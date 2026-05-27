// Package database 封装 MySQL（GORM）与 Redis 客户端。
package database

import (
	"context"
	"fmt"
	"time"

	sqlmysql "github.com/go-sql-driver/mysql"
	"go.uber.org/zap"
	gormmysql "gorm.io/driver/mysql"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"

	"github.com/kleinai/backend/pkg/config"
	"github.com/kleinai/backend/pkg/logger"
)

// NewMySQL 用 GORM 创建 MySQL 连接（含连接池配置与慢查询日志）。
func NewMySQL(c *config.MySQL) (*gorm.DB, error) {
	if c.DSN == "" {
		return nil, fmt.Errorf("mysql dsn empty")
	}

	parsedDSN, err := sqlmysql.ParseDSN(c.DSN)
	if err != nil {
		return nil, fmt.Errorf("parse mysql dsn: %w", err)
	}
	// Force utf8mb4 at the handshake/session level so every pooled connection
	// uses the same charset when reading Chinese text.
	parsedDSN.Collation = "utf8mb4_0900_ai_ci"
	effectiveDSN := parsedDSN.FormatDSN()

	gormLog := gormlogger.New(
		zapWriter{l: logger.L()},
		gormlogger.Config{
			SlowThreshold:             c.SlowThreshold,
			LogLevel:                  gormlogger.Warn,
			IgnoreRecordNotFoundError: true,
			Colorful:                  false,
		},
	)

	db, err := gorm.Open(gormmysql.Open(effectiveDSN), &gorm.Config{
		Logger:                                   gormLog,
		PrepareStmt:                              true,
		DisableForeignKeyConstraintWhenMigrating: true,
		NowFunc:                                  func() time.Time { return time.Now().UTC() },
	})
	if err != nil {
		return nil, fmt.Errorf("gorm open: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("get sql db: %w", err)
	}

	maxOpen := c.MaxOpenConns
	if maxOpen <= 0 {
		maxOpen = 100
	}
	maxIdle := c.MaxIdleConns
	if maxIdle <= 0 {
		maxIdle = 20
	}
	lifetime := c.ConnMaxLifetime
	if lifetime <= 0 {
		lifetime = time.Hour
	}

	sqlDB.SetMaxOpenConns(maxOpen)
	sqlDB.SetMaxIdleConns(maxIdle)
	sqlDB.SetConnMaxLifetime(lifetime)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("ping mysql: %w", err)
	}

	// Force the session charset to utf8mb4 so reads/writes of Chinese text
	// stay consistent even if the client/session defaults drift.
	if err := db.WithContext(ctx).Exec("SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci").Error; err != nil {
		return nil, fmt.Errorf("set mysql session charset: %w", err)
	}

	type sessionVar struct {
		Name  string
		Value string
	}
	var sessionVars []sessionVar
	if err := db.WithContext(ctx).Raw(`
		SHOW VARIABLES WHERE Variable_name IN (
			'character_set_client',
			'character_set_connection',
			'character_set_results',
			'collation_connection'
		)
	`).Scan(&sessionVars).Error; err != nil {
		return nil, fmt.Errorf("query mysql session charset: %w", err)
	}
	sessionCharset := map[string]string{}
	for _, item := range sessionVars {
		sessionCharset[item.Name] = item.Value
	}

	logger.L().Info("mysql connected",
		zap.Int("max_open", maxOpen),
		zap.Int("max_idle", maxIdle),
		zap.Duration("lifetime", lifetime),
		zap.String("character_set_client", sessionCharset["character_set_client"]),
		zap.String("character_set_connection", sessionCharset["character_set_connection"]),
		zap.String("character_set_results", sessionCharset["character_set_results"]),
		zap.String("collation_connection", sessionCharset["collation_connection"]),
	)
	return db, nil
}

// zapWriter 让 GORM logger 写入 zap。
type zapWriter struct{ l *zap.Logger }

func (z zapWriter) Printf(format string, args ...any) {
	z.l.Sugar().Infof(format, args...)
}
