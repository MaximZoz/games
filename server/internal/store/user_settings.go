package store

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// UserSettings — пользовательские настройки аккаунта (не игровые).
type UserSettings struct {
	MessagesFriendsOnly bool   `json:"messages_friends_only"`
	PreferredLanguage   string `json:"preferred_language"`
}

// DefaultUserSettings — значения по умолчанию, если строки ещё нет.
func DefaultUserSettings() UserSettings {
	return UserSettings{
		MessagesFriendsOnly: false,
		PreferredLanguage:   "",
	}
}

// GetUserSettings возвращает настройки или дефолты, если строки нет.
func GetUserSettings(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (UserSettings, error) {
	var s UserSettings
	err := pool.QueryRow(ctx, `
		SELECT messages_friends_only, COALESCE(preferred_language, '')
		FROM user_settings
		WHERE user_id = $1
	`, userID).Scan(&s.MessagesFriendsOnly, &s.PreferredLanguage)
	if err == pgx.ErrNoRows {
		return DefaultUserSettings(), nil
	}
	if err != nil {
		return DefaultUserSettings(), err
	}
	return s, nil
}

// UpsertMessagesFriendsOnly сохраняет флаг «только смайлики от не-друзей».
func UpsertMessagesFriendsOnly(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	value bool,
) (UserSettings, error) {
	var s UserSettings
	err := pool.QueryRow(ctx, `
		INSERT INTO user_settings (user_id, messages_friends_only, preferred_language, updated_at)
		VALUES ($1, $2, '', now())
		ON CONFLICT (user_id) DO UPDATE SET
			messages_friends_only = EXCLUDED.messages_friends_only,
			updated_at = now()
		RETURNING messages_friends_only, COALESCE(preferred_language, '')
	`, userID, value).Scan(&s.MessagesFriendsOnly, &s.PreferredLanguage)
	if err != nil {
		return DefaultUserSettings(), err
	}
	return s, nil
}

// SetPreferredLanguage сохраняет язык интерфейса пользователя (для автоперевода в чате).
func SetPreferredLanguage(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	lang string,
) (UserSettings, error) {
	lang = strings.ToLower(strings.TrimSpace(lang))
	if i := strings.IndexByte(lang, '-'); i > 0 {
		lang = lang[:i]
	}
	switch lang {
	case "no", "nn":
		lang = "nb"
	case "iw":
		lang = "he"
	}
	var s UserSettings
	err := pool.QueryRow(ctx, `
		INSERT INTO user_settings (user_id, messages_friends_only, preferred_language, updated_at)
		VALUES ($1, false, $2, now())
		ON CONFLICT (user_id) DO UPDATE SET
			preferred_language = EXCLUDED.preferred_language,
			updated_at = now()
		RETURNING messages_friends_only, COALESCE(preferred_language, '')
	`, userID, lang).Scan(&s.MessagesFriendsOnly, &s.PreferredLanguage)
	if err != nil {
		return DefaultUserSettings(), err
	}
	return s, nil
}

// UpsertUserSettings — совместимость: обновляет messages_friends_only.
func UpsertUserSettings(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	s UserSettings,
) (UserSettings, error) {
	return UpsertMessagesFriendsOnly(ctx, pool, userID, s.MessagesFriendsOnly)
}
