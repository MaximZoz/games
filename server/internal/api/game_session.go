package api

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// moveActiveToObserving — выбывание в multi: active снимаем, observation до конца партии.
// Общая логика для крестиков, дурака и будущих игр.
func moveActiveToObserving(ctx context.Context, rdb *redis.Client, userID uuid.UUID, gameID string) {
	clearUserActiveGame(ctx, rdb, userID)
	gt := ""
	if rdb != nil && gameID != "" {
		if v, err := rdb.HGet(ctx, "game:"+gameID, "game_type").Result(); err == nil {
			gt = v
		}
	}
	setUserObservingGame(ctx, rdb, userID, gameID, gt)
}

// clearUsersFinishedGame — снять active/observation/lobby по оконченной партии.
func clearUsersFinishedGame(ctx context.Context, rdb *redis.Client, users []uuid.UUID, gameID string) {
	if rdb == nil {
		return
	}
	lobbyID := ""
	if gm, _ := rdb.HGetAll(ctx, "game:"+gameID).Result(); len(gm) > 0 {
		lobbyID = strings.TrimSpace(gm["lobby_id"])
	}
	for _, u := range users {
		clearUserActiveGame(ctx, rdb, u)
		clearUserObservingGameIfMatch(ctx, rdb, u, gameID)
		if lobbyID != "" {
			clearUserActiveLobbyIfMatch(ctx, rdb, u, lobbyID)
		}
	}
}
