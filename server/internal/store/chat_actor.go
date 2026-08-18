package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ActingChatUserID — кто выполняет операции в чате.
// Участник действует сам. Админ в диалоге support↔пользователь —
// от имени системного аккаунта поддержки (не как посторонний JWT).
func ActingChatUserID(
	ctx context.Context,
	pool *pgxpool.Pool,
	jwtUserID, chatID uuid.UUID,
) (uuid.UUID, error) {
	ok, err := IsChatMember(ctx, pool, chatID, jwtUserID)
	if err != nil {
		return uuid.Nil, err
	}
	if ok {
		return jwtUserID, nil
	}
	u, err := GetUserByID(ctx, pool, jwtUserID)
	if err != nil || u == nil || !u.IsAdmin {
		return uuid.Nil, ErrChatForbidden
	}
	su, err := GetSupportUser(ctx, pool)
	if err != nil || su == nil {
		return uuid.Nil, ErrChatForbidden
	}
	ok, err = IsChatMember(ctx, pool, chatID, su.ID)
	if err != nil {
		return uuid.Nil, err
	}
	if !ok {
		return uuid.Nil, ErrChatForbidden
	}
	return su.ID, nil
}

// IsSupportChat — в чате есть системный аккаунт поддержки.
func IsSupportChat(ctx context.Context, pool *pgxpool.Pool, chatID uuid.UUID) (bool, error) {
	su, err := GetSupportUser(ctx, pool)
	if err != nil || su == nil {
		return false, err
	}
	return IsChatMember(ctx, pool, chatID, su.ID)
}

func userIsSupport(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) bool {
	u, err := GetUserByID(ctx, pool, userID)
	return err == nil && u != nil && u.IsSupport
}

// UserIsSupport — публичная обёртка для API-слоя.
func UserIsSupport(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) bool {
	return userIsSupport(ctx, pool, userID)
}
