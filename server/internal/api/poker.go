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

	"multigames/server/internal/poker"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

const (
	pokerGameType      = "poker"
	pokerStatusOver    = "over"
	pokerBotDelay      = 700 * time.Millisecond
	pokerNextHandDelay = 4 * time.Second
)

func pokerMatchmakeLockKey(turnTimeSec, maxPlayers, stakeBronze int) string {
	return fmt.Sprintf("poker_open_lock:%d:%d:%d", turnTimeSec, maxPlayers, stakeBronze)
}

// servePoker — dispatcher для `/api/games/poker/*`.
func (h *GamesHandler) servePoker(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/games/poker/")
	parts := strings.Split(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreatePokerLobby(w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListPokerLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.PokerRematch(w, r)
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
			h.JoinPokerLobby(w, r, lobbyID)
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
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetPokerGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
			h.PokerMove(w, r, gameID)
		case len(parts) == 3 && parts[2] == "show" && r.Method == http.MethodPost:
			h.PokerShowCards(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.ForfeitPokerGame(w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

// ---- Chips / blinds ----

func pokerChipConfig(stakeBronze int) (startingChips, smallBlind, bigBlind int) {
	bigBlind = stakeBronze
	if bigBlind < 2 {
		bigBlind = 2
	}
	smallBlind = bigBlind / 2
	if smallBlind < 1 {
		smallBlind = 1
	}
	startingChips = stakeBronze * 50
	if startingChips < 100 {
		startingChips = 100
	}
	return startingChips, smallBlind, bigBlind
}

// ---- CreatePokerLobby ----

type createPokerLobbyBody struct {
	Mode        string `json:"mode"`          // "invite" | "matchmake"
	MaxPlayers  int    `json:"max_players"`   // 2..6
	TurnTimeSec int    `json:"turn_time_sec"` // 0/20/60/600
	StakeBronze int    `json:"stake_bronze"`
}

func (h *GamesHandler) CreatePokerLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body createPokerLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()

	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}

	mode := strings.TrimSpace(strings.ToLower(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		mode = "invite"
	}
	maxPlayers := body.MaxPlayers
	if maxPlayers < 2 || maxPlayers > 6 {
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
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	// «Найти игру»: схлопнуться с уже открытым лобби тех же правил.
	if mode == "matchmake" {
		lockKey := pokerMatchmakeLockKey(body.TurnTimeSec, maxPlayers, stakeBronze)
		if locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result(); locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existing := h.findOpenPokerLobbyID(ctx, userID, body.TurnTimeSec, maxPlayers, stakeBronze); existing != "" {
			h.JoinPokerLobby(w, r, existing)
			return
		}
	}

	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	status := lobbyStatusWaitingInvite
	now := time.Now().UTC().Format(time.RFC3339Nano)

	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", pokerGameType,
		"creator_id", userID.String(),
		"status", status,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(body.TurnTimeSec),
		"max_players", strconv.Itoa(maxPlayers),
		"game_mode", "holdem",
		"player_ids", userID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	// Групповой чат для стола на 3+ игроков.
	if maxPlayers > 2 {
		title := pokerGroupChatTitle(maxPlayers)
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{userID}, title, pokerGameType); cerr == nil {
			h.Rdb.HSet(ctx, key, "chat_id", cid.String())
			h.broadcast([]uuid.UUID{userID}, map[string]any{"type": "chat_list_changed"})
		}
	}
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id":   lobbyID,
		"status":     status,
		"created_at": now,
		"creator_id": userID.String(),
		"matched":    false,
	})
}

func pokerGroupChatTitle(n int) string {
	return fmt.Sprintf("Покер на %d", n)
}

// findOpenPokerLobbyID — открытое poker-лобби тех же правил, куда можно войти.
func (h *GamesHandler) findOpenPokerLobbyID(ctx context.Context, excludeUser uuid.UUID, turnTimeSec, maxPlayers, stakeBronze int) string {
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil {
		return ""
	}
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || len(m) == 0 {
			continue
		}
		if m["game_type"] != pokerGameType || m["mode"] != "matchmake" {
			continue
		}
		st := m["status"]
		if st != lobbyStatusWaitingInvite && st != lobbyStatusWaitingMatchmake {
			continue
		}
		if strings.TrimSpace(m["invite_target_id"]) != "" {
			continue
		}
		if m["creator_id"] == excludeUser.String() {
			continue
		}
		if tt, _ := strconv.Atoi(m["turn_time_sec"]); tt != turnTimeSec {
			continue
		}
		if mp, _ := strconv.Atoi(m["max_players"]); mp != maxPlayers {
			continue
		}
		stakes, _ := strconv.Atoi(m["stake_bronze"])
		if stakes < 2 {
			stakes = 2
		}
		if stakes != stakeBronze {
			continue
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) >= maxPlayers {
			continue
		}
		for _, p := range players {
			if p == excludeUser.String() {
				return ""
			}
		}
		return strings.TrimPrefix(key, "lobby:")
	}
	return ""
}

// ---- ListPokerLobbies ----

func (h *GamesHandler) ListPokerLobbies(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	type lobbyOut struct {
		LobbyID     string `json:"lobby_id"`
		CreatorID   string `json:"creator_id"`
		Status      string `json:"status"`
		GameType    string `json:"game_type"`
		MaxPlayers  int    `json:"max_players"`
		TurnTimeSec int    `json:"turn_time_sec"`
		StakeBronze int    `json:"stake_bronze"`
		Players     int    `json:"players_count"`
		CreatedAt   string `json:"created_at"`
	}
	items := make([]lobbyOut, 0, 8)
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, _ := h.Rdb.HGetAll(ctx, key).Result()
		if m["game_type"] != pokerGameType {
			continue
		}
		st := m["status"]
		if st != lobbyStatusWaitingMatchmake && !(st == lobbyStatusWaitingInvite && m["mode"] == "matchmake" && strings.TrimSpace(m["invite_target_id"]) == "") {
			continue
		}
		if m["creator_id"] == userID.String() {
			continue
		}
		maxPlayers, _ := strconv.Atoi(m["max_players"])
		stake, _ := strconv.Atoi(m["stake_bronze"])
		turnT, _ := strconv.Atoi(m["turn_time_sec"])
		if stake < 2 {
			stake = 2
		}
		items = append(items, lobbyOut{
			LobbyID:     strings.TrimPrefix(key, "lobby:"),
			CreatorID:   m["creator_id"],
			Status:      st,
			GameType:    pokerGameType,
			MaxPlayers:  maxPlayers,
			TurnTimeSec: turnT,
			StakeBronze: stake,
			Players:     len(parsePlayerIDsCSV(m["player_ids"])),
			CreatedAt:   m["created_at"],
		})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"lobbies": items})
}

// ---- JoinPokerLobby ----

func (h *GamesHandler) JoinPokerLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
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
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	status := m["status"]
	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusBadRequest, "lobby not joinable")
		return
	}
	if h.prepareJoinLobbySession(ctx, userID, lobbyID) {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}

	players := parsePlayerIDsCSV(m["player_ids"])
	already := false
	for _, p := range players {
		if p == userID.String() {
			already = true
			break
		}
	}
	if !already {
		players = append(players, userID.String())
	}

	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 2 {
		maxPlayers = 2
	}
	if len(players) > maxPlayers {
		WriteErr(w, r, http.StatusConflict, "lobby full")
		return
	}

	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 2 {
		stake = 2
	}
	creatorUUID, _ := uuid.Parse(m["creator_id"])

	if !already && stake > 0 {
		mayStake, e := store.UserMayStake(ctx, h.Pool, userID, stake)
		if e != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if !mayStake {
			WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
			return
		}
		if err := h.checkStakeAffordable(ctx, userID, stake); err != nil {
			if err == store.ErrInsufficientFunds {
				WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
				return
			}
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
	}

	h.Rdb.HSet(ctx, key, "player_ids", strings.Join(players, ","))
	h.Rdb.Expire(ctx, key, lobbyTTL)
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	humanPlayers := make([]uuid.UUID, 0, len(players))
	for _, p := range players {
		if u, err := uuid.Parse(p); err == nil {
			humanPlayers = append(humanPlayers, u)
		}
	}
	h.broadcast(humanPlayers, map[string]any{
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
		title := pokerGroupChatTitle(maxPlayers)
		if _, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, humanPlayers, title, pokerGameType); cerr == nil {
			h.broadcast(humanPlayers, map[string]any{"type": "chat_list_changed"})
		}
	}

	if len(players) == maxPlayers {
		gameID, serr := h.startPokerGameCore(ctx, lobbyID, players, humanPlayers, turnT, stake, maxPlayers)
		if serr != nil {
			h.writePokerStartError(w, r, serr)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"joined":   true,
			"game_id":  gameID,
			"lobby_id": lobbyID,
		})
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"joined":        true,
		"lobby_id":      lobbyID,
		"status":        status,
		"players_count": len(players),
		"max_players":   maxPlayers,
		"waiting_more":  true,
		"already":       already,
		"creator_id":    creatorUUID.String(),
	})
}

func (h *GamesHandler) writePokerStartError(w http.ResponseWriter, r *http.Request, err error) {
	switch err {
	case store.ErrStakeNotAllowed:
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
	case store.ErrInsufficientFunds:
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

// ---- Start ----

// startPokerGameCore создаёт партию из состава playerIDs (люди + боты),
// списывает ставки у людей, публикует game_started и, если ходит бот, запускает его.
func (h *GamesHandler) startPokerGameCore(ctx context.Context, lobbyID string, playerIDs []string, humans []uuid.UUID, turnTimeSec, stakeBronze, maxPlayers int) (string, error) {
	if len(playerIDs) < 2 {
		return "", fmt.Errorf("poker: need at least 2 players")
	}
	if stakeBronze > 0 {
		for _, u := range humans {
			ok, e := store.UserMayStake(ctx, h.Pool, u, stakeBronze)
			if e != nil {
				return "", e
			}
			if !ok {
				return "", store.ErrStakeNotAllowed
			}
			if e := h.checkStakeAffordable(ctx, u, stakeBronze); e != nil {
				return "", e
			}
		}
		if len(humans) > 0 {
			if err := store.DeductCoinsMany(ctx, h.Pool, humans, stakeBronze); err != nil {
				return "", err
			}
		}
	}

	startingChips, smallBlind, bigBlind := pokerChipConfig(stakeBronze)
	rng := rand.New(rand.NewSource(time.Now().UTC().UnixNano()))
	state, err := poker.NewGame(playerIDs, startingChips, smallBlind, bigBlind, rng)
	if err != nil {
		// Возврат ставок, чтобы люди не потеряли монеты при неудачном старте.
		if stakeBronze > 0 {
			for _, u := range humans {
				_ = store.AddCoins(ctx, h.Pool, u, stakeBronze)
			}
		}
		return "", err
	}
	encoded, _ := poker.Encode(state)
	gameID := uuid.New().String()
	gkey := "game:" + gameID
	now := time.Now().UTC().Format(time.RFC3339Nano)

	turnDeadline := int64(0)
	if turnTimeSec > 0 {
		turnDeadline = time.Now().UTC().Unix() + int64(turnTimeSec)
	}
	fields := []any{
		"game_type", pokerGameType,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"max_players", strconv.Itoa(maxPlayers),
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"player_ids", strings.Join(playerIDs, ","),
		"state", encoded,
		"turn_deadline", strconv.FormatInt(turnDeadline, 10),
		"turn_actor_idx", strconv.Itoa(state.ActingIndex),
		"started_at", now,
	}
	if lm, _ := h.Rdb.HGet(ctx, "lobby:"+lobbyID, "chat_id").Result(); lm != "" {
		fields = append(fields, "chat_id", lm)
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gkey, fields...)
	pipe.Expire(ctx, gkey, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"game_type", pokerGameType,
		"player_ids", strings.Join(playerIDs, ","),
	)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	_, _ = pipe.Exec(ctx)

	h.notifyAndClearLobbyInvites(ctx, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)

	for _, u := range humans {
		clearUserActiveLobby(ctx, h.Rdb, u)
		setUserActiveGame(ctx, h.Rdb, u, gameID)
	}
	h.publishGameStartedTyped(humans, gameID, lobbyID, pokerGameType)

	// Первым может ходить бот.
	if isBot(state.Players[state.ActingIndex].UserID) {
		h.schedulePokerBotAct(gameID)
	}
	return gameID, nil
}

// ---- GetPokerGame ----

func (h *GamesHandler) GetPokerGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	h.applyPokerTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()

	state, err := poker.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	// Ход за ботом — подтолкнуть (после рестарта сервера тикер мог не работать).
	if m["status"] == gameStatusActive && state.ActingIndex >= 0 &&
		state.ActingIndex < len(state.Players) && isBot(state.Players[state.ActingIndex].UserID) {
		h.schedulePokerBotAct(gameID)
	}
	view := h.pokerViewFor(ctx, state, userID.String(), m, gameID)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

// ---- PokerMove ----

type pokerMoveBody struct {
	Type   string `json:"type"`   // fold|check|call|raise|all_in
	Amount int    `json:"amount"` // для raise — «поднять до» (raise-to)
}

func (h *GamesHandler) PokerMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body pokerMoveBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	state, err := poker.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	idx := pokerPlayerIndex(state, userID.String())
	if idx < 0 {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	if idx != state.ActingIndex {
		WriteErr(w, r, http.StatusBadRequest, "not your turn")
		return
	}
	action, aerr := pokerParseAction(body)
	if aerr != nil {
		WriteErr(w, r, http.StatusBadRequest, aerr.Error())
		return
	}
	if err := state.Apply(idx, action); err != nil {
		WriteErr(w, r, http.StatusBadRequest, err.Error())
		return
	}
	h.savePokerState(ctx, gameID, m, state)
	h.broadcastPokerState(gameID, m)
	if state.IsOver() || state.HandOver {
		h.onPokerHandOrTableOver(ctx, gameID, m, state, "normal")
	} else if state.ActingIndex >= 0 && state.ActingIndex < len(state.Players) {
		nextID := state.Players[state.ActingIndex].UserID
		if isBot(nextID) {
			h.schedulePokerBotAct(gameID)
		} else {
			h.notifyYourTurnUser(gameID, nextID, pokerGameType)
		}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

func pokerParseAction(body pokerMoveBody) (poker.Action, error) {
	switch poker.ActionType(body.Type) {
	case poker.ActionFold:
		return poker.Action{Type: poker.ActionFold}, nil
	case poker.ActionCheck:
		return poker.Action{Type: poker.ActionCheck}, nil
	case poker.ActionCall:
		return poker.Action{Type: poker.ActionCall}, nil
	case poker.ActionRaise:
		return poker.Action{Type: poker.ActionRaise, Amount: body.Amount}, nil
	case poker.ActionAllIn:
		return poker.Action{Type: poker.ActionAllIn}, nil
	default:
		return poker.Action{}, fmt.Errorf("unknown move type")
	}
}

// ---- Forfeit ----

func (h *GamesHandler) ForfeitPokerGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	state, err := poker.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	idx := pokerPlayerIndex(state, userID.String())
	if idx < 0 {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	// Сдача = выбывание из-за стола: игрок сбрасывает карты и теряет фишки.
	// Если это оставляет фишки лишь у одного — стол закончен (рассчитываем).
	// Иначе стол продолжается без выбывшего.
	state.ForfeitPlayer(idx)
	h.savePokerState(ctx, gameID, m, state)
	// Не ставим глобальный forfeit, если стол продолжается (как в дураке multi) —
	// иначе у оставшихся в конце будет «Соперник сдался».
	if state.TableOver {
		m["forfeit"] = "1"
		h.Rdb.HSet(ctx, "game:"+gameID, "forfeit", "1")
	} else {
		h.Rdb.HDel(ctx, "game:"+gameID, "forfeit")
		delete(m, "forfeit")
	}
	h.broadcastPokerState(gameID, m)
	h.promotePokerEliminatedPlayers(ctx, gameID, m, state)
	if state.TableOver {
		h.onPokerTableFinished(ctx, gameID, m, state, "forfeit")
	} else {
		if state.IsOver() || state.HandOver {
			// Форфейт завершил текущую раздачу — планируем следующую.
			h.schedulePokerNextHand(gameID)
		} else if state.ActingIndex >= 0 && state.ActingIndex < len(state.Players) &&
			isBot(state.Players[state.ActingIndex].UserID) {
			h.schedulePokerBotAct(gameID)
		}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "status": m["status"], "forfeit": true})
}

// ---- Rematch ----

func (h *GamesHandler) PokerRematch(w http.ResponseWriter, r *http.Request) {
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
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	var invitees []string
	for _, pid := range players {
		if pid != userID.String() && !isBot(pid) {
			invitees = append(invitees, pid)
		}
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents")
		return
	}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 2 {
		maxPlayers = 2
	}
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 2 {
		stake = 2
	}

	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", pokerGameType,
		"creator_id", userID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", now,
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnT),
		"max_players", strconv.Itoa(maxPlayers),
		"game_mode", "holdem",
		"player_ids", userID.String(),
		"stake_bronze", strconv.Itoa(stake),
		"invite_target_id", invitees[0],
	)
	pipe.Expire(ctx, key, lobbyTTL)
	invitedKey := key + ":invited"
	for _, iv := range invitees {
		pipe.SAdd(ctx, invitedKey, iv)
	}
	pipe.Expire(ctx, invitedKey, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	h.trackUserInvites(ctx, lobbyID, invitees)
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	inviteeUUIDs := make([]uuid.UUID, 0, len(invitees))
	for _, iv := range invitees {
		if u, err := uuid.Parse(iv); err == nil {
			inviteeUUIDs = append(inviteeUUIDs, u)
		}
	}
	creator, _ := store.GetUserByID(ctx, h.Pool, userID)
	creatorName := "Игрок"
	creatorAvatarKind := ""
	creatorAvatarValue := ""
	if creator != nil {
		if creator.DisplayName != nil && *creator.DisplayName != "" {
			creatorName = *creator.DisplayName
		}
		if creator.AvatarKind != "" {
			creatorAvatarKind = creator.AvatarKind
		}
		if creator.AvatarValue != nil && *creator.AvatarValue != "" {
			creatorAvatarValue = *creator.AvatarValue
		}
	}
	invite := map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    userID.String(),
		"creator_name":  creatorName,
		"game_type":     pokerGameType,
		"turn_time_sec": turnT,
		"max_players":   maxPlayers,
		"stake_bronze":  stake,
	}
	if creatorAvatarKind != "" {
		invite["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		invite["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast(inviteeUUIDs, invite)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

// ---- Persistence / broadcast ----

func (h *GamesHandler) savePokerState(ctx context.Context, gameID string, m map[string]string, state *poker.Game) {
	encoded, err := poker.Encode(state)
	if err != nil {
		return
	}
	fields := []any{"state", encoded}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	// Redis status=over только когда весь стол окончен. Между раздачами (HandOver)
	// оставляем active — иначе GetActive сбрасывает active_game и клиенты «теряют» стол.
	if state.TableOver {
		fields = append(fields, "status", pokerStatusOver, "turn_deadline", "0", "turn_actor_idx", "-1")
		m["status"] = pokerStatusOver
		m["turn_deadline"] = "0"
		m["turn_actor_idx"] = "-1"
	} else {
		fields = append(fields, "status", gameStatusActive)
		m["status"] = gameStatusActive
		if state.HandOver || state.ActingIndex < 0 {
			fields = append(fields, "turn_deadline", "0", "turn_actor_idx", "-1")
			m["turn_deadline"] = "0"
			m["turn_actor_idx"] = "-1"
		} else if turnT > 0 {
			dl := time.Now().UTC().Unix() + int64(turnT)
			fields = append(fields,
				"turn_deadline", strconv.FormatInt(dl, 10),
				"turn_actor_idx", strconv.Itoa(state.ActingIndex),
			)
			m["turn_deadline"] = strconv.FormatInt(dl, 10)
			m["turn_actor_idx"] = strconv.Itoa(state.ActingIndex)
		} else {
			fields = append(fields,
				"turn_deadline", "0",
				"turn_actor_idx", strconv.Itoa(state.ActingIndex),
			)
			m["turn_deadline"] = "0"
			m["turn_actor_idx"] = strconv.Itoa(state.ActingIndex)
		}
	}
	m["state"] = encoded
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
}

func (h *GamesHandler) broadcastPokerState(gameID string, m map[string]string) {
	if m == nil {
		return
	}
	ctx := context.Background()
	if h.Rdb != nil {
		if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
			m = fresh
		}
	}
	state, err := poker.Decode(m["state"])
	if err != nil || state == nil {
		h.broadcast(pokerHumans(m), map[string]any{
			"type":      "game_state",
			"game_id":   gameID,
			"game_type": pokerGameType,
		})
		return
	}
	for _, u := range pokerHumans(m) {
		view := h.pokerViewFor(ctx, state, u.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{u}, view)
	}
}

// ---- Bot ----

// schedulePokerBotAct — через ~700 мс ходит бот; несколько ботов подряд — в цикле.
// Сериализуется Redis-локом, чтобы не было двойных ходов.
func (h *GamesHandler) schedulePokerBotAct(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		for {
			time.Sleep(pokerBotDelay)
			ctx := context.Background()
			lockKey := "poker_bot_lock:" + gameID
			locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result()
			if !locked {
				return
			}
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["status"] != gameStatusActive {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			state, err := poker.Decode(m["state"])
			if err != nil || state.ActingIndex < 0 || state.ActingIndex >= len(state.Players) {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			acting := state.Players[state.ActingIndex]
			if !isBot(acting.UserID) {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			action := pokerBotAction(state)
			if err := state.Apply(state.ActingIndex, action); err != nil {
				// Фолбэк: если ход невалиден — фолд.
				_ = state.Apply(state.ActingIndex, poker.Action{Type: poker.ActionFold})
			}
			h.savePokerState(ctx, gameID, m, state)
			h.broadcastPokerState(gameID, m)
			over := state.IsOver() || state.HandOver
			if over {
				h.onPokerHandOrTableOver(ctx, gameID, m, state, "normal")
			}
			h.Rdb.Del(ctx, lockKey)
			if over {
				return
			}
			if state.ActingIndex < 0 || state.ActingIndex >= len(state.Players) {
				return
			}
			nextID := state.Players[state.ActingIndex].UserID
			if !isBot(nextID) {
				h.notifyYourTurnUser(gameID, nextID, pokerGameType)
				return
			}
			// Следующий тоже бот — продолжаем цикл (с новой паузой).
		}
	}()
}

// pokerBotAction — простая стратегия: чек, иначе колл если дёшево, иногда мин-рейз, иначе фолд.
func pokerBotAction(state *poker.Game) poker.Action {
	idx := state.ActingIndex
	legal := state.LegalActions(idx)
	has := func(a string) bool {
		for _, x := range legal {
			if x == a {
				return true
			}
		}
		return false
	}
	p := state.Players[idx]
	callAmount := state.CurrentBet - p.Bet
	if callAmount < 0 {
		callAmount = 0
	}
	if has(string(poker.ActionCheck)) {
		// Иногда мин-рейз при наличии фишек.
		if has(string(poker.ActionRaise)) && p.Chips > state.BigBlind*2 && rand.Intn(4) == 0 {
			to := state.CurrentBet + state.MinRaise
			if to <= p.Bet+p.Chips {
				return poker.Action{Type: poker.ActionRaise, Amount: to}
			}
		}
		return poker.Action{Type: poker.ActionCheck}
	}
	if has(string(poker.ActionCall)) && callAmount <= p.Chips/3 {
		// Изредка отвечаем рейзом.
		if has(string(poker.ActionRaise)) && p.Chips > state.BigBlind*4 && rand.Intn(6) == 0 {
			to := state.CurrentBet + state.MinRaise
			if to <= p.Bet+p.Chips {
				return poker.Action{Type: poker.ActionRaise, Amount: to}
			}
		}
		return poker.Action{Type: poker.ActionCall}
	}
	if has(string(poker.ActionCheck)) {
		return poker.Action{Type: poker.ActionCheck}
	}
	return poker.Action{Type: poker.ActionFold}
}

// ---- Timeout ----

// applyPokerTurnTimeout — если истёк ход, действующий игрок проигрывает стол
// (как сдача), а не просто сбрасывает карты в текущей раздаче.
func (h *GamesHandler) applyPokerTurnTimeout(ctx context.Context, gameID string, m map[string]string) {
	if m["status"] != gameStatusActive {
		return
	}
	turnDeadline, err := strconv.ParseInt(m["turn_deadline"], 10, 64)
	if err != nil || turnDeadline <= 0 {
		return
	}
	if time.Now().UTC().Unix() < turnDeadline {
		return
	}
	// Перечитать — ход мог обновить дедлайн на последней секунде.
	fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(fresh) == 0 || fresh["status"] != gameStatusActive {
		return
	}
	freshDL, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDL != turnDeadline || time.Now().UTC().Unix() < freshDL {
		return
	}
	state, err := poker.Decode(fresh["state"])
	if err != nil || state.Status != poker.StatusActive {
		return
	}
	idx := state.ActingIndex
	if idx < 0 || idx >= len(state.Players) {
		return
	}
	state.ForfeitPlayer(idx)
	h.savePokerState(ctx, gameID, fresh, state)
	fresh["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "timeout", "1")
	h.broadcastPokerState(gameID, fresh)
	h.promotePokerEliminatedPlayers(ctx, gameID, fresh, state)
	if state.TableOver {
		h.onPokerTableFinished(ctx, gameID, fresh, state, "timeout")
	} else if state.IsOver() || state.HandOver {
		h.schedulePokerNextHand(gameID)
	} else if state.ActingIndex >= 0 && state.ActingIndex < len(state.Players) {
		nextID := state.Players[state.ActingIndex].UserID
		if isBot(nextID) {
			h.schedulePokerBotAct(gameID)
		} else {
			h.notifyYourTurnUser(gameID, nextID, pokerGameType)
		}
	}
	// Обновить снимок для вызывающего.
	for k, v := range fresh {
		m[k] = v
	}
	if nm, e := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); e == nil {
		for k, v := range nm {
			m[k] = v
		}
	}
}

// ---- Finish / settlement ----

// onPokerHandOrTableOver вызывается, когда текущая раздача завершилась. Если весь
// стол окончен (фишки у одного игрока) — рассчитываем монеты и закрываем лобби.
// Иначе — раздача просто закончилась: сохраняем результат и через паузу стартуем
// следующую раздачу тем же составом.
func (h *GamesHandler) onPokerHandOrTableOver(ctx context.Context, gameID string, m map[string]string, state *poker.Game, finishReason string) {
	h.promotePokerEliminatedPlayers(ctx, gameID, m, state)
	if state.TableOver {
		h.onPokerTableFinished(ctx, gameID, m, state, finishReason)
		return
	}
	h.onPokerHandFinished(gameID)
}

// promotePokerEliminatedPlayers — выбывший (0 фишек) → observation; ранняя выплата доли места.
func (h *GamesHandler) promotePokerEliminatedPlayers(ctx context.Context, gameID string, m map[string]string, state *poker.Game) {
	if state == nil || h.Rdb == nil {
		return
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	n := len(state.Players)
	for i := range state.Players {
		if !state.IsEliminated(i) {
			continue
		}
		pid := state.Players[i].UserID
		if isBot(pid) {
			continue
		}
		u, err := uuid.Parse(pid)
		if err != nil {
			continue
		}
		// Стол ещё идёт — active → observation (как дурак).
		if !state.TableOver {
			moveActiveToObserving(ctx, h.Rdb, u, gameID)
		}
		if state.TableOver || stakeBronze <= 0 || h.Pool == nil {
			continue
		}
		place := state.PlaceOf(pid)
		if place < 1 {
			continue
		}
		credit := poker.PlaceCredit(stakeBronze, n, place)
		ok, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "early_paid:"+pid, strconv.Itoa(credit)).Result()
		if err != nil || !ok {
			continue
		}
		if credit <= 0 {
			continue
		}
		if err := store.AddCoins(ctx, h.Pool, u, credit); err != nil {
			h.Rdb.HDel(ctx, "game:"+gameID, "early_paid:"+pid)
		}
	}
}

func (h *GamesHandler) pokerEarlyPaid(ctx context.Context, gameID, playerID string) int {
	if h.Rdb == nil || playerID == "" {
		return 0
	}
	v, err := h.Rdb.HGet(ctx, "game:"+gameID, "early_paid:"+playerID).Int()
	if err != nil || v < 0 {
		return 0
	}
	return v
}

func (h *GamesHandler) pokerPayCreditDelta(ctx context.Context, gameID, playerID string, credit int) {
	if credit <= 0 || isBot(playerID) || h.Pool == nil {
		return
	}
	u, err := uuid.Parse(playerID)
	if err != nil {
		return
	}
	delta := credit - h.pokerEarlyPaid(ctx, gameID, playerID)
	if delta <= 0 {
		return
	}
	_ = store.AddCoins(ctx, h.Pool, u, delta)
}

// onPokerHandFinished — раздача завершена, но стол продолжается: планируем старт
// следующей раздачи. Состояние и трансляция уже сохранены вызывающим.
func (h *GamesHandler) onPokerHandFinished(gameID string) {
	h.schedulePokerNextHand(gameID)
}

// PokerShowCards — добровольно показать карты после фолд-вины (пауза перед следующей раздачей).
func (h *GamesHandler) PokerShowCards(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != pokerGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	state, err := poker.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	idx := pokerPlayerIndex(state, userID.String())
	if idx < 0 {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	if err := state.ShowCards(idx); err != nil {
		WriteErr(w, r, http.StatusBadRequest, err.Error())
		return
	}
	h.savePokerState(ctx, gameID, m, state)
	h.broadcastPokerState(gameID, m)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

// schedulePokerNextHand через ~4 с стартует следующую раздачу за столом.
// Сериализуется Redis-локом, чтобы не запустить раздачу дважды.
func (h *GamesHandler) schedulePokerNextHand(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		time.Sleep(pokerNextHandDelay)
		ctx := context.Background()
		lockKey := "poker_next_hand_lock:" + gameID
		locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 10*time.Second).Result()
		if !locked {
			return
		}
		defer h.Rdb.Del(ctx, lockKey)

		m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		if err != nil || len(m) == 0 || m["game_type"] != pokerGameType {
			return
		}
		state, err := poker.Decode(m["state"])
		if err != nil || !state.HandOver || state.TableOver {
			return
		}
		rng := rand.New(rand.NewSource(time.Now().UTC().UnixNano()))
		if err := state.StartNextHand(rng); err != nil {
			return
		}
		// Сбрасываем флаги прошлой раздачи.
		h.Rdb.HDel(ctx, "game:"+gameID, "forfeit", "timeout")
		delete(m, "forfeit")
		delete(m, "timeout")
		h.savePokerState(ctx, gameID, m, state)
		// Active только у игроков с фишками; выбывшие остаются в observation.
		for i := range state.Players {
			pid := state.Players[i].UserID
			if isBot(pid) || state.Players[i].Chips <= 0 {
				continue
			}
			if u, err := uuid.Parse(pid); err == nil {
				setUserActiveGame(ctx, h.Rdb, u, gameID)
			}
		}
		h.broadcastPokerState(gameID, m)
		if state.ActingIndex >= 0 && state.ActingIndex < len(state.Players) {
			nextID := state.Players[state.ActingIndex].UserID
			if isBot(nextID) {
				h.schedulePokerBotAct(gameID)
			} else {
				h.notifyYourTurnUser(gameID, nextID, pokerGameType)
			}
		}
	}()
}

func (h *GamesHandler) onPokerTableFinished(ctx context.Context, gameID string, m map[string]string, state *poker.Game, finishReason string) {
	humans := pokerHumans(m)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)

	lobbyID := strings.TrimSpace(m["lobby_id"])
	if lobbyID != "" {
		h.Rdb.Del(ctx, "lobby:"+lobbyID)
		h.Rdb.Del(ctx, "lobby:"+lobbyID+":invited")
		if strings.TrimSpace(m["chat_id"]) != "" {
			_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
			h.broadcast(humans, map[string]any{
				"type":     "lobby_updated",
				"lobby_id": lobbyID,
				"closed":   true,
			})
			h.broadcast(humans, map[string]any{"type": "chat_list_changed"})
		}
	}

	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	h.settlePokerCoins(ctx, gameID, m, state, stakeBronze)

	for _, uid := range humans {
		_ = store.IncrementGamesFinished(ctx, h.Pool, uid)
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, uid)
		notifyAchievementUnlocks(h.Hub, h.Push, uid, unlocked)
	}
	for _, wid := range state.WinnerUserIDs {
		if isBot(wid) {
			continue
		}
		if u, err := uuid.Parse(wid); err == nil {
			_ = store.IncrementWinsByStake(ctx, h.Pool, u, stakeBronze)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
			notifyAchievementUnlocks(h.Hub, h.Push, u, unlocked)
		}
	}
	h.recordPokerGameResult(ctx, gameID, m, state, stakeBronze, finishReason)
}

// settlePokerCoins — банк stake×N по местам (см. poker.PlaceCredit); учитывает early_paid.
func (h *GamesHandler) settlePokerCoins(ctx context.Context, gameID string, m map[string]string, state *poker.Game, stakeBronze int) {
	if stakeBronze <= 0 || h.Pool == nil || h.Rdb == nil {
		return
	}
	ok, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "coins_settled", "1").Result()
	if err != nil || !ok {
		return
	}
	n := len(state.Players)
	if n < 2 {
		return
	}
	places := state.FinishPlaces()
	if len(places) == 0 {
		// Fallback: старое поведение — банк победителям поровну.
		winners := state.WinnerUserIDs
		if len(winners) == 0 {
			return
		}
		pot := stakeBronze * n
		each := pot / len(winners)
		rem := pot % len(winners)
		for i, wid := range winners {
			credit := each
			if i == 0 {
				credit += rem
			}
			h.pokerPayCreditDelta(ctx, gameID, wid, credit)
		}
		return
	}
	for pid, place := range places {
		credit := poker.PlaceCredit(stakeBronze, n, place)
		h.pokerPayCreditDelta(ctx, gameID, pid, credit)
	}
}

// recordPokerGameResult — статистика: 1×1 как раньше; multi — победитель vs каждый человек.
func (h *GamesHandler) recordPokerGameResult(ctx context.Context, gameID string, m map[string]string, state *poker.Game, stakeBronze int, finishReason string) {
	if len(state.Players) < 2 {
		return
	}
	var durationSec int
	if t, ok := parseGameStartedAt(m["started_at"]); ok {
		durationSec = clampNonNegative(int(time.Since(t).Seconds()))
	}

	humans := make([]string, 0, len(state.Players))
	for i := range state.Players {
		pid := state.Players[i].UserID
		if !isBot(pid) {
			humans = append(humans, pid)
		}
	}
	if len(humans) == 0 {
		return
	}

	var tableWinner string
	for _, wid := range state.WinnerUserIDs {
		if wid != "" {
			tableWinner = wid
			break
		}
	}
	if tableWinner == "" {
		places := state.FinishPlaces()
		for pid, place := range places {
			if place == 1 {
				tableWinner = pid
				break
			}
		}
	}

	recordPair := func(rowGameID, xID, oID, winnerID string) {
		result := "draw"
		switch {
		case winnerID == xID && winnerID != "":
			result = "x_won"
		case winnerID == oID && winnerID != "":
			result = "o_won"
		}
		gr := store.GameResult{
			GameID:       rowGameID,
			GameType:     pokerGameType,
			Result:       result,
			FinishReason: finishReason,
			StakeBronze:  stakeBronze,
			AgainstBot:   isBot(xID) || isBot(oID),
			DurationSec:  durationSec,
		}
		if u, err := uuid.Parse(xID); err == nil {
			gr.XUserID = u
		}
		if u, err := uuid.Parse(oID); err == nil {
			gr.OUserID = u
		}
		if winnerID != "" && !isBot(winnerID) {
			if wu, err := uuid.Parse(winnerID); err == nil {
				gr.WinnerUserID = &wu
			}
		}
		_ = store.RecordGameResult(ctx, h.Pool, gr)
	}

	if len(state.Players) == 2 {
		xID, oID := state.Players[0].UserID, state.Players[1].UserID
		winnerID := ""
		if tableWinner == xID || tableWinner == oID {
			winnerID = tableWinner
		}
		recordPair(gameID, xID, oID, winnerID)
		return
	}

	// Multi: H2H победителя с каждым другим человеком (и с ботом — against_bot).
	if tableWinner == "" {
		return
	}
	for i := range state.Players {
		oid := state.Players[i].UserID
		if oid == "" || oid == tableWinner {
			continue
		}
		rowID := gameID + ":" + oid
		recordPair(rowID, tableWinner, oid, tableWinner)
	}
}

// ---- View ----

func pokerHumans(m map[string]string) []uuid.UUID {
	ids := parsePlayerIDsCSV(m["player_ids"])
	out := make([]uuid.UUID, 0, len(ids))
	for _, s := range ids {
		if isBot(s) {
			continue
		}
		u, err := uuid.Parse(s)
		if err != nil {
			continue
		}
		out = append(out, u)
	}
	return out
}

func pokerPlayerIndex(state *poker.Game, userID string) int {
	for i := range state.Players {
		if state.Players[i].UserID == userID {
			return i
		}
	}
	return -1
}

func (h *GamesHandler) pokerViewFor(ctx context.Context, state *poker.Game, viewer string, m map[string]string, gameID string) map[string]any {
	myIdx := pokerPlayerIndex(state, viewer)
	isHandOver := state.HandOver || state.IsOver()
	isTableOver := state.TableOver
	// is_over для клиента = вся партия окончена (показать rematch/итоги).
	isOver := isTableOver
	// Contested showdown — карты всем; фолд-вина — только если победитель нажал «Показать».
	autoReveal := state.Street == poker.StreetShowdown

	playerIDs := make([]string, len(state.Players))
	for i := range state.Players {
		playerIDs[i] = state.Players[i].UserID
	}

	// Метаданные людей (имя/аватар/рамка).
	names := map[string]*store.User{}
	frameIDs := make([]uuid.UUID, 0, len(state.Players))
	for _, pid := range playerIDs {
		if isBot(pid) {
			continue
		}
		if u, err := uuid.Parse(pid); err == nil {
			if usr, e := store.GetUserByID(ctx, h.Pool, u); e == nil && usr != nil {
				names[pid] = usr
			}
			frameIDs = append(frameIDs, u)
		}
	}
	frames, _ := store.EquippedFramesMap(ctx, h.Pool, frameIDs)

	players := make([]map[string]any, len(state.Players))
	for i := range state.Players {
		p := state.Players[i]
		entry := map[string]any{
			"id":        p.UserID,
			"seat":      p.Seat,
			"chips":     p.Chips,
			"bet":       p.Bet,
			"folded":    p.Folded,
			"all_in":    p.AllIn,
			"shown":     p.Shown,
			"is_acting": state.Status == poker.StatusActive && i == state.ActingIndex,
		}
		if isBot(p.UserID) {
			entry["display_name"] = "Бот"
		} else if usr, ok := names[p.UserID]; ok && usr != nil {
			if usr.DisplayName != nil && *usr.DisplayName != "" {
				entry["display_name"] = *usr.DisplayName
			}
			if usr.AvatarKind != "" {
				entry["avatar_kind"] = usr.AvatarKind
			}
			if usr.AvatarValue != nil {
				entry["avatar_value"] = *usr.AvatarValue
			}
			if u, err := uuid.Parse(p.UserID); err == nil {
				if f, ok := frames[u]; ok {
					entry["frame_code"] = f.Code
					entry["frame_color"] = f.Color
				}
			}
		}
		// Карманные карты: свои всегда; чужие — на showdown или если добровольно показаны.
		if i == myIdx || (!p.Folded && (autoReveal || p.Shown)) {
			entry["hole_cards"] = []poker.Card{p.Hole[0], p.Hole[1]}
		}
		players[i] = entry
	}

	legal := []string{}
	callAmount := 0
	minRaiseTo := 0
	maxRaiseTo := 0
	if myIdx >= 0 {
		legal = state.LegalActions(myIdx)
		mp := state.Players[myIdx]
		callAmount = state.CurrentBet - mp.Bet
		if callAmount < 0 {
			callAmount = 0
		}
		if callAmount > mp.Chips {
			callAmount = mp.Chips
		}
		maxRaiseTo = mp.Bet + mp.Chips
		minRaiseTo = state.CurrentBet + state.MinRaise
		if minRaiseTo > maxRaiseTo {
			minRaiseTo = maxRaiseTo
		}
	}

	turnDeadline := int64(0)
	if v, err := strconv.ParseInt(m["turn_deadline"], 10, 64); err == nil {
		turnDeadline = v
	}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])

	// status — «сырой» статус движка (раздача active/over), не путать с is_over
	// (весь стол). Между раздачами статус будет over на время паузы.
	status := m["status"]
	if state.Status == poker.StatusOver {
		status = pokerStatusOver
	}

	// Инфо о комбинации зрителя (для подсветки и подписи ранга).
	var myHandRank string
	var myHandCards []poker.Card
	if myIdx >= 0 {
		if hv, err := state.BestHandFor(myIdx); err == nil {
			myHandRank = hv.Rank.String()
			myHandCards = hv.Cards
		}
	}

	// На вскрытии — лучшие комбинации победителей (ранг + 5 карт) для UI.
	winnerHands := make([]map[string]any, 0, len(state.Winners))
	if isHandOver {
		for _, wseat := range state.Winners {
			if wseat < 0 || wseat >= len(state.Players) {
				continue
			}
			wh := map[string]any{"seat": state.Players[wseat].Seat}
			if hv, err := state.BestHandFor(wseat); err == nil {
				wh["rank"] = hv.Rank.String()
				wh["cards"] = hv.Cards
			}
			winnerHands = append(winnerHands, wh)
		}
	}

	winners := state.Winners
	if winners == nil {
		winners = []int{}
	}
	winnerIDs := state.WinnerUserIDs
	if winnerIDs == nil {
		winnerIDs = []string{}
	}
	elimOrder := state.EliminatedOrder
	if elimOrder == nil {
		elimOrder = []string{}
	}
	myPlace := 0
	iAmEliminated := false
	if myIdx >= 0 {
		myPlace = state.PlaceOf(viewer)
		iAmEliminated = state.IsEliminated(myIdx) && !isTableOver
	}

	return map[string]any{
		"id":           gameID,
		"game_type":    pokerGameType,
		"status":       status,
		"street":       state.Street,
		"lobby_id":     m["lobby_id"],
		"chat_id":      m["chat_id"],
		"player_ids":   playerIDs,
		"players":      players,
		"community":    state.Community,
		"pot":          state.Pot,
		"current_bet":  state.CurrentBet,
		"min_raise":    state.MinRaise,
		"small_blind":  state.SmallBlind,
		"big_blind":    state.BigBlind,
		"dealer_index": state.DealerIndex,
		"acting_index": state.ActingIndex,
		"my_index":     myIdx,
		"is_my_turn": myIdx >= 0 &&
			!isTableOver &&
			!state.HandOver &&
			!iAmEliminated &&
			state.Status == poker.StatusActive &&
			myIdx == state.ActingIndex,
		"legal_actions": legal,
		"call_amount":   callAmount,
		"min_raise_to":  minRaiseTo,
		"max_raise_to":  maxRaiseTo,
		"turn_time_sec": turnT,
		"turn_deadline": turnDeadline,
		"stake_bronze":  stakeBronze,
		"winners":       winners,
		"winner_ids":    winnerIDs,
		"is_over":       isOver,
		"is_forfeit":    m["forfeit"] == "1",
		"is_timeout":    m["timeout"] == "1",
		// Кэш-стол: прогресс партии и уровни блайндов.
		"hand_number":     state.HandNumber,
		"blind_level":     state.BlindLevel,
		"hands_per_level": state.HandsPerLevel,
		"is_hand_over":    isHandOver,
		"is_table_over":   isTableOver,
		"can_show_cards":  myIdx >= 0 && !iAmEliminated && state.CanShowCards(myIdx),
		// Места / выбывание (как дурак).
		"my_place":         myPlace,
		"i_am_eliminated":  iAmEliminated,
		"eliminated_order": elimOrder,
		// Подсказки по комбинациям для UI.
		"my_hand_rank":      myHandRank,
		"my_hand_cards":     myHandCards,
		"highlighted_cards": myHandCards,
		"winner_hands":      winnerHands,
	}
}
