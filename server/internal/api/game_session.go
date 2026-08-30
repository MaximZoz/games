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

func isWaitingLobbyStatus(status string) bool {
	return status == lobbyStatusWaitingInvite || status == lobbyStatusWaitingMatchmake
}

const (
	getActiveLobbyAsLobby = "lobby"
	getActiveLobbyAsGame  = "game"
	getActiveLobbyNone    = ""
)

// classifyGetActiveLobby — что показать в GetActive по указателю active_lobby.
// Оконченная / пропавшая партия не должна выглядеть как «текущая игра».
func classifyGetActiveLobby(lobbyStatus, gameID, gameStatus string) (kind string, clearPointer bool) {
	if isWaitingLobbyStatus(lobbyStatus) {
		return getActiveLobbyAsLobby, false
	}
	if lobbyStatus == lobbyStatusInGame &&
		strings.TrimSpace(gameID) != "" &&
		gameStatus == gameStatusActive {
		return getActiveLobbyAsGame, false
	}
	return getActiveLobbyNone, true
}

type otherLobbyJoinAction int

const (
	otherLobbyNone otherLobbyJoinAction = iota
	otherLobbyRelease
	otherLobbyBlock
	otherLobbyClear
)

// classifyOtherLobbyForJoin — чужой active_lobby при входе в target.
// Своё ожидание реванша не 409, а закрываем и входим в инвайт соперника.
func classifyOtherLobbyForJoin(otherLobbyID, targetLobbyID, otherStatus, otherGameStatus string) otherLobbyJoinAction {
	if otherLobbyID == "" || otherLobbyID == targetLobbyID {
		return otherLobbyNone
	}
	if isWaitingLobbyStatus(otherStatus) {
		return otherLobbyRelease
	}
	if otherStatus == lobbyStatusInGame && otherGameStatus == gameStatusActive {
		return otherLobbyBlock
	}
	return otherLobbyClear
}
