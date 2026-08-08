package store

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Session struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	RefreshTokenHash string
	ExpiresAt        time.Time
	CreatedAt        time.Time
}

func scanSession(row pgx.Row) (*Session, error) {
	var s Session
	err := row.Scan(
		&s.ID,
		&s.UserID,
		&s.RefreshTokenHash,
		&s.ExpiresAt,
		&s.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func CreateSession(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	refreshTokenHash string,
	expiresAt time.Time,
) (*Session, error) {
	row := pool.QueryRow(ctx,
		`INSERT INTO sessions (user_id, refresh_token_hash, expires_at)
		 VALUES ($1, $2, $3)
		 RETURNING id, user_id, refresh_token_hash, expires_at, created_at`,
		userID, refreshTokenHash, expiresAt,
	)
	return scanSession(row)
}

func GetSessionByRefreshTokenHash(
	ctx context.Context,
	pool *pgxpool.Pool,
	refreshTokenHash string,
) (*Session, error) {
	row := pool.QueryRow(ctx,
		`SELECT id, user_id, refresh_token_hash, expires_at, created_at
		 FROM sessions
		 WHERE refresh_token_hash = $1`,
		refreshTokenHash,
	)
	return scanSession(row)
}

func RotateSessionRefreshToken(
	ctx context.Context,
	pool *pgxpool.Pool,
	sessionID uuid.UUID,
	nextRefreshTokenHash string,
	expiresAt time.Time,
) error {
	tag, err := pool.Exec(ctx,
		`UPDATE sessions
		 SET refresh_token_hash = $2, expires_at = $3
		 WHERE id = $1`,
		sessionID, nextRefreshTokenHash, expiresAt,
	)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// DeleteSessionsByUserID удаляет все сессии пользователя (один активный вход).
func DeleteSessionsByUserID(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM sessions WHERE user_id = $1`, userID)
	return err
}

// SessionExists возвращает true, если сессия ещё в БД и не истекла.
// При кратковременных сбоях пула/соединения делает несколько попыток —
// иначе клиент на каждом деплое видит залипший 503 «temporarily unavailable».
func SessionExists(ctx context.Context, pool *pgxpool.Pool, sessionID uuid.UUID) (bool, error) {
	const attempts = 3
	var last error
	for i := 0; i < attempts; i++ {
		if i > 0 {
			delay := time.Duration(i) * 80 * time.Millisecond
			timer := time.NewTimer(delay)
			select {
			case <-ctx.Done():
				timer.Stop()
				if last != nil {
					return false, last
				}
				return false, ctx.Err()
			case <-timer.C:
			}
		}
		var ok bool
		err := pool.QueryRow(ctx,
			`SELECT EXISTS(
				SELECT 1 FROM sessions
				WHERE id = $1 AND expires_at > NOW()
			)`,
			sessionID,
		).Scan(&ok)
		if err == nil {
			return ok, nil
		}
		if errors.Is(err, context.Canceled) {
			return false, err
		}
		last = err
	}
	return false, last
}
