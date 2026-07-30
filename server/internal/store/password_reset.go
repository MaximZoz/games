package store

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PasswordResetCode struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	CodeHash  string
	ExpiresAt time.Time
	Attempts  int
	CreatedAt time.Time
	UpdatedAt time.Time
}

func UpsertPasswordResetCode(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO password_reset_codes (user_id, code_hash, expires_at, attempts, created_at, updated_at)
		VALUES ($1, $2, $3, 0, now(), now())
		ON CONFLICT (user_id) DO UPDATE SET
			code_hash = EXCLUDED.code_hash,
			expires_at = EXCLUDED.expires_at,
			attempts = 0,
			updated_at = now()
	`, userID, HashEmailCode(code), time.Now().Add(EmailCodeTTL))
	return err
}

func GetPasswordResetCodeByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*PasswordResetCode, error) {
	row := pool.QueryRow(ctx, `
		SELECT pr.id, pr.user_id, pr.code_hash, pr.expires_at, pr.attempts, pr.created_at, pr.updated_at
		FROM password_reset_codes pr
		JOIN users u ON u.id = pr.user_id
		WHERE lower(u.email) = lower($1)
		LIMIT 1
	`, email)
	var c PasswordResetCode
	err := row.Scan(&c.ID, &c.UserID, &c.CodeHash, &c.ExpiresAt, &c.Attempts, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func IncrementPasswordResetAttempts(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		UPDATE password_reset_codes SET attempts = attempts + 1, updated_at = now() WHERE id = $1
	`, id)
	return err
}

func DeletePasswordResetCode(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM password_reset_codes WHERE user_id = $1`, userID)
	return err
}

func CanResendPasswordReset(ctx context.Context, pool *pgxpool.Pool, email string) (bool, error) {
	c, err := GetPasswordResetCodeByEmail(ctx, pool, email)
	if err == pgx.ErrNoRows {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	return time.Since(c.UpdatedAt) >= EmailResendCooldown, nil
}
