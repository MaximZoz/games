package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/domino"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

const (
	dominoGameType   = "domino"
	dominoBotID      = "bot:domino"
	dominoStatusOver = "over"
	dominoBotDelay   = 420 * time.Millisecond
	dominoRoundPause = 2200 * time.Millisecond
)

type createDominoLobbyBody struct {
	Mode        string `json:"mode"`
	MaxPlayers  int    `json:"max_players"`
	TurnTimeSec int    `json:"turn_time_sec"`
	StakeBronze int    `json:"stake_bronze"`
	GameMode    string `json:"game_mode"`
}

const dominoChatTitle = "Домино"

func dominoMatchmakeLockKey(turnTimeSec, maxPlayers, stakeBronze int, gameMode string) string {
	return fmt.Sprintf("domino_open_lock:%s:%d:%d:%d", domino.NormalizeMode(gameMode), turnTimeSec, maxPlayers, stakeBronze)
}

func dominoModeOf(m map[string]string) string {
	raw := strings.TrimSpace(m["game_mode"])
	if raw == "" {
		raw = strings.TrimSpace(m["variant"])
	}
	return domino.NormalizeMode(raw)
}

func (h *GamesHandler) serveDomino(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/games/domino/")
	parts := strings.Split(path, "/")
	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreateDominoLobby(w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListDominoLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.DominoRematch(w, r)
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
			h.JoinDominoLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "matchmake" && r.Method == http.MethodPost:
			h.StartLobbyMatchmake(w, r, lobbyID)
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
		h.callGame(w, r, gameID, func(w http.ResponseWriter, r *http.Request) {
			switch {
			case len(parts) == 2 && r.Method == http.MethodGet:
				h.GetDominoGame(w, r, gameID)
			case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
				h.DominoMove(w, r, gameID)
			case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
				h.ForfeitDominoGame(w, r, gameID)
			default:
				WriteErr(w, r, http.StatusNotFound, "not found")
			}
		})
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

func (h *GamesHandler) CreateDominoLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body createDominoLobbyBody
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
	gameMode := domino.NormalizeMode(body.GameMode)
	maxPlayers := body.MaxPlayers
	if maxPlayers < 1 || maxPlayers > 4 {
		maxPlayers = 2
	}
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
	if maxPlayers == 1 {
		lobbyID := uuid.New().String()
		h.rememberLobby(lobbyID)
		gameID, err := h.startDominoGameCore(
			ctx,
			lobbyID,
			[]string{userID.String(), dominoBotID},
			[]uuid.UUID{userID},
			body.TurnTimeSec,
			stakeBronze,
			2,
			gameMode,
		)
		if err != nil {
			h.writeDominoStartError(w, r, err)
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
		lockKey := dominoMatchmakeLockKey(body.TurnTimeSec, maxPlayers, stakeBronze, gameMode)
		if locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result(); locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existing := h.findOpenDominoLobbyID(ctx, userID, body.TurnTimeSec, maxPlayers, stakeBronze, gameMode); existing != "" {
			h.JoinDominoLobby(w, r, existing)
			return
		}
	}
	lobbyID := uuid.New().String()
	h.rememberLobby(lobbyID)
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", dominoGameType,
		"creator_id", userID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(body.TurnTimeSec),
		"max_players", strconv.Itoa(maxPlayers),
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
	if maxPlayers > 2 {
		if cid, err := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{userID}, dominoChatTitle, dominoGameType); err == nil {
			h.Rdb.HSet(ctx, key, "chat_id", cid.String())
			h.broadcast([]uuid.UUID{userID}, map[string]any{"type": "chat_list_changed"})
		}
	}
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id":   lobbyID,
		"status":     lobbyStatusWaitingInvite,
		"created_at": now,
		"creator_id": userID.String(),
		"matched":    false,
	})
}

func (h *GamesHandler) findOpenDominoLobbyID(ctx context.Context, excludeUser uuid.UUID, turnTimeSec, maxPlayers, stakeBronze int, gameMode string) string {
	keys, err := h.lobbyHashKeys(ctx)
	if err != nil {
		return ""
	}
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["game_type"] != dominoGameType || m["mode"] != "matchmake" {
			continue
		}
		if m["status"] != lobbyStatusWaitingInvite && m["status"] != lobbyStatusWaitingMatchmake {
			continue
		}
		if strings.TrimSpace(m["invite_target_id"]) != "" || m["creator_id"] == excludeUser.String() {
			continue
		}
		if value, _ := strconv.Atoi(m["turn_time_sec"]); value != turnTimeSec {
			continue
		}
		if value, _ := strconv.Atoi(m["max_players"]); value != maxPlayers {
			continue
		}
		stake, _ := strconv.Atoi(m["stake_bronze"])
		if stake < 2 {
			stake = 2
		}
		if stake != stakeBronze {
			continue
		}
		if dominoModeOf(m) != domino.NormalizeMode(gameMode) {
			continue
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) >= maxPlayers || stringSliceContains(players, excludeUser.String()) {
			continue
		}
		return strings.TrimPrefix(key, "lobby:")
	}
	return ""
}

func (h *GamesHandler) ListDominoLobbies(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	keys, err := h.lobbyHashKeys(r.Context())
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
		if m["game_type"] != dominoGameType || m["creator_id"] == userID.String() {
			continue
		}
		status := m["status"]
		public := status == lobbyStatusWaitingMatchmake ||
			(status == lobbyStatusWaitingInvite && m["mode"] == "matchmake" && strings.TrimSpace(m["invite_target_id"]) == "")
		if !public {
			continue
		}
		maxPlayers, _ := strconv.Atoi(m["max_players"])
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 2 {
			stakeBronze = 2
		}
		items = append(items, map[string]any{
			"lobby_id":      strings.TrimPrefix(key, "lobby:"),
			"creator_id":    m["creator_id"],
			"status":        status,
			"game_type":     dominoGameType,
			"game_mode":     dominoModeOf(m),
			"max_players":   maxPlayers,
			"turn_time_sec": turnTimeSec,
			"stake_bronze":  stakeBronze,
			"players_count": len(parsePlayerIDsCSV(m["player_ids"])),
			"created_at":    m["created_at"],
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"lobbies": items})
}

func (h *GamesHandler) JoinDominoLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
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
	if m["game_type"] != dominoGameType {
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
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 2 || maxPlayers > 4 {
		maxPlayers = 2
	}
	if !already {
		if len(players) >= maxPlayers {
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
	humans := dominoHumanUUIDs(players)
	h.broadcast(humans, map[string]any{
		"type":          "lobby_updated",
		"lobby_id":      lobbyID,
		"player_ids":    players,
		"players_count": len(players),
		"max_players":   maxPlayers,
	})
	if m["mode"] == "matchmake" && strings.TrimSpace(m["invite_target_id"]) == "" {
		h.notifyPublicLobbiesChanged()
	}
	if maxPlayers > 2 {
		if cid, err := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, humans, dominoChatTitle, dominoGameType); err == nil {
			h.Rdb.HSet(ctx, key, "chat_id", cid.String())
			h.broadcast(humans, map[string]any{"type": "chat_list_changed"})
		}
	}
	if len(players) == maxPlayers {
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 2 {
			stakeBronze = 2
		}
		gameID, err := h.startDominoGameCore(ctx, lobbyID, players, humans, turnTimeSec, stakeBronze, maxPlayers, dominoModeOf(m))
		if err != nil {
			h.writeDominoStartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"joined": true, "game_id": gameID, "lobby_id": lobbyID})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"joined":        true,
		"lobby_id":      lobbyID,
		"status":        status,
		"players_count": len(players),
		"max_players":   maxPlayers,
		"waiting_more":  true,
		"already":       already,
		"creator_id":    m["creator_id"],
	})
}

func (h *GamesHandler) writeDominoStartError(w http.ResponseWriter, r *http.Request, err error) {
	switch err {
	case store.ErrStakeNotAllowed:
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
	case store.ErrInsufficientFunds:
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

func (h *GamesHandler) startDominoGameCore(ctx context.Context, lobbyID string, playerIDs []string, humans []uuid.UUID, turnTimeSec, stakeBronze, maxPlayers int, gameMode string) (string, error) {
	if len(playerIDs) < 2 || len(playerIDs) > 4 {
		return "", fmt.Errorf("domino: need 2..4 players")
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
	gameMode = domino.NormalizeMode(gameMode)
	state, err := domino.NewMatch(playerIDs, time.Now().UTC().UnixNano(), gameMode)
	if err != nil {
		for _, userID := range humans {
			_ = store.AddCoins(ctx, h.Pool, userID, stakeBronze)
		}
		return "", err
	}
	encoded, err := domino.Encode(state)
	if err != nil {
		for _, userID := range humans {
			_ = store.AddCoins(ctx, h.Pool, userID, stakeBronze)
		}
		return "", err
	}
	gameID := uuid.New().String()
	now := time.Now().UTC()
	turnDeadline := int64(0)
	if turnTimeSec > 0 {
		turnDeadline = now.Unix() + int64(turnTimeSec)
	}
	fields := []any{
		"game_type", dominoGameType,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"game_mode", gameMode,
		"variant", gameMode,
		"max_players", strconv.Itoa(maxPlayers),
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"player_ids", strings.Join(playerIDs, ","),
		"state", encoded,
		"turn_deadline", strconv.FormatInt(turnDeadline, 10),
		"turn_actor_idx", strconv.Itoa(state.Turn),
		"started_at", now.Format(time.RFC3339Nano),
	}
	if chatID, _ := h.Rdb.HGet(ctx, "lobby:"+lobbyID, "chat_id").Result(); chatID != "" {
		fields = append(fields, "chat_id", chatID)
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, "game:"+gameID, fields...)
	pipe.Expire(ctx, "game:"+gameID, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"game_type", dominoGameType,
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", strings.Join(playerIDs, ","),
	)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		for _, userID := range humans {
			_ = store.AddCoins(ctx, h.Pool, userID, stakeBronze)
		}
		return "", err
	}
	h.notifyAndClearLobbyInvites(ctx, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	for _, userID := range humans {
		clearUserActiveLobby(ctx, h.Rdb, userID)
		setUserActiveGame(ctx, h.Rdb, userID, gameID)
	}
	h.publishGameStartedTyped(humans, gameID, lobbyID, dominoGameType)
	h.notifyDominoTurn(gameID, state)
	return gameID, nil
}

func (h *GamesHandler) GetDominoGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != dominoGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	h.applyDominoTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	state, err := domino.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if m["status"] == gameStatusActive && state.Status == domino.StatusRoundEnd {
		h.scheduleDominoNextRound(gameID)
	} else if m["status"] == gameStatusActive && dominoCurrentIsBot(state) {
		h.scheduleDominoBotAct(gameID)
	}
	writeJSON(w, http.StatusOK, h.dominoViewFor(ctx, state, userID.String(), m, gameID))
}

func (h *GamesHandler) DominoMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var action domino.Action
	if err := json.NewDecoder(r.Body).Decode(&action); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if err := h.applyDominoUserAction(r.Context(), gameID, userID, action); err != nil {
		h.writeDominoActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (h *GamesHandler) ForfeitDominoGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := h.applyDominoUserAction(r.Context(), gameID, userID, domino.Action{Type: domino.ActionForfeit, Actor: userID.String()}); err != nil {
		h.writeDominoActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "forfeit": true})
}

type dominoHTTPError struct {
	status int
	msg    string
}

func (e *dominoHTTPError) Error() string { return e.msg }

func (h *GamesHandler) writeDominoActionError(w http.ResponseWriter, r *http.Request, err error) {
	if httpErr, ok := err.(*dominoHTTPError); ok {
		WriteErr(w, r, httpErr.status, httpErr.msg)
		return
	}
	WriteErr(w, r, http.StatusBadRequest, err.Error())
}

func (h *GamesHandler) applyDominoUserAction(ctx context.Context, gameID string, userID uuid.UUID, action domino.Action) error {
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return &dominoHTTPError{status: http.StatusNotFound, msg: "game not found"}
	}
	if m["game_type"] != dominoGameType {
		return &dominoHTTPError{status: http.StatusBadRequest, msg: "wrong game type"}
	}
	h.applyDominoTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive {
		return &dominoHTTPError{status: http.StatusBadRequest, msg: "game is over"}
	}
	state, err := domino.Decode(m["state"])
	if err != nil {
		return &dominoHTTPError{status: http.StatusInternalServerError, msg: "bad state"}
	}
	playerIndex := state.PlayerIndex(userID.String())
	if playerIndex < 0 {
		return &dominoHTTPError{status: http.StatusForbidden, msg: "not a player"}
	}
	if state.Players[playerIndex].Forfeited {
		return &dominoHTTPError{status: http.StatusBadRequest, msg: "player forfeited"}
	}
	if action.Type == domino.ActionForfeit {
		action.Actor = userID.String()
	} else if state.Turn != playerIndex || state.Status != domino.StatusPlaying {
		return &dominoHTTPError{status: http.StatusBadRequest, msg: "not your turn"}
	}
	if err := state.Apply(action); err != nil {
		return err
	}
	if action.Type == domino.ActionForfeit && !state.IsOver() {
		moveActiveToObserving(ctx, h.Rdb, userID, gameID)
	}
	h.saveDominoState(ctx, gameID, m, state)
	if action.Type == domino.ActionForfeit && state.IsOver() {
		m["forfeit"] = "1"
		h.Rdb.HSet(ctx, key, "forfeit", "1")
	}
	h.broadcastDominoState(gameID, m)
	if state.IsOver() {
		reason := "normal"
		if action.Type == domino.ActionForfeit {
			reason = "forfeit"
		}
		h.onDominoGameFinished(ctx, gameID, m, state, reason)
	} else {
		h.notifyDominoTurn(gameID, state)
	}
	return nil
}

func (h *GamesHandler) DominoRematch(w http.ResponseWriter, r *http.Request) {
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
	if m["game_type"] != dominoGameType {
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
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 2 || maxPlayers > 4 {
		maxPlayers = len(players)
	}
	invitees := make([]string, 0, len(players)-1)
	botCount := 0
	for _, playerID := range players {
		if isBot(playerID) {
			botCount++
		} else if playerID != userID.String() {
			invitees = append(invitees, playerID)
		}
	}
	if len(invitees) == 0 && botCount > 0 {
		ids := []string{userID.String()}
		for i := 0; i < botCount; i++ {
			if i == 0 {
				ids = append(ids, dominoBotID)
			} else {
				ids = append(ids, fmt.Sprintf("%s:%d", dominoBotID, i+1))
			}
		}
		lobbyID := uuid.New().String()
		h.rememberLobby(lobbyID)
		gameID, err := h.startDominoGameCore(ctx, lobbyID, ids, []uuid.UUID{userID}, turnTimeSec, stakeBronze, len(ids), dominoModeOf(m))
		if err != nil {
			h.writeDominoStartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"lobby_id": lobbyID, "game_id": gameID, "matched": true})
		return
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents")
		return
	}
	lobbyID, err := h.createDominoInviteLobby(ctx, userID, invitees, turnTimeSec, stakeBronze, maxPlayers, dominoModeOf(m))
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"lobby_id": lobbyID, "status": lobbyStatusWaitingInvite, "matched": false})
}

func (h *GamesHandler) createDominoInviteLobby(ctx context.Context, creatorID uuid.UUID, invitees []string, turnTimeSec, stakeBronze, maxPlayers int, gameMode string) (string, error) {
	gameMode = domino.NormalizeMode(gameMode)
	lobbyID := uuid.New().String()
	h.rememberLobby(lobbyID)
	key := "lobby:" + lobbyID
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", dominoGameType,
		"creator_id", creatorID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", time.Now().UTC().Format(time.RFC3339Nano),
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"max_players", strconv.Itoa(maxPlayers),
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
	if maxPlayers > 2 {
		if chatID, err := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{creatorID}, dominoChatTitle, dominoGameType); err == nil {
			h.Rdb.HSet(ctx, key, "chat_id", chatID.String())
			h.broadcast([]uuid.UUID{creatorID}, map[string]any{"type": "chat_list_changed"})
		}
	}
	h.broadcastDominoInvites(ctx, creatorID, invitees, lobbyID, turnTimeSec, stakeBronze, maxPlayers, gameMode)
	return lobbyID, nil
}

func (h *GamesHandler) broadcastDominoInvites(ctx context.Context, creatorID uuid.UUID, invitees []string, lobbyID string, turnTimeSec, stakeBronze, maxPlayers int, gameMode string) {
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
	ids := make([]uuid.UUID, 0, len(invitees))
	for _, raw := range invitees {
		if id, err := uuid.Parse(raw); err == nil {
			ids = append(ids, id)
		}
	}
	payload := map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    creatorID.String(),
		"creator_name":  creatorName,
		"game_type":     dominoGameType,
		"game_mode":     domino.NormalizeMode(gameMode),
		"variant":       domino.NormalizeMode(gameMode),
		"turn_time_sec": turnTimeSec,
		"max_players":   maxPlayers,
		"stake_bronze":  stakeBronze,
	}
	if creatorAvatarKind != "" {
		payload["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		payload["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast(ids, payload)
}

func (h *GamesHandler) saveDominoState(ctx context.Context, gameID string, m map[string]string, state *domino.Game) {
	encoded, err := domino.Encode(state)
	if err != nil {
		return
	}
	fields := []any{"state", encoded}
	if state.IsOver() {
		fields = append(fields, "status", dominoStatusOver, "turn_deadline", "0", "turn_actor_idx", "-1")
		m["status"] = dominoStatusOver
		m["turn_deadline"] = "0"
		m["turn_actor_idx"] = "-1"
	} else if state.Status == domino.StatusRoundEnd {
		fields = append(fields, "status", gameStatusActive, "turn_deadline", "0", "turn_actor_idx", "-1")
		m["status"] = gameStatusActive
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

func (h *GamesHandler) broadcastDominoState(gameID string, m map[string]string) {
	if m == nil {
		return
	}
	ctx := context.Background()
	if h.Rdb != nil {
		if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
			m = fresh
		}
	}
	state, err := domino.Decode(m["state"])
	if err != nil || state == nil {
		h.broadcast(dominoHumans(m), map[string]any{"type": "game_state", "game_id": gameID, "game_type": dominoGameType})
		return
	}
	for _, userID := range dominoHumans(m) {
		view := h.dominoViewFor(ctx, state, userID.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{userID}, view)
	}
}

func (h *GamesHandler) notifyDominoTurn(gameID string, state *domino.Game) {
	if state == nil || state.IsOver() {
		return
	}
	if state.Status == domino.StatusRoundEnd {
		h.scheduleDominoNextRound(gameID)
		return
	}
	if state.Turn < 0 || state.Turn >= len(state.Players) {
		return
	}
	playerID := state.Players[state.Turn].UserID
	if isBot(playerID) {
		h.scheduleDominoBotAct(gameID)
	} else {
		h.notifyYourTurnUser(gameID, playerID, dominoGameType)
	}
}

func (h *GamesHandler) onDominoGameFinished(ctx context.Context, gameID string, m map[string]string, state *domino.Game, finishReason string) {
	if h.Rdb == nil || state == nil {
		return
	}
	processed, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "finished_processed", "1").Result()
	if err != nil || !processed {
		return
	}
	humans := dominoHumans(m)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	lobbyID := strings.TrimSpace(m["lobby_id"])
	if lobbyID != "" {
		h.Rdb.Del(ctx, "lobby:"+lobbyID)
		h.forgetLobby(lobbyID)
		h.Rdb.Del(ctx, "lobby:"+lobbyID+":invited")
		if strings.TrimSpace(m["chat_id"]) != "" {
			_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
			h.broadcast(humans, map[string]any{"type": "lobby_updated", "lobby_id": lobbyID, "closed": true})
			h.broadcast(humans, map[string]any{"type": "chat_list_changed"})
		}
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	settled, _ := h.Rdb.HSetNX(ctx, "game:"+gameID, "coins_settled", "1").Result()
	if settled {
		_ = store.SettleStakePot(ctx, h.Pool, stakeBronze, parsePlayerIDsCSV(m["player_ids"]), state.WinnerUserIDs, len(state.WinnerUserIDs) == 0, isBot)
	}
	for _, userID := range humans {
		_ = store.IncrementGamesFinished(ctx, h.Pool, userID)
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
		notifyAchievementUnlocks(h.Hub, h.Push, userID, unlocked)
	}
	for _, winnerID := range state.WinnerUserIDs {
		if isBot(winnerID) {
			continue
		}
		if userID, err := uuid.Parse(winnerID); err == nil {
			_ = store.IncrementWinsByStake(ctx, h.Pool, userID, stakeBronze)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
			notifyAchievementUnlocks(h.Hub, h.Push, userID, unlocked)
		}
	}
	h.recordDominoGameResult(ctx, gameID, m, state, stakeBronze, finishReason)
}

func (h *GamesHandler) recordDominoGameResult(ctx context.Context, gameID string, m map[string]string, state *domino.Game, stakeBronze int, finishReason string) {
	if state == nil || len(state.Players) < 2 {
		return
	}
	winnerID := ""
	if len(state.WinnerUserIDs) > 0 {
		winnerID = state.WinnerUserIDs[0]
	}
	durationSec := 0
	if startedAt, ok := parseGameStartedAt(m["started_at"]); ok {
		durationSec = clampNonNegative(int(time.Since(startedAt).Seconds()))
	}
	recordPair := func(rowID, xID, oID string) {
		result := "draw"
		if winnerID == xID {
			result = "x_won"
		} else if winnerID == oID {
			result = "o_won"
		}
		gameResult := store.GameResult{
			GameID:       rowID,
			GameType:     store.GameTypeDomino,
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
	if len(state.Players) == 2 {
		recordPair(gameID, state.Players[0].UserID, state.Players[1].UserID)
		return
	}
	if winnerID == "" {
		return
	}
	for _, player := range state.Players {
		if player.UserID != winnerID {
			recordPair(gameID+":"+player.UserID, winnerID, player.UserID)
		}
	}
}

func (h *GamesHandler) dominoViewFor(ctx context.Context, state *domino.Game, viewer string, m map[string]string, gameID string) map[string]any {
	view := state.View(viewer)
	raw, _ := json.Marshal(view)
	payload := map[string]any{}
	_ = json.Unmarshal(raw, &payload)
	userIDs := make([]uuid.UUID, 0, len(state.Players))
	for _, player := range state.Players {
		if userID, err := uuid.Parse(player.UserID); err == nil {
			userIDs = append(userIDs, userID)
		}
	}
	users, _ := store.GetUsersByIDs(ctx, h.Pool, userIDs)
	frames, _ := store.EquippedFramesMap(ctx, h.Pool, userIDs)
	if players, ok := payload["players"].([]any); ok {
		for index, rawPlayer := range players {
			player, ok := rawPlayer.(map[string]any)
			if !ok || index >= len(state.Players) {
				continue
			}
			playerID := state.Players[index].UserID
			if isBot(playerID) {
				player["display_name"] = "Бот"
				continue
			}
			userID, err := uuid.Parse(playerID)
			if err != nil {
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
		}
	}
	turnDeadline, _ := strconv.ParseInt(m["turn_deadline"], 10, 64)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	viewerIndex := state.PlayerIndex(viewer)
	myTurn := viewerIndex >= 0 && viewerIndex == state.Turn && state.Status == domino.StatusPlaying && !state.Players[viewerIndex].Forfeited && !state.IsOver()
	payload["id"] = gameID
	payload["game_id"] = gameID
	payload["game_type"] = dominoGameType
	payload["lobby_id"] = m["lobby_id"]
	payload["chat_id"] = m["chat_id"]
	payload["turn_time_sec"] = turnTimeSec
	payload["turn_deadline"] = turnDeadline
	payload["stake_bronze"] = stakeBronze
	payload["my_index"] = viewerIndex
	payload["is_my_turn"] = myTurn
	payload["is_over"] = state.IsOver()
	payload["is_forfeit"] = m["forfeit"] == "1" && state.IsOver()
	payload["is_timeout"] = m["timeout"] == "1"
	return payload
}

func dominoCurrentIsBot(state *domino.Game) bool {
	if state == nil || state.IsOver() || state.Status != domino.StatusPlaying {
		return false
	}
	if state.Turn < 0 || state.Turn >= len(state.Players) {
		return false
	}
	return isBot(state.Players[state.Turn].UserID)
}

func dominoHumanUUIDs(playerIDs []string) []uuid.UUID {
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

func dominoHumans(m map[string]string) []uuid.UUID {
	return dominoHumanUUIDs(parsePlayerIDsCSV(m["player_ids"]))
}
