package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// UserSettings — пользовательские настройки аккаунта (не игровые).
type UserSettings struct {
	MessagesFriendsOnly bool `json:"messages_friends_only"`
}

// DefaultUserSettings — значения по умолчанию, если строки ещё нет.
func DefaultUserSettings() UserSettings {
	return UserSettings{
		MessagesFriendsOnly: false,
	}
}

// GetUserSettings возвращает настройки или дефолты, если строки нет.
func GetUserSettings(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (UserSettings, error) {
	var s UserSettings
	err := pool.QueryRow(ctx, `
		SELECT messages_friends_only
		FROM user_settings
		WHERE user_id = $1
	`, userID).Scan(&s.MessagesFriendsOnly)
	if err == pgx.ErrNoRows {
		return DefaultUserSettings(), nil
	}
	if err != nil {
		return DefaultUserSettings(), err
	}
	return s, nil
}

// UpsertUserSettings сохраняет настройки пользователя.
func UpsertUserSettings(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	s UserSettings,
) (UserSettings, error) {
	err := pool.QueryRow(ctx, `
		INSERT INTO user_settings (user_id, messages_friends_only, updated_at)
		VALUES ($1, $2, now())
		ON CONFLICT (user_id) DO UPDATE SET
			messages_friends_only = EXCLUDED.messages_friends_only,
			updated_at = now()
		RETURNING messages_friends_only
	`, userID, s.MessagesFriendsOnly).Scan(&s.MessagesFriendsOnly)
	if err != nil {
		return DefaultUserSettings(), err
	}
	return s, nil
}
