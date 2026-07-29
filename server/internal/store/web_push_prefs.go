package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// WebPushCategory — категории пользовательских Web Push.
const (
	WebPushCategoryChat    = "chat"
	WebPushCategoryFriends = "friends"
	WebPushCategoryGames   = "games"
	WebPushCategoryRewards = "rewards"
)

// WebPushPreferences — какие категории пушей включены у пользователя.
type WebPushPreferences struct {
	Chat    bool `json:"chat"`
	Friends bool `json:"friends"`
	Games   bool `json:"games"`
	Rewards bool `json:"rewards"`
}

// DefaultWebPushPreferences — всё включено, пока пользователь не сохранил иное.
func DefaultWebPushPreferences() WebPushPreferences {
	return WebPushPreferences{
		Chat:    true,
		Friends: true,
		Games:   true,
		Rewards: true,
	}
}

// GetWebPushPreferences возвращает prefs пользователя (или дефолт, если строки нет).
func GetWebPushPreferences(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (WebPushPreferences, error) {
	var p WebPushPreferences
	err := pool.QueryRow(ctx, `
		SELECT chat, friends, games, rewards
		FROM web_push_preferences
		WHERE user_id = $1
	`, userID).Scan(&p.Chat, &p.Friends, &p.Games, &p.Rewards)
	if err == pgx.ErrNoRows {
		return DefaultWebPushPreferences(), nil
	}
	if err != nil {
		return DefaultWebPushPreferences(), err
	}
	return p, nil
}

// UpsertWebPushPreferences сохраняет категории уведомлений.
func UpsertWebPushPreferences(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	p WebPushPreferences,
) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO web_push_preferences (
			user_id, chat, friends, games, rewards, updated_at
		) VALUES ($1, $2, $3, $4, $5, now())
		ON CONFLICT (user_id) DO UPDATE SET
			chat = EXCLUDED.chat,
			friends = EXCLUDED.friends,
			games = EXCLUDED.games,
			rewards = EXCLUDED.rewards,
			updated_at = now()
	`, userID, p.Chat, p.Friends, p.Games, p.Rewards)
	return err
}

func categoryEnabled(p WebPushPreferences, category string) bool {
	switch category {
	case WebPushCategoryChat:
		return p.Chat
	case WebPushCategoryFriends:
		return p.Friends
	case WebPushCategoryGames:
		return p.Games
	case WebPushCategoryRewards:
		return p.Rewards
	default:
		return true
	}
}

// FilterUserIDsForWebPushCategory оставляет пользователей с включённой категорией
// (отсутствие строки prefs = все категории включены).
func FilterUserIDsForWebPushCategory(
	ctx context.Context,
	pool *pgxpool.Pool,
	userIDs []uuid.UUID,
	category string,
) ([]uuid.UUID, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT user_id, chat, friends, games, rewards
		FROM web_push_preferences
		WHERE user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	byUser := make(map[uuid.UUID]WebPushPreferences, len(userIDs))
	for rows.Next() {
		var id uuid.UUID
		var p WebPushPreferences
		if err := rows.Scan(&id, &p.Chat, &p.Friends, &p.Games, &p.Rewards); err != nil {
			return nil, err
		}
		byUser[id] = p
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]uuid.UUID, 0, len(userIDs))
	for _, id := range userIDs {
		p, ok := byUser[id]
		if !ok {
			p = DefaultWebPushPreferences()
		}
		if categoryEnabled(p, category) {
			out = append(out, id)
		}
	}
	return out, nil
}

// TryMarkDailyRewardPush возвращает true, если сегодня ещё не слали push
// о доступной ежедневной награде (и помечает день).
func TryMarkDailyRewardPush(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (bool, error) {
	var id uuid.UUID
	err := pool.QueryRow(ctx, `
		INSERT INTO web_push_preferences (user_id, last_daily_reward_push_date, updated_at)
		VALUES ($1, CURRENT_DATE, now())
		ON CONFLICT (user_id) DO UPDATE SET
			last_daily_reward_push_date = CURRENT_DATE,
			updated_at = now()
		WHERE web_push_preferences.last_daily_reward_push_date IS DISTINCT FROM CURRENT_DATE
		RETURNING user_id
	`, userID).Scan(&id)
	if err == pgx.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}
