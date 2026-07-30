package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PendingRegistration struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	DisplayName  *string
	ReferredBy   *uuid.UUID
	CodeHash     string
	ExpiresAt    time.Time
	Attempts     int
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

// UpsertPendingRegistration сохраняет заявку на регистрацию и код.
// Повторная регистрация на тот же email обновляет данные и код.
func UpsertPendingRegistration(
	ctx context.Context,
	pool *pgxpool.Pool,
	email, passwordHash, displayName, code string,
	referredBy *uuid.UUID,
) (*PendingRegistration, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	var displayNamePtr *string
	if strings.TrimSpace(displayName) != "" {
		dn := strings.TrimSpace(displayName)
		displayNamePtr = &dn
	}
	var referrerID *uuid.UUID
	if referredBy != nil && *referredBy != uuid.Nil {
		var exists uuid.UUID
		err := pool.QueryRow(ctx, `SELECT id FROM users WHERE id = $1`, *referredBy).Scan(&exists)
		if err == nil {
			referrerID = referredBy
		}
	}

	now := time.Now()
	row := pool.QueryRow(ctx, `
		INSERT INTO pending_registrations (
			email, password_hash, display_name, referred_by,
			code_hash, expires_at, attempts, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, 0, $7, $7)
		ON CONFLICT (email) DO UPDATE SET
			password_hash = EXCLUDED.password_hash,
			display_name  = EXCLUDED.display_name,
			referred_by   = EXCLUDED.referred_by,
			code_hash     = EXCLUDED.code_hash,
			expires_at    = EXCLUDED.expires_at,
			attempts      = 0,
			updated_at    = EXCLUDED.updated_at
		RETURNING id, email, password_hash, display_name, referred_by,
			code_hash, expires_at, attempts, created_at, updated_at
	`, email, passwordHash, displayNamePtr, referrerID,
		HashEmailCode(code), now.Add(EmailCodeTTL), now)

	return scanPending(row)
}

func GetPendingRegistrationByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*PendingRegistration, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	row := pool.QueryRow(ctx, `
		SELECT id, email, password_hash, display_name, referred_by,
			code_hash, expires_at, attempts, created_at, updated_at
		FROM pending_registrations
		WHERE email = $1
	`, email)
	return scanPending(row)
}

func IncrementPendingRegistrationAttempts(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		UPDATE pending_registrations SET attempts = attempts + 1 WHERE id = $1
	`, id)
	return err
}

func RefreshPendingRegistrationCode(ctx context.Context, pool *pgxpool.Pool, email, code string) (*PendingRegistration, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	now := time.Now()
	row := pool.QueryRow(ctx, `
		UPDATE pending_registrations SET
			code_hash = $2,
			expires_at = $3,
			attempts = 0,
			updated_at = $4
		WHERE email = $1
		RETURNING id, email, password_hash, display_name, referred_by,
			code_hash, expires_at, attempts, created_at, updated_at
	`, email, HashEmailCode(code), now.Add(EmailCodeTTL), now)
	return scanPending(row)
}

func DeletePendingRegistration(ctx context.Context, pool *pgxpool.Pool, email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	_, err := pool.Exec(ctx, `DELETE FROM pending_registrations WHERE email = $1`, email)
	return err
}

func CanResendPendingRegistration(ctx context.Context, pool *pgxpool.Pool, email string) (bool, error) {
	p, err := GetPendingRegistrationByEmail(ctx, pool, email)
	if err == pgx.ErrNoRows {
		return false, err
	}
	if err != nil {
		return false, err
	}
	return time.Since(p.UpdatedAt) >= EmailResendCooldown, nil
}

func EmailTakenByUser(ctx context.Context, pool *pgxpool.Pool, email string) (bool, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	var exists bool
	err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`, email).Scan(&exists)
	return exists, err
}

func DisplayNameTakenByUser(ctx context.Context, pool *pgxpool.Pool, displayName string) (bool, error) {
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		return false, nil
	}
	var exists bool
	err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE display_name = $1)`, displayName).Scan(&exists)
	return exists, err
}

func scanPending(row pgx.Row) (*PendingRegistration, error) {
	var p PendingRegistration
	err := row.Scan(
		&p.ID, &p.Email, &p.PasswordHash, &p.DisplayName, &p.ReferredBy,
		&p.CodeHash, &p.ExpiresAt, &p.Attempts, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &p, nil
}
