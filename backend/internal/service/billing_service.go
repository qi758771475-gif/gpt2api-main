// Package service 计费引擎核心：预扣 / 结算 / 退款。
//
// 流程（与 docs/02-后端规范.md §6 对齐）：
//
//   1. PreDeduct  → wallet.Freeze + 写 consume_record(status=0)
//   2. (上游调用)
//   3. Settle     → wallet.Settle  + 更新 consume_record(status=1)
//   4. Failure    → wallet.Refund  + 更新 consume_record(status=2) + 写 refund_record
//
// 任务 ID（task_id）在调用方生成，应使用 ULID 字符串。
package service

import (
	"context"
	"errors"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"github.com/kleinai/backend/internal/model"
	"github.com/kleinai/backend/internal/repo"
	"github.com/kleinai/backend/pkg/errcode"
	"github.com/kleinai/backend/pkg/logger"
)

// BillingService 计费引擎。
type BillingService struct {
	db        *gorm.DB
	wallet    *repo.WalletRepo
	sub2api   *Sub2APIClient
}

// NewBillingService 构造。
func NewBillingService(db *gorm.DB, w *repo.WalletRepo, sub2api *Sub2APIClient) *BillingService {
	return &BillingService{db: db, wallet: w, sub2api: sub2api}
}

// PreDeductReq 预扣点请求。
type PreDeductReq struct {
	UserID     uint64
	TaskID     string
	Kind       string // image / video
	ModelCode  string
	Count      int
	UnitPoints int64
}

// PreDeduct calls sub2api to freeze USD, then writes consume_record locally for tracking.
func (s *BillingService) PreDeduct(ctx context.Context, req PreDeductReq) error {
	total := req.UnitPoints * int64(req.Count)
	if total <= 0 {
		return errcode.InvalidParam.WithMsg("invalid cost")
	}

	// Call sub2api to pre-deduct USD (amount in cents, convert to dollars)
	amountUSD := float64(total) / 100.0
	frozenID, err := s.sub2api.PreDeduct(ctx, req.UserID, amountUSD, req.ModelCode, req.TaskID)
	if err != nil {
		return errcode.InsufficientPoints
	}

	rec := &model.ConsumeRecord{
		TaskID:      req.TaskID,
		UserID:      req.UserID,
		Kind:        req.Kind,
		ModelCode:   req.ModelCode,
		Count:       req.Count,
		UnitPoints:  req.UnitPoints,
		TotalPoints: total,
		Status:      model.ConsumeStatusFrozen,
	}
	if err := s.db.WithContext(ctx).Create(rec).Error; err != nil {
		_ = s.sub2api.Refund(ctx, frozenID)
		return errcode.DBError.Wrap(err)
	}
	return nil
}

// Settle 结算消费：调用 sub2api 确认扣费 + 更新本地记录。
func (s *BillingService) Settle(ctx context.Context, taskID string, accountID *uint64) error {
	var rec model.ConsumeRecord
	if err := s.db.WithContext(ctx).Where("task_id = ?", taskID).First(&rec).Error; err != nil {
		return errcode.ResourceMissing
	}
	if rec.Status != model.ConsumeStatusFrozen {
		return nil
	}
	if err := s.sub2api.Settle(ctx, taskID); err != nil {
		logger.FromCtx(ctx).Error("sub2api.settle", zap.Error(err))
		return errcode.DBError.Wrap(err)
	}
	updates := map[string]any{"status": model.ConsumeStatusSettled}
	if accountID != nil {
		updates["account_id"] = *accountID
	}
	if err := s.db.WithContext(ctx).Model(&model.ConsumeRecord{}).
		Where("task_id = ?", taskID).Updates(updates).Error; err != nil {
		return errcode.DBError.Wrap(err)
	}
	logger.FromCtx(ctx).Info("billing.settle", zap.String("task", taskID), zap.Int64("points", rec.TotalPoints))
	return nil
}

// FinalizeUsage settles a frozen usage-based consume record with the actual cost.
// If actual is lower than the estimate, the difference is refunded before settling.
// If actual is higher than the estimate, the extra cost is deducted immediately when balance allows.
func (s *BillingService) FinalizeUsage(ctx context.Context, taskID string, actualPoints int64, accountID *uint64) error {
	var rec model.ConsumeRecord
	if err := s.db.WithContext(ctx).Where("task_id = ?", taskID).First(&rec).Error; err != nil {
		return errcode.ResourceMissing
	}
	if rec.Status != model.ConsumeStatusFrozen {
		return nil
	}
	if actualPoints < 0 {
		actualPoints = 0
	}
	estimated := rec.TotalPoints
	if actualPoints == 0 {
		if err := s.wallet.Refund(ctx, rec.UserID, taskID, "usage cost is zero", estimated); err != nil {
			return errcode.DBError.Wrap(err)
		}
		return s.db.WithContext(ctx).Model(&model.ConsumeRecord{}).
			Where("task_id = ?", taskID).
			Updates(map[string]any{"status": model.ConsumeStatusRefunded, "unit_points": 0, "total_points": 0}).Error
	}
	if actualPoints < estimated {
		if err := s.wallet.RefundFrozenPart(ctx, rec.UserID, taskID, "chat usage refund", estimated-actualPoints); err != nil {
			return errcode.DBError.Wrap(err)
		}
	} else if actualPoints > estimated {
		// Settle estimated frozen points first, then charge the extra balance.
		if err := s.wallet.Settle(ctx, rec.UserID, estimated); err != nil {
			return errcode.DBError.Wrap(err)
		}
		if _, err := s.wallet.Adjust(ctx, rec.UserID, model.BizConsume, taskID+":extra", -(actualPoints - estimated), rec.ModelCode+" extra usage", false); err != nil {
			if errors.Is(err, repo.ErrInsufficient) {
				return errcode.InsufficientPoints
			}
			return errcode.DBError.Wrap(err)
		}
		updates := map[string]any{"status": model.ConsumeStatusSettled, "unit_points": actualPoints, "total_points": actualPoints}
		if accountID != nil {
			updates["account_id"] = *accountID
		}
		return s.db.WithContext(ctx).Model(&model.ConsumeRecord{}).Where("task_id = ?", taskID).Updates(updates).Error
	}
	if err := s.wallet.Settle(ctx, rec.UserID, actualPoints); err != nil {
		return errcode.DBError.Wrap(err)
	}
	updates := map[string]any{"status": model.ConsumeStatusSettled, "unit_points": actualPoints, "total_points": actualPoints}
	if accountID != nil {
		updates["account_id"] = *accountID
	}
	if err := s.db.WithContext(ctx).Model(&model.ConsumeRecord{}).Where("task_id = ?", taskID).Updates(updates).Error; err != nil {
		return errcode.DBError.Wrap(err)
	}
	logger.FromCtx(ctx).Info("billing.finalize_usage", zap.String("task", taskID), zap.Int64("estimate", estimated), zap.Int64("actual", actualPoints))
	return nil
}

// FailRefund 失败退款：调用 sub2api 退回 + 标记本地 status=refunded。
func (s *BillingService) FailRefund(ctx context.Context, taskID, reason string) error {
	var rec model.ConsumeRecord
	if err := s.db.WithContext(ctx).Where("task_id = ?", taskID).First(&rec).Error; err != nil {
		return errcode.ResourceMissing
	}
	if rec.Status != model.ConsumeStatusFrozen {
		return nil
	}
	if err := s.sub2api.Refund(ctx, taskID); err != nil {
		logger.FromCtx(ctx).Error("sub2api.refund", zap.Error(err))
	}
	if err := s.db.WithContext(ctx).Model(&model.ConsumeRecord{}).
		Where("task_id = ?", taskID).
		Update("status", model.ConsumeStatusRefunded).Error; err != nil {
		return errcode.DBError.Wrap(err)
	}
	logger.FromCtx(ctx).Info("billing.refund", zap.String("task", taskID), zap.Int64("points", rec.TotalPoints), zap.String("reason", reason))
	return nil
}

// GrantPoints 赠送 / 兑换码 / 邀请奖励：直接增加点数 + 写流水。
func (s *BillingService) GrantPoints(ctx context.Context, userID uint64, biz, bizID string, points int64, remark string) error {
	if _, err := s.wallet.Income(ctx, userID, biz, bizID, points, remark); err != nil {
		return errcode.DBError.Wrap(err)
	}
	return nil
}

// ListWalletLogs 用户钱包流水。
func (s *BillingService) ListWalletLogs(ctx context.Context, userID uint64, page, pageSize int) ([]*model.WalletLog, int64, error) {
	logs, total, err := s.wallet.ListUserLogs(ctx, userID, page, pageSize)
	if err != nil {
		return nil, 0, errcode.DBError.Wrap(err)
	}
	return logs, total, nil
}
