package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/durak"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

const (
	durakGameType   = "durak"
	durakBotID      = "bot:durak"
	durakStatusOver = "over"
)

// validDurakDeckSize — допустимые размеры колоды.
var validDurakDeckSize = map[int]bool{24: true, 36: true, 52: true}

// serveDurak — dispatcher для `/api/games/durak/*`.
func (h *GamesHandler) serveDurak(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/games/durak/")
	parts := strings.Split(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreateDurakLobby(w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListDurakLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.DurakRematch(w, r)
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
			h.JoinDurakLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
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
			h.GetDurakGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
			h.DurakMove(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.ForfeitDurakGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw-offer" && r.Method == http.MethodPost:
			h.DurakOfferDraw(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw-accept" && r.Method == http.MethodPost:
			h.DurakAcceptDraw(w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

// ---- Lobby: CreateDurakLobby ----

type createDurakLobbyBody struct {
	Mode        string `json:"mode"`         // "invite" | "matchmake"
	MaxPlayers  int    `json:"max_players"`  // 2..4
	DeckSize    int    `json:"deck_size"`    // 24/36/52
	GameMode    string `json:"game_mode"`    // "podkidnoi" | "perevodnoi"
	TurnTimeSec int    `json:"turn_time_sec"`
	StakeBronze int    `json:"stake_bronze"`
}

func (h *GamesHandler) CreateDurakLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body createDurakLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()

	// Уже в живой партии — нельзя создавать другую.
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}

	mode := body.Mode
	if mode != "invite" && mode != "matchmake" {
		mode = "invite"
	}
	maxPlayers := body.MaxPlayers
	if maxPlayers < 2 || maxPlayers > 4 {
		maxPlayers = 2
	}
	deckSize := body.DeckSize
	if !validDurakDeckSize[deckSize] {
		deckSize = 36
	}
	if deckSize == 24 && maxPlayers > 2 {
		WriteErr(w, r, http.StatusBadRequest, "deck 24 supports only 2 players")
		return
	}
	if !validTurnTimeSec[body.TurnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	gameMode := string(durak.ParseMode(body.GameMode))
	stakeBronze := body.StakeBronze
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	// Достаточность баланса.
	if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		return
	}

	// «Найти игру»: сначала пробуем схлопнуться с уже открытым лобби тех же
	// правил (как multi-поиск в крестиках-ноликах), и только если такого нет —
	// создаём своё. Иначе два игрока с одинаковыми настройками не находят
	// друг друга.
	if mode == "matchmake" {
		lockKey := fmt.Sprintf("durak_open_lock:%d:%d:%s:%d:%d",
			body.TurnTimeSec, deckSize, gameMode, maxPlayers, stakeBronze)
		if locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result(); locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existing := h.findOpenDurakLobbyID(
			ctx, userID, body.TurnTimeSec, deckSize, gameMode, maxPlayers, stakeBronze,
		); existing != "" {
			if h.mergeIntoOpenDurakLobby(w, r, ctx, userID, existing) {
				return
			}
			// Лобби успели закрыть — создаём новое ниже.
		}
	}

	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	// Открытый поиск живёт как waiting_invite + mode=matchmake — так же,
	// как multi «Найти игру» в крестиках: тогда ListLobbies его видит,
	// а друга можно пригласить прямо из поиска.
	status := lobbyStatusWaitingInvite
	now := time.Now().UTC().Format(time.RFC3339Nano)

	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", durakGameType,
		"creator_id", userID.String(),
		"status", status,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(body.TurnTimeSec),
		"max_players", strconv.Itoa(maxPlayers),
		"deck_size", strconv.Itoa(deckSize),
		"game_mode", gameMode,
		"player_ids", userID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	// Групповой чат для 3-4 игроков.
	if maxPlayers > 2 {
		title := durakGroupChatTitle(maxPlayers)
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{userID}, title, durakGameType); cerr == nil {
			h.Rdb.HSet(ctx, key, "chat_id", cid.String())
			h.broadcast([]uuid.UUID{userID}, map[string]any{"type": "chat_list_changed"})
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id":   lobbyID,
		"status":     status,
		"created_at": now,
		"creator_id": userID.String(),
	})
}

// findOpenDurakLobbyID — открытое durak-лобби тех же правил, куда можно войти.
func (h *GamesHandler) findOpenDurakLobbyID(
	ctx context.Context,
	excludeUser uuid.UUID,
	turnTimeSec, deckSize int,
	gameMode string,
	maxPlayers, stakeBronze int,
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
		if err != nil || len(m) == 0 {
			continue
		}
		if m["game_type"] != durakGameType || m["mode"] != "matchmake" {
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
		if ds, _ := strconv.Atoi(m["deck_size"]); ds != deckSize {
			continue
		}
		if strings.TrimSpace(m["game_mode"]) != gameMode {
			continue
		}
		if mp, _ := strconv.Atoi(m["max_players"]); mp != maxPlayers {
			continue
		}
		stakes, _ := strconv.Atoi(m["stake_bronze"])
		if stakes < 1 {
			stakes = 1
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

// mergeIntoOpenDurakLobby — вход в найденное открытое лобби. true, если ответ уже записан.
func (h *GamesHandler) mergeIntoOpenDurakLobby(
	w http.ResponseWriter,
	r *http.Request,
	ctx context.Context,
	userID uuid.UUID,
	lobbyID string,
) bool {
	m, err := h.Rdb.HGetAll(ctx, "lobby:"+lobbyID).Result()
	if err != nil || len(m) == 0 {
		return false
	}
	h.JoinDurakLobby(w, r, lobbyID)
	return true
}

func durakGroupChatTitle(n int) string {
	switch n {
	case 3:
		return "Дурак на троих"
	case 4:
		return "Дурак на четверых"
	default:
		return "Дурак"
	}
}

// checkStakeAffordable — сколько бронзы у пользователя (используем существующую логику,
// если она есть; здесь — упрощённо, никак не проверяем).
func (h *GamesHandler) checkStakeAffordable(ctx context.Context, userID uuid.UUID, stakeBronze int) error {
	return nil
}

// ---- ListDurakLobbies ----

func (h *GamesHandler) ListDurakLobbies(w http.ResponseWriter, r *http.Request) {
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
		MaxPlayers  int    `json:"max_players"`
		DeckSize    int    `json:"deck_size"`
		GameMode    string `json:"game_mode"`
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
		if m["game_type"] != durakGameType {
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
		deckSize, _ := strconv.Atoi(m["deck_size"])
		stake, _ := strconv.Atoi(m["stake_bronze"])
		turnT, _ := strconv.Atoi(m["turn_time_sec"])
		playerIDs := parsePlayerIDsCSV(m["player_ids"])
		items = append(items, lobbyOut{
			LobbyID:     strings.TrimPrefix(key, "lobby:"),
			CreatorID:   m["creator_id"],
			Status:      st,
			MaxPlayers:  maxPlayers,
			DeckSize:    deckSize,
			GameMode:    m["game_mode"],
			TurnTimeSec: turnT,
			StakeBronze: stake,
			Players:     len(playerIDs),
			CreatedAt:   m["created_at"],
		})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"lobbies": items})
}

// ---- JoinDurakLobby ----

func (h *GamesHandler) JoinDurakLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	status := m["status"]
	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		WriteErr(w, r, http.StatusBadRequest, "lobby not joinable")
		return
	}
	// Уже в другой активной партии / лобби.
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	if lid, lerr := h.Rdb.Get(ctx, userActiveLobbyKey(userID)).Result(); lerr == nil && lid != "" && lid != lobbyID {
		if lm, _ := h.Rdb.HGetAll(ctx, "lobby:"+lid).Result(); len(lm) > 0 {
			st := lm["status"]
			if st == lobbyStatusWaitingInvite || st == lobbyStatusWaitingMatchmake {
				WriteErr(w, r, http.StatusConflict, "finish your current game first")
				return
			}
		}
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
	// Слишком много игроков — уже стартовало.
	if len(players) > maxPlayers {
		WriteErr(w, r, http.StatusConflict, "lobby full")
		return
	}

	deckSize, _ := strconv.Atoi(m["deck_size"])
	gameMode := m["game_mode"]
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 1 {
		stake = 1
	}
	creatorUUID, _ := uuid.Parse(m["creator_id"])

	// Обновить состав лобби.
	h.Rdb.HSet(ctx, key, "player_ids", strings.Join(players, ","))
	h.Rdb.Expire(ctx, key, lobbyTTL)
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	// Broadcast: обновление состава.
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

	// Групповой чат для 3-4.
	if maxPlayers > 2 {
		title := durakGroupChatTitle(maxPlayers)
		if _, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, humanPlayers, title, durakGameType); cerr == nil {
			h.broadcast(humanPlayers, map[string]any{"type": "chat_list_changed"})
		}
	}

	// Все собрались — стартуем.
	if len(players) == maxPlayers {
		h.startDurakGame(ctx, w, r, lobbyID, humanPlayers, deckSize, gameMode, turnT, stake, maxPlayers)
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

// startDurakGame — создать игру, отправить `game_started` всем участникам.
func (h *GamesHandler) startDurakGame(ctx context.Context, w http.ResponseWriter, r *http.Request, lobbyID string, players []uuid.UUID, deckSize int, gameMode string, turnTimeSec, stakeBronze, maxPlayers int) {
	ids := make([]string, 0, len(players))
	for _, u := range players {
		ids = append(ids, u.String())
	}
	state, err := durak.New(ids, deckSize, durak.ParseMode(gameMode), time.Now().UTC().UnixNano())
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, err.Error())
		return
	}
	encoded, _ := durak.Encode(state)
	gameID := uuid.New().String()
	gkey := "game:" + gameID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	fields := []any{
		"game_type", durakGameType,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"mode", string(state.Mode),
		"deck_size", strconv.Itoa(deckSize),
		"max_players", strconv.Itoa(maxPlayers),
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"player_ids", strings.Join(ids, ","),
		"state", encoded,
		"started_at", now,
	}
	// chat_id если был в лобби.
	if lm, _ := h.Rdb.HGet(ctx, "lobby:"+lobbyID, "chat_id").Result(); lm != "" {
		fields = append(fields, "chat_id", lm)
	}
	if turnTimeSec > 0 {
		fields = append(fields, "turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnTimeSec), 10))
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gkey, fields...)
	pipe.Expire(ctx, gkey, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID, "status", lobbyStatusInGame, "game_id", gameID)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	_, _ = pipe.Exec(ctx)

	for _, u := range players {
		clearUserActiveLobby(ctx, h.Rdb, u)
		setUserActiveGame(ctx, h.Rdb, u, gameID)
	}
	h.publishGameStartedTyped(players, gameID, lobbyID, durakGameType)

	// В ответ — game_id и lobby_id: клиент роутит по ним без догадок.
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"joined":   true,
		"game_id":  gameID,
		"lobby_id": lobbyID,
	})
}

// ---- GetDurakGame ----

func (h *GamesHandler) GetDurakGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	// Применить таймаут хода: если время вышло — форфейт для чьего хода.
	h.applyDurakTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()

	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	// Скрываем чужие руки — оставляем длину.
	viewer := userID.String()
	view := durakViewFor(state, viewer, m, gameID)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

// ---- DurakMove ----

type durakMoveBody struct {
	Type string          `json:"type"`
	Card json.RawMessage `json:"card,omitempty"`
}

func (h *GamesHandler) DurakMove(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != durakGameType || m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type or state")
		return
	}
	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	idx := state.PlayerIndex(userID.String())
	if idx < 0 {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	var body durakMoveBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	switch body.Type {
	case "attack":
		card, err := durak.ParseCard(body.Card)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "bad card")
			return
		}
		if err := state.Attack(idx, card); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "defend":
		card, err := durak.ParseCard(body.Card)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "bad card")
			return
		}
		if err := state.Defend(idx, card); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "transfer":
		card, err := durak.ParseCard(body.Card)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "bad card")
			return
		}
		if err := state.Transfer(idx, card); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "take":
		if err := state.Take(idx); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "bito":
		if err := state.SayBito(idx); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	default:
		WriteErr(w, r, http.StatusBadRequest, "unknown move type")
		return
	}
	// Обновить турн-deadline: если ход идёт дальше — сбросим.
	encoded, _ := durak.Encode(state)
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	fields := []any{"state", encoded}
	if turnT > 0 && state.Status == durak.StatusActive {
		fields = append(fields, "turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10))
	}
	if state.Status == durak.StatusOver {
		fields = append(fields, "status", durakStatusOver)
		if state.LoserIndex >= 0 {
			fields = append(fields, "loser", state.PlayerIDs[state.LoserIndex])
		}
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)

	// Broadcast.
	humans := durakHumans(m)
	h.broadcast(humans, map[string]any{
		"type":     "game_state",
		"game_id":  gameID,
		"game_type": durakGameType,
	})
	if state.Status == durak.StatusOver {
		h.onDurakGameFinished(ctx, gameID, m, state)
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

// ---- Forfeit ----

func (h *GamesHandler) ForfeitDurakGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	idx := state.PlayerIndex(userID.String())
	if idx < 0 {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	state.Forfeit(idx)
	encoded, _ := durak.Encode(state)
	h.Rdb.HSet(ctx, "game:"+gameID,
		"state", encoded,
		"status", durakStatusOver,
		"forfeit", "1",
		"loser", state.PlayerIDs[state.LoserIndex],
	)
	humans := durakHumans(m)
	h.broadcast(humans, map[string]any{
		"type":      "game_state",
		"game_id":   gameID,
		"game_type": durakGameType,
	})
	h.onDurakGameFinished(ctx, gameID, m, state)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

// ---- Ничья (только 1×1) ----

// DurakOfferDraw — предложить ничью сопернику.
func (h *GamesHandler) DurakOfferDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(m) == 0 || m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is not active")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if len(players) != 2 {
		WriteErr(w, r, http.StatusBadRequest, "draw only in 1v1")
		return
	}
	inGame := false
	for _, p := range players {
		if p == userID.String() {
			inGame = true
		}
	}
	if !inGame {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	h.Rdb.HSet(ctx, "game:"+gameID, "draw_offer_by", userID.String())
	h.broadcast(durakHumans(m), map[string]any{
		"type":      "game_state",
		"game_id":   gameID,
		"game_type": durakGameType,
	})
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"offered": true})
}

// DurakAcceptDraw — принять ничью: партия завершается без «дурака».
func (h *GamesHandler) DurakAcceptDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(m) == 0 || m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	offeredBy := strings.TrimSpace(m["draw_offer_by"])
	if offeredBy == "" || offeredBy == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "no draw offer")
		return
	}
	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	state.Status = durak.StatusOver
	state.LoserIndex = -1 // ничья: «дурака» нет
	encoded, _ := durak.Encode(state)
	h.Rdb.HSet(ctx, "game:"+gameID,
		"state", encoded,
		"status", durakStatusOver,
		"draw", "1",
	)
	h.Rdb.HDel(ctx, "game:"+gameID, "draw_offer_by")
	humans := durakHumans(m)
	h.broadcast(humans, map[string]any{
		"type":      "game_state",
		"game_id":   gameID,
		"game_type": durakGameType,
	})
	h.onDurakGameFinished(ctx, gameID, m, state)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"draw": true})
}

// ---- Rematch (создать новое лобби из завершённой партии) ----

func (h *GamesHandler) DurakRematch(w http.ResponseWriter, r *http.Request) {
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
	if m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	// Собираем участников партии, кроме себя.
	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	// Простое поведение: создатель — я, invitee — первый соперник.
	var invitees []string
	for _, pid := range state.PlayerIDs {
		if pid != userID.String() {
			invitees = append(invitees, pid)
		}
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents")
		return
	}
	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	deckSize, _ := strconv.Atoi(m["deck_size"])
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 1 {
		stake = 1
	}
	gameMode := m["mode"]
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", durakGameType,
		"creator_id", userID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", now,
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnT),
		"max_players", strconv.Itoa(maxPlayers),
		"deck_size", strconv.Itoa(deckSize),
		"game_mode", gameMode,
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
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	// game_invite всем приглашённым.
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
		"game_type":     durakGameType,
		"turn_time_sec": turnT,
		"max_players":   maxPlayers,
		"stake_bronze":  stake,
		"deck_size":     deckSize,
		"game_mode":     gameMode,
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

// ---- View / helpers ----

func durakHumans(m map[string]string) []uuid.UUID {
	ids := parsePlayerIDsCSV(m["player_ids"])
	out := make([]uuid.UUID, 0, len(ids))
	for _, s := range ids {
		if strings.HasPrefix(s, "bot:") {
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

// durakViewFor — представление состояния для конкретного игрока.
// Свои карты видны, чужие — только количество (списки заменяем на пустые для рубашек).
func durakViewFor(s *durak.State, viewer string, m map[string]string, gameID string) map[string]any {
	myIdx := s.PlayerIndex(viewer)
	hands := make([]map[string]any, len(s.Hands))
	for i, h := range s.Hands {
		if i == myIdx {
			hands[i] = map[string]any{"cards": h, "count": len(h)}
		} else {
			hands[i] = map[string]any{"count": len(h)}
		}
	}
	legalAttack := s.LegalAttackCards(myIdx)
	legalDefend := s.LegalDefendCards(myIdx)
	turnDeadline := int64(0)
	if v, err := strconv.ParseInt(m["turn_deadline"], 10, 64); err == nil {
		turnDeadline = v
	}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	return map[string]any{
		"id":             gameID,
		"game_type":      durakGameType,
		"status":         m["status"],
		"draw":           m["draw"] == "1",
		"draw_offer_by":  strings.TrimSpace(m["draw_offer_by"]),
		"lobby_id":       m["lobby_id"],
		"chat_id":        m["chat_id"],
		"mode":           string(s.Mode),
		"deck_size":      s.DeckSize,
		"player_ids":     s.PlayerIDs,
		"hands":          hands,
		"deck_count":     len(s.Deck),
		"trump":          s.Trump.String(),
		"trump_card":     s.TrumpCard,
		"table":          s.Table,
		"bito_count":     len(s.BitoPile),
		"attacker_index": s.AttackerIndex,
		"defender_index": s.DefenderIndex(),
		"phase":          string(s.Phase),
		"my_index":       myIdx,
		"legal_attack":   legalAttack,
		"legal_defend":   legalDefend,
		"loser_index":    s.LoserIndex,
		"finished":       s.FinishedIndices,
		"turn_time_sec":  turnT,
		"turn_deadline":  turnDeadline,
		"stake_bronze":   func() int { v, _ := strconv.Atoi(m["stake_bronze"]); return v }(),
	}
}

// applyDurakTurnTimeout — если истёк ход, атакующий/защитник форфейтит (упрощение).
func (h *GamesHandler) applyDurakTurnTimeout(ctx context.Context, gameID string, m map[string]string) {
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
	state, err := durak.Decode(m["state"])
	if err != nil {
		return
	}
	// Кто не успел: если защита — take + пропуск; если атака — bito (если можно), иначе forfeit.
	if state.Phase == durak.PhaseDefend {
		def := state.DefenderIndex()
		_ = state.Take(def)
	} else if state.Phase == durak.PhaseAttackFollow {
		_ = state.SayBito(state.AttackerIndex)
	}
	encoded, _ := durak.Encode(state)
	fields := []any{"state", encoded}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	if state.Status == durak.StatusActive && turnT > 0 {
		fields = append(fields, "turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10))
	}
	if state.Status == durak.StatusOver {
		fields = append(fields, "status", durakStatusOver, "loser", state.PlayerIDs[state.LoserIndex])
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
}

// onDurakGameFinished — очистка active/observation, ставки, статистика.
func (h *GamesHandler) onDurakGameFinished(ctx context.Context, gameID string, m map[string]string, state *durak.State) {
	humans := durakHumans(m)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	// Очистить чат лобби (multi).
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
	// Записать в game_results (пока без начисления монет — MVP).
	if len(state.PlayerIDs) >= 2 && state.Status == durak.StatusOver {
		// TODO: интеграция со ставками и монетами — следующая итерация.
		_ = state
	}
}
