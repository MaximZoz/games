package store

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	EmailCodeTTL       = 15 * time.Minute
	EmailCodeMaxAttempts = 5
	EmailResendCooldown = 60 * time.Second
)

func HashEmailCode(code string) string {
	sum := sha256.Sum256([]byte(code))
	return hex.EncodeToString(sum[:])
}

func CreateEmailVerificationCode(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) error {
	_, err := pool.Exec(ctx, `DELETE FROM email_verification_codes WHERE user_id = $1`, userID)
	if err != nil {
		return err
	}
	_, err = pool.Exec(ctx, `
		INSERT INTO email_verification_codes (user_id, code_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, HashEmailCode(code), time.Now().Add(EmailCodeTTL))
	return err
}

type EmailVerificationCode struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	CodeHash  string
	ExpiresAt time.Time
	Attempts  int
	CreatedAt time.Time
}

func GetLatestEmailVerificationCode(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (*EmailVerificationCode, error) {
	row := pool.QueryRow(ctx, `
		SELECT id, user_id, code_hash, expires_at, attempts, created_at
		FROM email_verification_codes
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 1
	`, userID)
	var c EmailVerificationCode
	err := row.Scan(&c.ID, &c.UserID, &c.CodeHash, &c.ExpiresAt, &c.Attempts, &c.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func IncrementEmailCodeAttempts(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		UPDATE email_verification_codes SET attempts = attempts + 1 WHERE id = $1
	`, id)
	return err
}

func DeleteEmailVerificationCodes(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM email_verification_codes WHERE user_id = $1`, userID)
	return err
}

func MarkEmailVerified(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	cmd, err := pool.Exec(ctx, `
		UPDATE users SET email_verified_at = now(), updated_at = now()
		WHERE id = $1 AND email_verified_at IS NULL
	`, userID)
	if err != nil {
		return err
	}
	if cmd.RowsAffected() == 0 {
		// Уже подтверждён или пользователь не найден — проверим наличие.
		var exists bool
		err = pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)`, userID).Scan(&exists)
		if err != nil {
			return err
		}
		if !exists {
			return pgx.ErrNoRows
		}
	}
	return nil
}

func CanResendEmailCode(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (bool, error) {
	c, err := GetLatestEmailVerificationCode(ctx, pool, userID)
	if err == pgx.ErrNoRows {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	return time.Since(c.CreatedAt) >= EmailResendCooldown, nil
}
