package store

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// WebPushSubscription — браузерная Push-подписка пользователя (PWA).
type WebPushSubscription struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Endpoint  string
	P256dh    string
	Auth      string
	UserAgent string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// UpsertWebPushSubscription сохраняет или обновляет подписку по endpoint.
func UpsertWebPushSubscription(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	endpoint, p256dh, auth, userAgent string,
) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO web_push_subscriptions (
			user_id, endpoint, p256dh, auth, user_agent, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, now(), now())
		ON CONFLICT (endpoint) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			p256dh = EXCLUDED.p256dh,
			auth = EXCLUDED.auth,
			user_agent = EXCLUDED.user_agent,
			updated_at = now()
	`, userID, endpoint, p256dh, auth, userAgent)
	return err
}

// DeleteWebPushSubscriptionByEndpoint удаляет подписку текущего пользователя.
func DeleteWebPushSubscriptionByEndpoint(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	endpoint string,
) error {
	_, err := pool.Exec(ctx, `
		DELETE FROM web_push_subscriptions
		WHERE user_id = $1 AND endpoint = $2
	`, userID, endpoint)
	return err
}

// DeleteWebPushSubscriptionByID удаляет протухшую подписку (410/404 от push-сервиса).
func DeleteWebPushSubscriptionByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM web_push_subscriptions WHERE id = $1`, id)
	return err
}

// ListWebPushSubscriptionsForUsers возвращает все подписки для набора пользователей.
func ListWebPushSubscriptionsForUsers(
	ctx context.Context,
	pool *pgxpool.Pool,
	userIDs []uuid.UUID,
) ([]WebPushSubscription, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT id, user_id, endpoint, p256dh, auth, COALESCE(user_agent, ''), created_at, updated_at
		FROM web_push_subscriptions
		WHERE user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := make([]WebPushSubscription, 0)
	for rows.Next() {
		var s WebPushSubscription
		if err := rows.Scan(
			&s.ID, &s.UserID, &s.Endpoint, &s.P256dh, &s.Auth,
			&s.UserAgent, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, rows.Err()
}
