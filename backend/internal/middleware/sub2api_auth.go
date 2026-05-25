package middleware

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"gorm.io/gorm"

	"github.com/kleinai/backend/internal/model"
	"github.com/kleinai/backend/pkg/logger"
)

type ctxKeySub2API struct{}

var CtxSub2APIUser = ctxKeySub2API{}

// Sub2APIMeResp mirrors sub2api's /api/v1/user/me response.
type Sub2APIMeResp struct {
	ID       int64  `json:"id"`
	Email    string `json:"email"`
	Username string `json:"username"`
	Role     string `json:"role"`
}

// Sub2APIAuth validates sub2api tokens by calling sub2api's API.
// If the token is valid, it finds or creates a gpt2api user
// and sets the user ID + sub2api user info in the context.
func Sub2APIAuth(db *gorm.DB) gin.HandlerFunc {
	sub2apiURL := os.Getenv("SUB2API_URL")
	if sub2apiURL == "" {
		sub2apiURL = "http://sub2api:8080"
	}

	client := &http.Client{Timeout: 10 * time.Second}

	return func(c *gin.Context) {
		// Get token from header
		tok := c.GetHeader("X-Sub2API-Token")
		if tok == "" {
			auth := c.GetHeader("Authorization")
			if strings.HasPrefix(auth, "Bearer ") {
				tok = strings.TrimPrefix(auth, "Bearer ")
			}
		}
		if tok == "" {
			c.Next()
			return
		}

		// Validate token by calling sub2api
		req, _ := http.NewRequestWithContext(c.Request.Context(), "GET",
			sub2apiURL+"/api/v1/user/me", nil)
		req.Header.Set("Authorization", "Bearer "+tok)

		resp, err := client.Do(req)
		if err != nil || resp == nil || resp.StatusCode != http.StatusOK {
			if resp != nil {
				resp.Body.Close()
			}
			logger.FromCtx(c.Request.Context()).Warn("sub2api_auth: validate failed",
				zap.Error(err),
				zap.Int("status", func() int { if resp != nil { return resp.StatusCode }; return 0 }()),
			)
			c.Next()
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		var apiResp struct {
			Data Sub2APIMeResp `json:"data"`
		}
		if err := json.Unmarshal(body, &apiResp); err != nil || apiResp.Data.ID == 0 {
			logger.FromCtx(c.Request.Context()).Warn("sub2api_auth: unmarshal failed or id==0",
				zap.Error(err),
				zap.ByteString("body", body),
			)
			c.Next()
			return
		}
		me := apiResp.Data
		logger.FromCtx(c.Request.Context()).Info("sub2api_auth: user authenticated",
			zap.Int64("sub2api_id", me.ID),
			zap.String("email", me.Email),
		)

		// Find or create gpt2api user
		var user model.User
		sub2ID := string(rune(me.ID))
		email := me.Email

		err = db.WithContext(c.Request.Context()).
			Where("email = ?", email).
			First(&user).Error

		if err == gorm.ErrRecordNotFound {
			uid := uuid.NewString()
			user = model.User{
				UUID:     uid,
				Email:    &email,
				Username: &me.Username,
				Password: "$2a$" + sub2ID + "." + uid[:8], // random unusable hash
				Points:   0,
				Status:   1,
			}
			if createErr := db.WithContext(c.Request.Context()).
				Create(&user).Error; createErr != nil {
				c.Next()
				return
			}
			_ = sub2ID
		} else if err != nil {
			c.Next()
			return
		}

		// Store in context
		c.Set(string(CtxUID), user.ID)
		c.Set("sub2api_id", me.ID)
		c.Set("sub2api_email", me.Email)
		ctx := context.WithValue(c.Request.Context(), CtxUID, user.ID)
		ctx = context.WithValue(ctx, CtxSub2APIUser, me)
		c.Request = c.Request.WithContext(ctx)

		c.Next()
	}
}
