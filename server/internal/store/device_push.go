package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DevicePushToken — FCM (или аналог) токен нативного приложения.
type DevicePushToken struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Token     string
	Platform  string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// UpsertDevicePushToken сохраняет токен устройства за пользователем.
func UpsertDevicePushToken(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	token, platform string,
) error {
	platform = strings.TrimSpace(platform)
	if platform == "" {
		platform = "android"
	}
	_, err := pool.Exec(ctx, `
		INSERT INTO device_push_tokens (
			user_id, token, platform, created_at, updated_at
		) VALUES ($1, $2, $3, now(), now())
		ON CONFLICT (token) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			platform = EXCLUDED.platform,
			updated_at = now()
	`, userID, token, platform)
	return err
}

// DeleteDevicePushToken удаляет токен текущего пользователя.
func DeleteDevicePushToken(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	token string,
) error {
	_, err := pool.Exec(ctx, `
		DELETE FROM device_push_tokens
		WHERE user_id = $1 AND token = $2
	`, userID, token)
	return err
}

// DeleteDevicePushTokenByValue удаляет протухший токен (FCM UNREGISTERED).
func DeleteDevicePushTokenByValue(ctx context.Context, pool *pgxpool.Pool, token string) error {
	_, err := pool.Exec(ctx, `DELETE FROM device_push_tokens WHERE token = $1`, token)
	return err
}

// ListDevicePushTokensForUsers возвращает нативные токены пользователей.
func ListDevicePushTokensForUsers(
	ctx context.Context,
	pool *pgxpool.Pool,
	userIDs []uuid.UUID,
) ([]DevicePushToken, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT id, user_id, token, platform, created_at, updated_at
		FROM device_push_tokens
		WHERE user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := make([]DevicePushToken, 0)
	for rows.Next() {
		var t DevicePushToken
		if err := rows.Scan(
			&t.ID, &t.UserID, &t.Token, &t.Platform, &t.CreatedAt, &t.UpdatedAt,
		); err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}
