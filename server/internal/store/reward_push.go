package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// RewardPushCandidate — кому можно слать пуш о награде, и его язык.
type RewardPushCandidate struct {
	UserID uuid.UUID
	Lang   string
}

const rewardPushHasTargetSQL = `
	(
		EXISTS (SELECT 1 FROM device_push_tokens d WHERE d.user_id = u.id)
		OR EXISTS (SELECT 1 FROM web_push_subscriptions w WHERE w.user_id = u.id)
	)
	AND NOT EXISTS (
		SELECT 1 FROM web_push_preferences p
		WHERE p.user_id = u.id AND p.rewards = false
	)
`

// ListDailyRewardPushCandidates — ещё не забрали монеты за вход сегодня (UTC)
// и пуш об этом сегодня не уходил. Только с токеном устройства или web push.
func ListDailyRewardPushCandidates(
	ctx context.Context,
	pool *pgxpool.Pool,
	after uuid.UUID,
	limit int,
) ([]RewardPushCandidate, error) {
	return listRewardPushCandidates(ctx, pool, after, limit, `
		AND (
			u.daily_reward_claimed_at IS NULL
			OR (u.daily_reward_claimed_at AT TIME ZONE 'UTC')::date < `+utcTodaySQL+`
		)
		AND NOT EXISTS (
			SELECT 1 FROM web_push_preferences p
			WHERE p.user_id = u.id
				AND p.last_daily_reward_push_date = `+utcTodaySQL+`
		)
	`)
}

// ListCollectionIncomePushCandidates — есть предмет коллекции с доходом,
// сегодня его ещё не забирали и пуш об этом не уходил.
func ListCollectionIncomePushCandidates(
	ctx context.Context,
	pool *pgxpool.Pool,
	after uuid.UUID,
	limit int,
) ([]RewardPushCandidate, error) {
	return listRewardPushCandidates(ctx, pool, after, limit, `
		AND (
			u.collection_income_claimed_at IS NULL
			OR (u.collection_income_claimed_at AT TIME ZONE 'UTC')::date < `+utcTodaySQL+`
		)
		AND EXISTS (
			SELECT 1
			FROM user_inventory inv
			JOIN shop_items s ON s.code = inv.item_code
			WHERE inv.user_id = u.id
				AND s.kind = 'collection'
				AND s.active = TRUE
				AND COALESCE((s.payload->>'weekly_bronze')::int, 0) > 0
		)
		AND NOT EXISTS (
			SELECT 1 FROM web_push_preferences p
			WHERE p.user_id = u.id
				AND p.last_collection_income_push_date = `+utcTodaySQL+`
		)
	`)
}

func listRewardPushCandidates(
	ctx context.Context,
	pool *pgxpool.Pool,
	after uuid.UUID,
	limit int,
	extra string,
) ([]RewardPushCandidate, error) {
	if limit < 1 {
		limit = 1
	}
	if limit > 1000 {
		limit = 1000
	}
	rows, err := pool.Query(ctx, `
		SELECT u.id, COALESCE(us.preferred_language, '')
		FROM users u
		LEFT JOIN user_settings us ON us.user_id = u.id
		WHERE u.frozen_at IS NULL
			AND u.id > $2
			AND `+rewardPushHasTargetSQL+`
			`+extra+`
		ORDER BY u.id
		LIMIT $1
	`, limit, after)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]RewardPushCandidate, 0)
	for rows.Next() {
		var c RewardPushCandidate
		if err := rows.Scan(&c.UserID, &c.Lang); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}
