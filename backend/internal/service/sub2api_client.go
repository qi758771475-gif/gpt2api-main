package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"go.uber.org/zap"
	"github.com/kleinai/backend/pkg/logger"
)

// Sub2APIClient calls sub2api's internal billing API.
type Sub2APIClient struct {
	baseURL      string
	sharedSecret string
	client       *http.Client
}

// NewSub2APIClient creates the client. Reads SUB2API_URL and INTERNAL_SECRET from env.
func NewSub2APIClient() *Sub2APIClient {
	base := os.Getenv("SUB2API_URL")
	if base == "" {
		base = "http://sub2api:8080"
	}
	secret := os.Getenv("INTERNAL_SECRET")
	if secret == "" {
		secret = "sub2api-internal-secret-change-me"
	}
	return &Sub2APIClient{
		baseURL:      base,
		sharedSecret: secret,
		client:       &http.Client{Timeout: 10 * time.Second},
	}
}

type preDeductReq struct {
	UserID uint64  `json:"user_id"`
	Amount float64 `json:"amount"`
	Model  string  `json:"model"`
	TaskID string  `json:"task_id"`
}

type preDeductResp struct {
	Success  bool   `json:"success"`
	FrozenID string `json:"frozen_id"`
	Error    string `json:"error"`
}

// PreDeduct calls sub2api to freeze a user's balance.
func (c *Sub2APIClient) PreDeduct(ctx context.Context, userID uint64, amount float64, model, taskID string) (string, error) {
	return c.preDeduct(ctx, userID, amount, model, taskID)
}

func (c *Sub2APIClient) preDeduct(ctx context.Context, userID uint64, amount float64, model, taskID string) (string, error) {
	body, _ := json.Marshal(preDeductReq{UserID: userID, Amount: amount, Model: model, TaskID: taskID})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/api/v1/internal/billing/pre-deduct", bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("pre-deduct request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Secret", c.sharedSecret)

	resp, err := c.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("pre-deduct call: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	var r preDeductResp
	if err := json.Unmarshal(respBody, &r); err != nil {
		return "", fmt.Errorf("pre-deduct parse: %w", err)
	}
	if !r.Success {
		return "", fmt.Errorf("pre-deduct failed: %s", r.Error)
	}
	logger.L().Info("sub2api.pre_deduct", zap.Uint64("user_id", userID), zap.Float64("amount", amount), zap.String("frozen_id", r.FrozenID))
	return r.FrozenID, nil
}

type settleReq struct {
	FrozenID string `json:"frozen_id"`
}

type settleResp struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

// Settle calls sub2api to confirm a frozen deduction.
func (c *Sub2APIClient) Settle(ctx context.Context, frozenID string) error {
	body, _ := json.Marshal(settleReq{FrozenID: frozenID})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/api/v1/internal/billing/settle", bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("settle request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Secret", c.sharedSecret)

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("settle call: %w", err)
	}
	defer resp.Body.Close()
	logger.L().Info("sub2api.settle", zap.String("frozen_id", frozenID))
	return nil
}

type refundReq struct {
	FrozenID string `json:"frozen_id"`
}

type refundResp struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

// Refund calls sub2api to release a frozen balance.
func (c *Sub2APIClient) Refund(ctx context.Context, frozenID string) error {
	body, _ := json.Marshal(refundReq{FrozenID: frozenID})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/api/v1/internal/billing/refund", bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("refund request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Secret", c.sharedSecret)

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("refund call: %w", err)
	}
	defer resp.Body.Close()
	logger.L().Info("sub2api.refund", zap.String("frozen_id", frozenID))
	return nil
}
