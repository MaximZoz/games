package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CountPhoneBadgeSources — непрочитанные диалоги и входящие заявки в друзья.
// Приглашения в игру лежат в Redis, сюда не входят.
func CountPhoneBadgeSources(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
) (unreadChats int, incomingFriends int, err error) {
	err = pool.QueryRow(ctx, `
		WITH my_chats AS (
			SELECT c.id, COALESCE(c.kind, 'direct') AS kind
			FROM chats c
			WHERE (
				COALESCE(c.kind, 'direct') = 'direct'
				AND (c.user_low = $1 OR c.user_high = $1)
			) OR (
				c.kind = 'group' AND EXISTS (
					SELECT 1 FROM chat_members cm
					WHERE cm.chat_id = c.id AND cm.user_id = $1
				)
			)
		),
		unread_chats AS (
			SELECT m.chat_id
			FROM chat_messages m
			JOIN my_chats mc ON mc.id = m.chat_id
			LEFT JOIN chat_members cm
			  ON cm.chat_id = m.chat_id AND cm.user_id = $1
			WHERE m.sender_user_id <> $1
			  AND (
			    (mc.kind = 'direct' AND m.read_at IS NULL)
			    OR (
			      mc.kind = 'group'
			      AND m.created_at > COALESCE(cm.last_read_at, '-infinity'::timestamptz)
			    )
			  )
			GROUP BY m.chat_id
		)
		SELECT
			(SELECT COUNT(*)::int FROM unread_chats),
			(SELECT COUNT(*)::int FROM friend_requests WHERE receiver_user_id = $1)
	`, userID).Scan(&unreadChats, &incomingFriends)
	return unreadChats, incomingFriends, err
}

// CountRewardIconBadges — по единице, если сегодня можно забрать монеты за
// вход и дневной доход коллекций. Это те же условия, что у пушей наград.
func CountRewardIconBadges(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
) (daily int, income int, err error) {
	err = pool.QueryRow(ctx, `
		SELECT
			CASE WHEN u.daily_reward_claimed_at IS NULL
				OR (u.daily_reward_claimed_at AT TIME ZONE 'UTC')::date < `+utcTodaySQL+`
				THEN 1 ELSE 0 END,
			CASE WHEN (
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
				THEN 1 ELSE 0 END
		FROM users u
		WHERE u.id = $1
	`, userID).Scan(&daily, &income)
	return daily, income, err
}
