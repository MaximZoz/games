package api

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/nardy"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

const (
	nardyGameType   = "nardy"
	nardyBotID      = nardy.BotID
	nardyStatusOver = "over"
	nardyBotDelay   = 750 * time.Millisecond
	nardyMaxPlayers = 2
)

type createNardyLobbyBody struct {
	Mode        string `json:"mode"`
	TurnTimeSec int    `json:"turn_time_sec"`
	StakeBronze int    `json:"stake_bronze"`
	GameMode    string `json:"game_mode"`
	VsBot       bool   `json:"vs_bot"`
}

type nardyMoveBody struct {
	Action string `json:"action"`
	From   int    `json:"from"`
	Die    int    `json:"die"`
}

func nardyMatchmakeLockKey(gameMode string, turnTimeSec, stakeBronze int) string {
	return fmt.Sprintf("nardy_open_lock:%s:%d:%d", gameMode, turnTimeSec, stakeBronze)
}

// serveNardy — dispatcher для `/api/games/nardy/*`.
func (h *GamesHandler) serveNardy(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/games/nardy/")
	parts := strings.Split(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreateNardyLobby(w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListNardyLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.NardyRematch(w, r)
	case len(parts) >= 2 && parts[0] == "lobby":
		lobbyID := parts[1]
		if lobbyID == "" {
			WriteErr(w, r, http.StatusBadRequest, "lobby id required")
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "invite" && r.Method == http.MethodPost:
			h.InviteToLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "join" && r.Method == http.MethodPost:
			h.JoinNardyLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "cancel-invite" && r.Method == http.MethodPost:
			h.CancelInvite(w, r, lobbyID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	case len(parts) >= 2 && parts[0] == "game":
		gameID := parts[1]
		if gameID == "" {
			WriteErr(w, r, http.StatusBadRequest, "game id required")
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetNardyGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
			h.NardyMove(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.ForfeitNardyGame(w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

func (h *GamesHandler) CreateNardyLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body createNardyLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	mode := strings.ToLower(strings.TrimSpace(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		mode = "invite"
	}
	gameMode := nardy.NormalizeMode(strings.ToLower(strings.TrimSpace(body.GameMode)))
	if !validTurnTimeSec[body.TurnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	stakeBronze := body.StakeBronze
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	mayStake, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !mayStake {
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
		return
	}
	if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
		if err == store.ErrInsufficientFunds {
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		} else {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}

	if body.VsBot {
		lobbyID := uuid.New().String()
		gameID, err := h.startNardyGameCore(
			ctx,
			lobbyID,
			[]string{userID.String(), nardyBotID},
			[]uuid.UUID{userID},
			gameMode,
			body.TurnTimeSec,
			stakeBronze,
		)
		if err != nil {
			h.writeNardyStartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"lobby_id": lobbyID,
			"game_id":  gameID,
			"matched":  true,
		})
		return
	}

	if mode == "matchmake" {
		lockKey := nardyMatchmakeLockKey(gameMode, body.TurnTimeSec, stakeBronze)
		if locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result(); locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existing := h.findOpenNardyLobbyID(ctx, userID, gameMode, body.TurnTimeSec, stakeBronze); existing != "" {
			h.JoinNardyLobby(w, r, existing)
			return
		}
	}

	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", nardyGameType,
		"creator_id", userID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(body.TurnTimeSec),
		"max_players", strconv.Itoa(nardyMaxPlayers),
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", userID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id":   lobbyID,
		"status":     lobbyStatusWaitingInvite,
		"created_at": now,
		"creator_id": userID.String(),
		"game_mode":  gameMode,
		"matched":    false,
	})
}

func (h *GamesHandler) findOpenNardyLobbyID(
	ctx context.Context,
	excludeUser uuid.UUID,
	gameMode string,
	turnTimeSec, stakeBronze int,
) string {
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil {
		return ""
	}
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["game_type"] != nardyGameType || m["mode"] != "matchmake" {
			continue
		}
		if m["status"] != lobbyStatusWaitingInvite && m["status"] != lobbyStatusWaitingMatchmake {
			continue
		}
		if strings.TrimSpace(m["invite_target_id"]) != "" || m["creator_id"] == excludeUser.String() {
			continue
		}
		if nardy.NormalizeMode(m["game_mode"]) != gameMode {
			continue
		}
		if value, _ := strconv.Atoi(m["turn_time_sec"]); value != turnTimeSec {
			continue
		}
		stake, _ := strconv.Atoi(m["stake_bronze"])
		if stake < 2 {
			stake = 2
		}
		if stake != stakeBronze {
			continue
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) >= nardyMaxPlayers {
			continue
		}
		if stringSliceContains(players, excludeUser.String()) {
			continue
		}
		return strings.TrimPrefix(key, "lobby:")
	}
	return ""
}

func (h *GamesHandler) ListNardyLobbies(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	keys, err := scanRedisKeys(r.Context(), h.Rdb, "lobby:*")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	items := make([]map[string]any, 0, 8)
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, _ := h.Rdb.HGetAll(r.Context(), key).Result()
		if m["game_type"] != nardyGameType || m["creator_id"] == userID.String() {
			continue
		}
		status := m["status"]
		public := status == lobbyStatusWaitingMatchmake ||
			(status == lobbyStatusWaitingInvite && m["mode"] == "matchmake" &&
				strings.TrimSpace(m["invite_target_id"]) == "")
		if !public {
			continue
		}
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 2 {
			stakeBronze = 2
		}
		gameMode := nardy.NormalizeMode(m["game_mode"])
		items = append(items, map[string]any{
			"lobby_id":      strings.TrimPrefix(key, "lobby:"),
			"creator_id":    m["creator_id"],
			"status":        status,
			"game_type":     nardyGameType,
			"game_mode":     gameMode,
			"variant":       gameMode,
			"max_players":   nardyMaxPlayers,
			"turn_time_sec": turnTimeSec,
			"stake_bronze":  stakeBronze,
			"players_count": len(parsePlayerIDsCSV(m["player_ids"])),
			"created_at":    m["created_at"],
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"lobbies": items})
}

func (h *GamesHandler) JoinNardyLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["game_type"] != nardyGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	status := m["status"]
	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		WriteErr(w, r, http.StatusBadRequest, "lobby not joinable")
		return
	}
	if h.prepareJoinLobbySession(ctx, userID, lobbyID) {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}

	players := parsePlayerIDsCSV(m["player_ids"])
	already := stringSliceContains(players, userID.String())
	if !already {
		if len(players) >= nardyMaxPlayers {
			WriteErr(w, r, http.StatusConflict, "lobby full")
			return
		}
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 2 {
			stakeBronze = 2
		}
		mayStake, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if !mayStake {
			WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
			return
		}
		if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
			if err == store.ErrInsufficientFunds {
				WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
			} else {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
			}
			return
		}
		players = append(players, userID.String())
	}

	h.Rdb.HSet(ctx, key, "player_ids", strings.Join(players, ","))
	h.Rdb.Expire(ctx, key, lobbyTTL)
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	humans := nardyHumanUUIDs(players)
	h.broadcast(humans, map[string]any{
		"type":          "lobby_updated",
		"lobby_id":      lobbyID,
		"player_ids":    players,
		"players_count": len(players),
		"max_players":   nardyMaxPlayers,
	})
	if m["mode"] == "matchmake" && strings.TrimSpace(m["invite_target_id"]) == "" {
		h.notifyPublicLobbiesChanged()
	}
	if len(players) == nardyMaxPlayers {
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 2 {
			stakeBronze = 2
		}
		gameID, err := h.startNardyGameCore(
			ctx,
			lobbyID,
			players,
			humans,
			nardy.NormalizeMode(m["game_mode"]),
			turnTimeSec,
			stakeBronze,
		)
		if err != nil {
			h.writeNardyStartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"joined":   true,
			"game_id":  gameID,
			"lobby_id": lobbyID,
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"joined":        true,
		"lobby_id":      lobbyID,
		"status":        status,
		"players_count": len(players),
		"max_players":   nardyMaxPlayers,
		"waiting_more":  true,
		"already":       already,
		"creator_id":    m["creator_id"],
	})
}

func (h *GamesHandler) writeNardyStartError(w http.ResponseWriter, r *http.Request, err error) {
	switch err {
	case store.ErrStakeNotAllowed:
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
	case store.ErrInsufficientFunds:
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

func (h *GamesHandler) startNardyGameCore(
	ctx context.Context,
	lobbyID string,
	playerIDs []string,
	humans []uuid.UUID,
	gameMode string,
	turnTimeSec, stakeBronze int,
) (string, error) {
	if len(playerIDs) != nardyMaxPlayers {
		return "", fmt.Errorf("nardy: need exactly %d players", nardyMaxPlayers)
	}
	if stakeBronze > 0 {
		for _, userID := range humans {
			ok, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
			if err != nil {
				return "", err
			}
			if !ok {
				return "", store.ErrStakeNotAllowed
			}
			if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
				return "", err
			}
		}
		if err := store.DeductCoinsMany(ctx, h.Pool, humans, stakeBronze); err != nil {
			return "", err
		}
	}
	refund := func() {
		for _, userID := range humans {
			_ = store.AddCoins(ctx, h.Pool, userID, stakeBronze)
		}
	}
	state := nardy.NewGame(gameMode)
	// Первый бросок делает сервер: клиенту сразу видны кубики.
	_ = state.Roll(nardyRNG())
	encoded, err := nardy.Encode(state)
	if err != nil {
		refund()
		return "", err
	}
	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	now := time.Now().UTC()
	turnDeadline := int64(0)
	if turnTimeSec > 0 {
		turnDeadline = now.Unix() + int64(turnTimeSec)
	}
	fields := []any{
		"game_type", nardyGameType,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"game_mode", gameMode,
		"variant", gameMode,
		"max_players", strconv.Itoa(nardyMaxPlayers),
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"player_ids", strings.Join(playerIDs, ","),
		"state", encoded,
		"turn_deadline", strconv.FormatInt(turnDeadline, 10),
		"turn_actor_idx", strconv.Itoa(state.Turn),
		"started_at", now.Format(time.RFC3339Nano),
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gameKey, fields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"game_type", nardyGameType,
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", strings.Join(playerIDs, ","),
	)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		refund()
		return "", err
	}
	h.notifyAndClearLobbyInvites(ctx, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	for _, userID := range humans {
		clearUserActiveLobby(ctx, h.Rdb, userID)
		setUserActiveGame(ctx, h.Rdb, userID, gameID)
	}
	h.publishGameStartedTyped(humans, gameID, lobbyID, nardyGameType)
	if nardyCurrentPlayerIsBot(state, playerIDs) {
		h.scheduleNardyBotAct(gameID)
	}
	return gameID, nil
}

func nardyRNG() *rand.Rand {
	return rand.New(rand.NewSource(time.Now().UTC().UnixNano()))
}

func (h *GamesHandler) GetNardyGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != nardyGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	h.applyNardyTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	state, err := nardy.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if m["status"] == gameStatusActive &&
		nardyCurrentPlayerIsBot(state, parsePlayerIDsCSV(m["player_ids"])) {
		h.scheduleNardyBotAct(gameID)
	}
	writeJSON(w, http.StatusOK, h.nardyViewFor(ctx, state, userID.String(), m, gameID))
}

func (h *GamesHandler) NardyMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body nardyMoveBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if err := h.applyNardyUserAction(r.Context(), gameID, userID, body); err != nil {
		h.writeNardyActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (h *GamesHandler) ForfeitNardyGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := h.applyNardyUserAction(
		r.Context(),
		gameID,
		userID,
		nardyMoveBody{Action: "forfeit"},
	); err != nil {
		h.writeNardyActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "forfeit": true})
}

type nardyHTTPError struct {
	status int
	msg    string
}

func (e *nardyHTTPError) Error() string { return e.msg }

func (h *GamesHandler) writeNardyActionError(w http.ResponseWriter, r *http.Request, err error) {
	if httpErr, ok := err.(*nardyHTTPError); ok {
		WriteErr(w, r, httpErr.status, httpErr.msg)
		return
	}
	WriteErr(w, r, http.StatusBadRequest, err.Error())
}

func (h *GamesHandler) applyNardyUserAction(
	ctx context.Context,
	gameID string,
	userID uuid.UUID,
	body nardyMoveBody,
) error {
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return &nardyHTTPError{status: http.StatusNotFound, msg: "game not found"}
	}
	if m["game_type"] != nardyGameType {
		return &nardyHTTPError{status: http.StatusBadRequest, msg: "wrong game type"}
	}
	h.applyNardyTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive {
		return &nardyHTTPError{status: http.StatusBadRequest, msg: "game is over"}
	}
	state, err := nardy.Decode(m["state"])
	if err != nil {
		return &nardyHTTPError{status: http.StatusInternalServerError, msg: "bad state"}
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := nardySeatOf(players, userID.String())
	if seat < 0 {
		return &nardyHTTPError{status: http.StatusForbidden, msg: "not a player"}
	}

	action := strings.ToLower(strings.TrimSpace(body.Action))
	if action == "" {
		action = "move"
	}
	switch action {
	case "forfeit":
		state.Forfeit(seat)
	case "roll":
		if seat != state.Turn {
			return &nardyHTTPError{status: http.StatusBadRequest, msg: "not your turn"}
		}
		if err := state.Roll(nardyRNG()); err != nil {
			return &nardyHTTPError{status: http.StatusBadRequest, msg: err.Error()}
		}
	case "move":
		if err := state.ApplyMove(seat, nardy.Move{From: body.From, Die: body.Die}); err != nil {
			return &nardyHTTPError{status: http.StatusBadRequest, msg: err.Error()}
		}
	case "end_turn":
		if seat != state.Turn {
			return &nardyHTTPError{status: http.StatusBadRequest, msg: "not your turn"}
		}
		if state.HasLegalMove() {
			return &nardyHTTPError{status: http.StatusBadRequest, msg: "moves are still available"}
		}
		state.EndTurn()
	default:
		return &nardyHTTPError{status: http.StatusBadRequest, msg: "unknown action"}
	}

	if action == "forfeit" && !nardyIsOver(state) {
		moveActiveToObserving(ctx, h.Rdb, userID, gameID)
	}
	h.saveNardyState(ctx, gameID, m, state)
	if action == "forfeit" {
		m["forfeit"] = "1"
		h.Rdb.HSet(ctx, key, "forfeit", "1")
	}
	h.broadcastNardyState(gameID, m)
	if nardyIsOver(state) {
		reason := "normal"
		if action == "forfeit" {
			reason = "forfeit"
		}
		h.onNardyGameFinished(ctx, gameID, m, state, reason)
	} else {
		h.notifyNardyTurn(gameID, state, players)
	}
	return nil
}

func (h *GamesHandler) NardyRematch(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body struct {
		GameID string `json:"game_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+body.GameID).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != nardyGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if !stringSliceContains(players, userID.String()) {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	gameMode := nardy.NormalizeMode(m["game_mode"])
	invitees := make([]string, 0, 1)
	hasBot := false
	for _, playerID := range players {
		if isBot(playerID) {
			hasBot = true
		} else if playerID != userID.String() {
			invitees = append(invitees, playerID)
		}
	}
	if len(invitees) == 0 && hasBot {
		lobbyID := uuid.New().String()
		gameID, err := h.startNardyGameCore(
			ctx,
			lobbyID,
			[]string{userID.String(), nardyBotID},
			[]uuid.UUID{userID},
			gameMode,
			turnTimeSec,
			stakeBronze,
		)
		if err != nil {
			h.writeNardyStartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"lobby_id": lobbyID,
			"game_id":  gameID,
			"matched":  true,
		})
		return
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents")
		return
	}
	lobbyID, err := h.createNardyInviteLobby(ctx, userID, invitees, gameMode, turnTimeSec, stakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

func (h *GamesHandler) createNardyInviteLobby(
	ctx context.Context,
	creatorID uuid.UUID,
	invitees []string,
	gameMode string,
	turnTimeSec, stakeBronze int,
) (string, error) {
	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", nardyGameType,
		"creator_id", creatorID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", time.Now().UTC().Format(time.RFC3339Nano),
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"max_players", strconv.Itoa(nardyMaxPlayers),
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", creatorID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"invite_target_id", invitees[0],
	)
	pipe.Expire(ctx, key, lobbyTTL)
	for _, invitee := range invitees {
		pipe.SAdd(ctx, key+":invited", invitee)
	}
	pipe.Expire(ctx, key+":invited", lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		return "", err
	}
	h.trackUserInvites(ctx, lobbyID, invitees)
	setUserActiveLobby(ctx, h.Rdb, creatorID, lobbyID)
	h.broadcastNardyInvites(ctx, creatorID, invitees, lobbyID, gameMode, turnTimeSec, stakeBronze)
	return lobbyID, nil
}

func (h *GamesHandler) broadcastNardyInvites(
	ctx context.Context,
	creatorID uuid.UUID,
	invitees []string,
	lobbyID string,
	gameMode string,
	turnTimeSec, stakeBronze int,
) {
	creator, _ := store.GetUserByID(ctx, h.Pool, creatorID)
	creatorName := "Игрок"
	creatorAvatarKind := ""
	creatorAvatarValue := ""
	if creator != nil {
		if creator.DisplayName != nil && *creator.DisplayName != "" {
			creatorName = *creator.DisplayName
		}
		creatorAvatarKind = creator.AvatarKind
		if creator.AvatarValue != nil {
			creatorAvatarValue = *creator.AvatarValue
		}
	}
	payload := map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    creatorID.String(),
		"creator_name":  creatorName,
		"game_type":     nardyGameType,
		"game_mode":     gameMode,
		"variant":       gameMode,
		"turn_time_sec": turnTimeSec,
		"max_players":   nardyMaxPlayers,
		"stake_bronze":  stakeBronze,
	}
	if creatorAvatarKind != "" {
		payload["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		payload["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast(nardyHumanUUIDs(invitees), payload)
}

func (h *GamesHandler) saveNardyState(
	ctx context.Context,
	gameID string,
	m map[string]string,
	state *nardy.Game,
) {
	encoded, err := nardy.Encode(state)
	if err != nil {
		return
	}
	fields := []any{"state", encoded}
	if nardyIsOver(state) {
		fields = append(fields,
			"status", nardyStatusOver,
			"turn_deadline", "0",
			"turn_actor_idx", "-1",
		)
		m["status"] = nardyStatusOver
		m["turn_deadline"] = "0"
		m["turn_actor_idx"] = "-1"
	} else {
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		deadline := int64(0)
		if turnTimeSec > 0 {
			deadline = time.Now().UTC().Unix() + int64(turnTimeSec)
		}
		fields = append(fields,
			"status", gameStatusActive,
			"turn_deadline", strconv.FormatInt(deadline, 10),
			"turn_actor_idx", strconv.Itoa(state.Turn),
		)
		m["status"] = gameStatusActive
		m["turn_deadline"] = strconv.FormatInt(deadline, 10)
		m["turn_actor_idx"] = strconv.Itoa(state.Turn)
	}
	m["state"] = encoded
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
}

func (h *GamesHandler) broadcastNardyState(gameID string, m map[string]string) {
	if m == nil {
		return
	}
	ctx := context.Background()
	if h.Rdb != nil {
		if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
			m = fresh
		}
	}
	humans := nardyHumans(m)
	state, err := nardy.Decode(m["state"])
	if err != nil || state == nil {
		h.broadcast(humans, map[string]any{
			"type":      "game_state",
			"game_id":   gameID,
			"game_type": nardyGameType,
		})
		return
	}
	for _, u := range humans {
		view := h.nardyViewFor(ctx, state, u.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{u}, view)
	}
}

func (h *GamesHandler) notifyNardyTurn(gameID string, state *nardy.Game, players []string) {
	if state == nil || nardyIsOver(state) {
		return
	}
	if nardyCurrentPlayerIsBot(state, players) {
		h.scheduleNardyBotAct(gameID)
		return
	}
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	h.notifyYourTurnUser(gameID, players[state.Turn], nardyGameType)
}

func (h *GamesHandler) onNardyGameFinished(
	ctx context.Context,
	gameID string,
	m map[string]string,
	state *nardy.Game,
	finishReason string,
) {
	if h.Rdb == nil || state == nil {
		return
	}
	processed, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "finished_processed", "1").Result()
	if err != nil || !processed {
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	humans := nardyHumanUUIDs(players)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	lobbyID := strings.TrimSpace(m["lobby_id"])
	if lobbyID != "" {
		h.Rdb.Del(ctx, "lobby:"+lobbyID)
		h.Rdb.Del(ctx, "lobby:"+lobbyID+":invited")
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	winners := make([]string, 0, 1)
	if state.Winner >= 0 && state.Winner < len(players) {
		winners = append(winners, players[state.Winner])
	}
	settled, _ := h.Rdb.HSetNX(ctx, "game:"+gameID, "coins_settled", "1").Result()
	if settled {
		_ = store.SettleStakePot(
			ctx,
			h.Pool,
			stakeBronze,
			players,
			winners,
			len(winners) == 0,
			isBot,
		)
	}
	for _, userID := range humans {
		_ = store.IncrementGamesFinished(ctx, h.Pool, userID)
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
		notifyAchievementUnlocks(h.Push, userID, unlocked)
	}
	for _, winnerID := range winners {
		if isBot(winnerID) {
			continue
		}
		if userID, err := uuid.Parse(winnerID); err == nil {
			_ = store.IncrementWinsByStake(ctx, h.Pool, userID, stakeBronze)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
			notifyAchievementUnlocks(h.Push, userID, unlocked)
		}
	}
	h.recordNardyGameResult(ctx, gameID, m, players, winners, stakeBronze, finishReason)
}

func (h *GamesHandler) recordNardyGameResult(
	ctx context.Context,
	gameID string,
	m map[string]string,
	players []string,
	winners []string,
	stakeBronze int,
	finishReason string,
) {
	if len(players) < 2 {
		return
	}
	winnerID := ""
	if len(winners) > 0 {
		winnerID = winners[0]
	}
	durationSec := 0
	if startedAt, ok := parseGameStartedAt(m["started_at"]); ok {
		durationSec = clampNonNegative(int(time.Since(startedAt).Seconds()))
	}
	xID, oID := players[0], players[1]
	result := "draw"
	if winnerID == xID {
		result = "x_won"
	} else if winnerID == oID {
		result = "o_won"
	}
	gameResult := store.GameResult{
		GameID:       gameID,
		GameType:     store.GameTypeNardy,
		Result:       result,
		FinishReason: finishReason,
		StakeBronze:  stakeBronze,
		DurationSec:  durationSec,
		AgainstBot:   isBot(xID) || isBot(oID),
	}
	if userID, err := uuid.Parse(xID); err == nil {
		gameResult.XUserID = userID
	}
	if userID, err := uuid.Parse(oID); err == nil {
		gameResult.OUserID = userID
	}
	if !isBot(winnerID) {
		if userID, err := uuid.Parse(winnerID); err == nil {
			gameResult.WinnerUserID = &userID
		}
	}
	_ = store.RecordGameResult(ctx, h.Pool, gameResult)
}

func (h *GamesHandler) nardyViewFor(
	ctx context.Context,
	state *nardy.Game,
	viewer string,
	m map[string]string,
	gameID string,
) map[string]any {
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := nardySeatOf(players, viewer)
	turnDeadline, _ := strconv.ParseInt(m["turn_deadline"], 10, 64)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])

	userIDs := make([]uuid.UUID, 0, len(players))
	for _, playerID := range players {
		if userID, err := uuid.Parse(playerID); err == nil {
			userIDs = append(userIDs, userID)
		}
	}
	users, _ := store.GetUsersByIDs(ctx, h.Pool, userIDs)
	frames, _ := store.EquippedFramesMap(ctx, h.Pool, userIDs)
	playerViews := make([]map[string]any, 0, len(players))
	for index, playerID := range players {
		player := map[string]any{
			"user_id":      playerID,
			"seat":         index,
			"display_name": "",
			"off":          state.Off[index],
			"bar":          state.Bar[index],
			"pips":         state.Pips(index),
		}
		if isBot(playerID) {
			player["display_name"] = "Бот"
			player["is_bot"] = true
			playerViews = append(playerViews, player)
			continue
		}
		userID, err := uuid.Parse(playerID)
		if err != nil {
			playerViews = append(playerViews, player)
			continue
		}
		if user := users[userID]; user != nil {
			if user.DisplayName != nil && *user.DisplayName != "" {
				player["display_name"] = *user.DisplayName
			}
			if user.AvatarKind != "" {
				player["avatar_kind"] = user.AvatarKind
			}
			if user.AvatarValue != nil {
				player["avatar_value"] = *user.AvatarValue
			}
		}
		if frame, ok := frames[userID]; ok {
			player["frame_code"] = frame.Code
			player["frame_color"] = frame.Color
		}
		playerViews = append(playerViews, player)
	}

	legal := make([]map[string]any, 0, 8)
	if seat >= 0 && seat == state.Turn && !nardyIsOver(state) {
		for _, mv := range state.LegalMoves() {
			legal = append(legal, map[string]any{"from": mv.From, "die": mv.Die})
		}
	}
	board := make([]int, nardy.Points)
	for i := 0; i < nardy.Points; i++ {
		board[i] = state.Board[i]
	}

	over := nardyIsOver(state)
	winnerID := ""
	if state.Winner >= 0 && state.Winner < len(players) {
		winnerID = players[state.Winner]
	}
	return map[string]any{
		"id":             gameID,
		"game_id":        gameID,
		"game_type":      nardyGameType,
		"lobby_id":       m["lobby_id"],
		"game_mode":      nardy.NormalizeMode(state.Mode),
		"board":          board,
		"bar":            []int{state.Bar[0], state.Bar[1]},
		"off":            []int{state.Off[0], state.Off[1]},
		"dice":           state.Dice,
		"rolled":         state.Rolled,
		"turn":           state.Turn,
		"turn_no":        state.TurnNo,
		"head_moved":     state.HeadMoved,
		"players":        playerViews,
		"player_ids":     players,
		"legal_moves":    legal,
		"my_index":       seat,
		"is_my_turn":     seat >= 0 && seat == state.Turn && !over,
		"needs_roll":     seat >= 0 && seat == state.Turn && len(state.Dice) == 0 && !over,
		"turn_time_sec":  turnTimeSec,
		"turn_deadline":  turnDeadline,
		"stake_bronze":   stakeBronze,
		"is_over":        over,
		"winner_index":   state.Winner,
		"winner_user_id": winnerID,
		"win_kind":       state.WinKind,
		"is_forfeit":     m["forfeit"] == "1" && over,
		"is_timeout":     m["timeout"] == "1",
	}
}

func nardyIsOver(state *nardy.Game) bool {
	return state != nil && state.Winner >= 0
}

func nardySeatOf(players []string, userID string) int {
	for index, playerID := range players {
		if playerID == userID {
			return index
		}
	}
	return -1
}

func nardyCurrentPlayerIsBot(state *nardy.Game, players []string) bool {
	if state == nil || nardyIsOver(state) {
		return false
	}
	if state.Turn < 0 || state.Turn >= len(players) {
		return false
	}
	return isBot(players[state.Turn])
}

func nardyHumanUUIDs(playerIDs []string) []uuid.UUID {
	humans := make([]uuid.UUID, 0, len(playerIDs))
	for _, playerID := range playerIDs {
		if isBot(playerID) {
			continue
		}
		if userID, err := uuid.Parse(playerID); err == nil {
			humans = append(humans, userID)
		}
	}
	return humans
}

func nardyHumans(m map[string]string) []uuid.UUID {
	return nardyHumanUUIDs(parsePlayerIDsCSV(m["player_ids"]))
}
