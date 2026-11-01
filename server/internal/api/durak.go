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
		})
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

// ---- Lobby: CreateDurakLobby ----

type createDurakLobbyBody struct {
	Mode        string `json:"mode"`        // "invite" | "matchmake"
	MaxPlayers  int    `json:"max_players"` // 2..4
	DeckSize    int    `json:"deck_size"`   // 24/36/52
	GameMode    string `json:"game_mode"`   // "podkidnoi" | "perevodnoi"
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
	// Вдвоём — 24/36; втроём и вчетвером — 36/52.
	if deckSize == 24 && maxPlayers > 2 {
		WriteErr(w, r, http.StatusBadRequest, "deck 24 supports only 2 players")
		return
	}
	if deckSize == 52 && maxPlayers < 3 {
		WriteErr(w, r, http.StatusBadRequest, "deck 52 requires 3 or 4 players")
		return
	}
	if !validTurnTimeSec[body.TurnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	gameMode := string(durak.ParseMode(body.GameMode))
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
	// Достаточность баланса (весь balance_bronze: серебро/золото тоже считаются).
	if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
		if err == store.ErrInsufficientFunds {
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
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
	h.rememberLobby(lobbyID)
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
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
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
	keys, err := h.lobbyHashKeys(ctx)
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

// checkStakeAffordable — хватает ли единого баланса (бронза+серебро+…) на ставку.
// 1 серебро = 100 бронзы в balance_bronze; отдельного кошелька серебра нет.
func (h *GamesHandler) checkStakeAffordable(ctx context.Context, userID uuid.UUID, stakeBronze int) error {
	if stakeBronze <= 0 || h.Pool == nil {
		return nil
	}
	bal, err := store.GetBalance(ctx, h.Pool, userID)
	if err != nil {
		return err
	}
	if bal < stakeBronze {
		return store.ErrInsufficientFunds
	}
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
	keys, err := h.lobbyHashKeys(ctx)
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
		if stake < 2 {
			stake = 2
		}
		items = append(items, lobbyOut{
			LobbyID:     strings.TrimPrefix(key, "lobby:"),
			CreatorID:   m["creator_id"],
			Status:      st,
			GameType:    durakGameType,
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
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["game_type"] != durakGameType {
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
	// Слишком много игроков — уже стартовало.
	if len(players) > maxPlayers {
		WriteErr(w, r, http.StatusConflict, "lobby full")
		return
	}

	deckSize, _ := strconv.Atoi(m["deck_size"])
	gameMode := m["game_mode"]
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 2 {
		stake = 2
	}
	creatorUUID, _ := uuid.Parse(m["creator_id"])

	// Ставка и баланс — до записи в лобби (иначе «присоединился», а игра не стартовала).
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
	// Открытый поиск: обновить вкладку «Лобби» (состав / убрать при заполнении).
	if m["mode"] == "matchmake" && strings.TrimSpace(m["invite_target_id"]) == "" {
		h.notifyPublicLobbiesChanged()
	}

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
	// Списываем ставку у людей — как в крестиках-ноликах.
	// Баланс один (balance_bronze): 1 серебро = 100 бронзы.
	if stakeBronze > 0 {
		humans := make([]uuid.UUID, 0, len(players))
		for _, u := range players {
			ok, e := store.UserMayStake(ctx, h.Pool, u, stakeBronze)
			if e != nil {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
			if !ok {
				WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
				return
			}
			bal, be := store.GetBalance(ctx, h.Pool, u)
			if be != nil {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
			if bal < stakeBronze {
				// Весь balance_bronze (серебро/золото входят); не только «остаток бронзы».
				reqUID, _ := currentUserIDFromGames(r)
				if u == reqUID {
					WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
				} else {
					WriteErr(w, r, http.StatusConflict, "a player has insufficient balance")
				}
				return
			}
			humans = append(humans, u)
		}
		if err := store.DeductCoinsMany(ctx, h.Pool, humans, stakeBronze); err != nil {
			if err == store.ErrInsufficientFunds {
				WriteErr(w, r, http.StatusPaymentRequired, "insufficient funds")
				return
			}
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
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
	// Таймер хода — только после стартовой раздачи на клиенте.
	graceUntil := time.Now().UTC().Unix() + int64(durak.OpeningDealGraceFor(state)/time.Second)
	fields = append(fields,
		"deal_grace_until", strconv.FormatInt(graceUntil, 10),
		"turn_deadline", "0",
		"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
	)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gkey, fields...)
	pipe.Expire(ctx, gkey, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID, "status", lobbyStatusInGame, "game_id", gameID)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	_, _ = pipe.Exec(ctx)

	// Приглашённые, кто ещё не вошёл — убрать карточку; лобби уходит из списка.
	h.notifyAndClearLobbyInvites(ctx, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)

	for _, u := range players {
		clearUserActiveLobby(ctx, h.Rdb, u)
		setUserActiveGame(ctx, h.Rdb, u, gameID)
	}
	h.publishGameStartedTyped(players, gameID, lobbyID, durakGameType)
	if turnTimeSec > 0 {
		h.scheduleDurakDealGrace(gameID)
	}

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
	// После раздачи — включить таймер; затем проверить таймаут хода.
	h.armDurakTurnAfterDeal(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	h.applyDurakTurnTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()

	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	// Недобор после бага refill при 3 игроках — добрать и сохранить.
	if h.healDurakShortHands(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	// Пауза «все отбили» истекла — увести стол в отбой.
	if h.healDurakBitoReveal(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	// Пауза перед взятием истекла — карты защитнику.
	if h.healDurakTakeReveal(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	// Вышедшие «в ноль» (миграция / reconnect) → observation + ранняя выплата.
	h.promoteDurakFinishedPlayers(ctx, gameID, m, state)
	// Застрявшее: у защитника 0 карт, стол не пуст — закрыть раунд.
	if h.healDurakDefenderEmpty(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	// Застрявшее: колода пуста, рук ни у кого нет, партия ещё «active» — ничья.
	if h.healDurakBothEmptyDraw(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	// Скрываем чужие руки — оставляем длину.
	viewer := userID.String()
	view := durakViewFor(state, viewer, m, gameID)
	h.enrichDurakPlayersMeta(ctx, view, state.PlayerIDs)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

// durakRevealDeadlineMs — дедлайн паузы в unix-ms; старые сейвы хранили секунды.
func durakRevealDeadlineMs(raw string, delay time.Duration) (deadlineMs int64, missing bool) {
	v, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || v <= 0 {
		return time.Now().UTC().Add(delay).UnixMilli(), true
	}
	// Секунды (~1e9…1e10) → миллисекунды.
	if v < 1_000_000_000_000 {
		v *= 1000
	}
	return v, false
}

// healDurakBitoReveal — если фаза bito_reveal и время паузы вышло → отбой.
func (h *GamesHandler) healDurakBitoReveal(ctx context.Context, gameID string, m map[string]string, state *durak.State) bool {
	if state == nil || state.Status != durak.StatusActive || state.Phase != durak.PhaseBitoReveal {
		return false
	}
	revealAt, missing := durakRevealDeadlineMs(m["bito_reveal_at"], state.ActiveRevealDelay())
	if missing {
		// Нет метки — взвести паузу заново, не закрывать стол мгновенно.
		h.Rdb.HSet(ctx, "game:"+gameID, "bito_reveal_at", strconv.FormatInt(revealAt, 10))
		h.scheduleDurakBitoReveal(gameID, state.ActiveRevealDelay())
		return false
	}
	if time.Now().UTC().UnixMilli() < revealAt {
		left := time.Until(time.UnixMilli(revealAt).UTC())
		if left > 40*time.Millisecond {
			h.scheduleDurakBitoReveal(gameID, left)
		}
		return false
	}
	if err := state.FinishBitoReveal(); err != nil {
		return false
	}
	encoded, err := durak.Encode(state)
	if err != nil {
		return false
	}
	fields := []any{"state", encoded, "bito_reveal_at", "0"}
	if state.Status == durak.StatusOver {
		fields = append(fields, durakOverRedisFields(state)...)
	} else if turnT, e := strconv.Atoi(m["turn_time_sec"]); e == nil && turnT > 0 {
		fields = append(fields,
			"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
			"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
		)
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	h.promoteDurakFinishedPlayers(ctx, gameID, m, state)
	if state.Status == durak.StatusOver {
		if state.LoserIndex < 0 {
			m["draw"] = "1"
		}
		h.onDurakGameFinished(ctx, gameID, m, state)
	}
	return true
}

// scheduleDurakBitoReveal — после хода дожать отбой и разослать state.
func (h *GamesHandler) scheduleDurakBitoReveal(gameID string, delay time.Duration) {
	if delay <= 0 {
		delay = durak.BitoRevealDelay
	}
	go func() {
		timer := time.NewTimer(delay + 50*time.Millisecond)
		defer timer.Stop()
		<-timer.C
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["status"] != gameStatusActive {
				return nil
			}
			state, err := durak.Decode(m["state"])
			if err != nil || state.Phase != durak.PhaseBitoReveal {
				return nil
			}
			_ = h.healDurakBitoReveal(ctx, gameID, m, state)
			return nil
		})
	}()
}

// healDurakTakeReveal — если фаза take_reveal и время паузы вышло → карты защитнику.
func (h *GamesHandler) healDurakTakeReveal(ctx context.Context, gameID string, m map[string]string, state *durak.State) bool {
	if state == nil || state.Status != durak.StatusActive || state.Phase != durak.PhaseTakeReveal {
		return false
	}
	revealAt, missing := durakRevealDeadlineMs(m["take_reveal_at"], state.ActiveRevealDelay())
	if missing {
		h.Rdb.HSet(ctx, "game:"+gameID, "take_reveal_at", strconv.FormatInt(revealAt, 10))
		h.scheduleDurakTakeReveal(gameID, state.ActiveRevealDelay())
		return false
	}
	if time.Now().UTC().UnixMilli() < revealAt {
		left := time.Until(time.UnixMilli(revealAt).UTC())
		if left > 40*time.Millisecond {
			h.scheduleDurakTakeReveal(gameID, left)
		}
		return false
	}
	if err := state.FinishTakeReveal(); err != nil {
		return false
	}
	encoded, err := durak.Encode(state)
	if err != nil {
		return false
	}
	fields := []any{"state", encoded, "take_reveal_at", "0", "throw_reveal_at", "0"}
	if state.Status == durak.StatusOver {
		fields = append(fields, durakOverRedisFields(state)...)
	} else if turnT, e := strconv.Atoi(m["turn_time_sec"]); e == nil && turnT > 0 {
		fields = append(fields,
			"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
			"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
		)
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	h.promoteDurakFinishedPlayers(ctx, gameID, m, state)
	if state.Status == durak.StatusOver {
		if state.LoserIndex < 0 {
			m["draw"] = "1"
		}
		h.onDurakGameFinished(ctx, gameID, m, state)
	}
	return true
}

// scheduleDurakTakeReveal — после подкида→«Беру» отдать карты защитнику.
func (h *GamesHandler) scheduleDurakTakeReveal(gameID string, delay time.Duration) {
	if delay <= 0 {
		delay = durak.TakeRevealDelay
	}
	go func() {
		timer := time.NewTimer(delay + 50*time.Millisecond)
		defer timer.Stop()
		<-timer.C
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["status"] != gameStatusActive {
				return nil
			}
			state, err := durak.Decode(m["state"])
			if err != nil || state.Phase != durak.PhaseTakeReveal {
				return nil
			}
			_ = h.healDurakTakeReveal(ctx, gameID, m, state)
			return nil
		})
	}()
}

// armDurakTurnAfterDeal — после паузы стартовой раздачи выставить turn_deadline.
func (h *GamesHandler) armDurakTurnAfterDeal(ctx context.Context, gameID string, m map[string]string) bool {
	if h.Rdb == nil || m == nil || m["status"] != gameStatusActive {
		return false
	}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	if turnT <= 0 {
		return false
	}
	deadline, _ := strconv.ParseInt(m["turn_deadline"], 10, 64)
	graceUntil, _ := strconv.ParseInt(m["deal_grace_until"], 10, 64)
	state, err := durak.Decode(m["state"])
	if err != nil || state == nil || state.Status != durak.StatusActive {
		return false
	}
	// Пауза «Беру»/«Бито» тоже пишет deadline 0. Без этой проверки GetGame
	// в окне паузы заводил полный таймер хода при actor -1: оба клиента
	// рисовали часы на сопернике и видели «Беру», пока пауза не кончится.
	if !durakMayArmTurnClock(state.Phase, deadline, graceUntil, time.Now().UTC().Unix()) {
		return false
	}
	actor := durakTurnActorIdx(state)
	h.Rdb.HSet(ctx, "game:"+gameID,
		"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
		"turn_actor_idx", strconv.Itoa(actor),
		"deal_grace_until", "0",
	)
	m["turn_deadline"] = strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10)
	m["turn_actor_idx"] = strconv.Itoa(actor)
	m["deal_grace_until"] = "0"
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	return true
}

// scheduleDurakDealGrace — через OpeningDealGrace включить таймер хода.
func (h *GamesHandler) scheduleDurakDealGrace(gameID string) {
	go func() {
		// Верхняя оценка раздачи; точный arm — по deal_grace_until.
		timer := time.NewTimer(durak.OpeningDealGraceExtra(4, 12) + 200*time.Millisecond)
		defer timer.Stop()
		<-timer.C
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["status"] != gameStatusActive {
				return nil
			}
			_ = h.armDurakTurnAfterDeal(ctx, gameID, m)
			return nil
		})
	}()
}

// promoteDurakFinishedPlayers — вышедший «в ноль» → observation; ранняя выплата доли места.
func (h *GamesHandler) promoteDurakFinishedPlayers(ctx context.Context, gameID string, m map[string]string, state *durak.State) {
	if state == nil || h.Rdb == nil || len(state.FinishedIndices) == 0 {
		return
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	n := len(state.PlayerIDs)
	// Ничья лидеров: банк мест (1+2+3…) делится поровну между TiedLeaders.
	tiedCredits := map[int]int{}
	if state.TiedLeaders >= 2 && stakeBronze > 0 {
		pot := stakeBronze * n
		each := pot / state.TiedLeaders
		rem := pot % state.TiedLeaders
		for i := 0; i < state.TiedLeaders && i < len(state.FinishedIndices); i++ {
			c := each
			if i == 0 {
				c += rem
			}
			tiedCredits[state.FinishedIndices[i]] = c
		}
	}
	for placeIdx, idx := range state.FinishedIndices {
		if idx < 0 || idx >= n {
			continue
		}
		pid := state.PlayerIDs[idx]
		if isBot(pid) {
			continue
		}
		u, err := uuid.Parse(pid)
		if err != nil {
			continue
		}
		// Как сдача в multi: active → observation, пока партия идёт.
		if state.Status == durak.StatusActive {
			moveActiveToObserving(ctx, h.Rdb, u, gameID)
		}
		// Монеты при конце партии — в settleDurakCoins (с учётом early_paid).
		if state.Status != durak.StatusActive || stakeBronze <= 0 || h.Pool == nil {
			continue
		}
		credit := 0
		if c, ok := tiedCredits[idx]; ok {
			credit = c
		} else if state.TiedLeaders >= 2 && placeIdx < state.TiedLeaders {
			continue
		} else if state.TiedLeaders >= 2 {
			// Места после ничьей лидеров уже «съедены» общим банком.
			continue
		} else {
			credit = durak.CreditForPlace(stakeBronze, n, placeIdx)
		}
		if credit <= 0 {
			continue
		}
		ok, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "early_paid:"+pid, strconv.Itoa(credit)).Result()
		if err != nil || !ok {
			continue
		}
		if err := store.AddCoins(ctx, h.Pool, u, credit); err != nil {
			// Откатить флаг, чтобы финальный settle мог выплатить.
			h.Rdb.HDel(ctx, "game:"+gameID, "early_paid:"+pid)
		}
	}
}

// healDurakShortHands — добрать карты, если стол пуст, а у кого-то меньше HandSize
// (старый баг порядка refill при 3 игроках).
func (h *GamesHandler) healDurakShortHands(ctx context.Context, gameID string, m map[string]string, state *durak.State) bool {
	if state == nil || !state.RefillIfNeeded() {
		return false
	}
	encoded, err := durak.Encode(state)
	if err != nil {
		return false
	}
	h.Rdb.HSet(ctx, "game:"+gameID, "state", encoded)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	return true
}

// healDurakDefenderEmpty — дожимает раунд, если защитник уже без карт, а стол ещё лежит.
// Возвращает true, если состояние записали в Redis.
func (h *GamesHandler) healDurakDefenderEmpty(ctx context.Context, gameID string, m map[string]string, state *durak.State) bool {
	if state == nil || state.Status != durak.StatusActive || len(state.Table) == 0 {
		return false
	}
	if state.Phase == durak.PhaseBitoReveal || state.Phase == durak.PhaseTakeReveal {
		return false
	}
	def := state.DefenderIndex()
	if def < 0 || def >= len(state.Hands) || len(state.Hands[def]) > 0 {
		return false
	}
	state.HealDefenderEmpty()
	encoded, err := durak.Encode(state)
	if err != nil {
		return false
	}
	fields := []any{"state", encoded}
	if state.Status == durak.StatusOver {
		fields = append(fields, durakOverRedisFields(state)...)
	} else if turnT, e := strconv.Atoi(m["turn_time_sec"]); e == nil && turnT > 0 {
		fields = append(fields,
			"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
			"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
		)
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	h.promoteDurakFinishedPlayers(ctx, gameID, m, state)
	if state.Status == durak.StatusOver {
		if state.LoserIndex < 0 {
			m["draw"] = "1"
		}
		h.onDurakGameFinished(ctx, gameID, m, state)
	}
	return true
}

// durakOverRedisFields — status=over + loser или draw (оба вышли).
func durakOverRedisFields(state *durak.State) []any {
	fields := []any{"status", durakStatusOver}
	if state.LoserIndex >= 0 && state.LoserIndex < len(state.PlayerIDs) {
		fields = append(fields, "loser", state.PlayerIDs[state.LoserIndex])
	} else {
		fields = append(fields, "draw", "1")
	}
	return fields
}

// healDurakBothEmptyDraw — если все живые без карт и колода пуста, фиксируем ничью.
func (h *GamesHandler) healDurakBothEmptyDraw(ctx context.Context, gameID string, m map[string]string, state *durak.State) bool {
	if state == nil || state.Status != durak.StatusActive || len(state.Deck) > 0 || len(state.Table) > 0 {
		return false
	}
	for _, hnd := range state.Hands {
		if len(hnd) > 0 {
			return false
		}
	}
	state.HealGameOver()
	if state.Status != durak.StatusOver {
		return false
	}
	encoded, err := durak.Encode(state)
	if err != nil {
		return false
	}
	fields := append([]any{"state", encoded}, durakOverRedisFields(state)...)
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	if state.LoserIndex < 0 {
		m["draw"] = "1"
	}
	h.onDurakGameFinished(ctx, gameID, m, state)
	return true
}

// enrichDurakPlayersMeta — имена/аватары/рамки игроков (как x_/o_ в крестиках).
func (h *GamesHandler) enrichDurakPlayersMeta(ctx context.Context, view map[string]any, playerIDs []string) {
	players := make([]map[string]any, 0, len(playerIDs))
	ids := make([]uuid.UUID, 0, len(playerIDs))
	for _, pid := range playerIDs {
		entry := map[string]any{"id": pid}
		if isBot(pid) {
			entry["display_name"] = "Бот"
			players = append(players, entry)
			continue
		}
		uid, err := uuid.Parse(pid)
		if err != nil {
			players = append(players, entry)
			continue
		}
		ids = append(ids, uid)
		user, err := store.GetUserByID(ctx, h.Pool, uid)
		if err == nil && user != nil {
			if user.DisplayName != nil && *user.DisplayName != "" {
				entry["display_name"] = *user.DisplayName
			}
			if user.AvatarKind != "" {
				entry["avatar_kind"] = user.AvatarKind
			}
			if user.AvatarValue != nil {
				entry["avatar_value"] = *user.AvatarValue
			}
		}
		players = append(players, entry)
	}
	if frames, err := store.EquippedFramesMap(ctx, h.Pool, ids); err == nil {
		for _, entry := range players {
			pid, _ := entry["id"].(string)
			uid, err := uuid.Parse(pid)
			if err != nil {
				continue
			}
			if f, ok := frames[uid]; ok {
				entry["frame_code"] = f.Code
				entry["frame_color"] = f.Color
			}
		}
	}
	view["players"] = players
}

// broadcastDurakState шлёт каждому человеку полный view (как GET), не ping.
func (h *GamesHandler) broadcastDurakState(ctx context.Context, gameID string, m map[string]string, state *durak.State, extra map[string]any) {
	if ctx == nil {
		ctx = context.Background()
	}
	if h.Rdb != nil {
		if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
			m = fresh
		}
	}
	if state == nil && m != nil {
		state, _ = durak.Decode(m["state"])
	}
	if state == nil {
		payload := map[string]any{
			"type":      "game_state",
			"game_id":   gameID,
			"game_type": durakGameType,
		}
		for k, v := range extra {
			payload[k] = v
		}
		h.broadcast(durakHumans(m), payload)
		return
	}
	for _, u := range durakHumans(m) {
		view := durakViewFor(state, u.String(), m, gameID)
		h.enrichDurakPlayersMeta(ctx, view, state.PlayerIDs)
		view["type"] = "game_state"
		view["game_id"] = gameID
		for k, v := range extra {
			view[k] = v
		}
		h.broadcast([]uuid.UUID{u}, view)
	}
}

// ---- DurakMove ----

type durakMoveBody struct {
	Type      string          `json:"type"`
	Card      json.RawMessage `json:"card,omitempty"`
	Cards     json.RawMessage `json:"cards,omitempty"`      // несколько карт атаки/подкида
	PairIndex *int            `json:"pair_index,omitempty"` // индекс пары для defend
}

func parseDurakAttackCards(body durakMoveBody) ([]durak.Card, error) {
	if len(body.Cards) > 0 && string(body.Cards) != "null" {
		var raws []json.RawMessage
		if err := json.Unmarshal(body.Cards, &raws); err != nil {
			return nil, err
		}
		if len(raws) == 0 {
			return nil, fmt.Errorf("empty cards")
		}
		out := make([]durak.Card, 0, len(raws))
		for _, raw := range raws {
			c, err := durak.ParseCard(raw)
			if err != nil {
				return nil, err
			}
			out = append(out, c)
		}
		return out, nil
	}
	c, err := durak.ParseCard(body.Card)
	if err != nil {
		return nil, err
	}
	return []durak.Card{c}, nil
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
	if m["game_type"] != durakGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type or state")
		return
	}
	state, err := durak.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if h.healDurakShortHands(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
	}
	if h.healDurakBitoReveal(ctx, gameID, m, state) {
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
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
	// Таймаут не срывает ход владельца таймера (взятие/карта на последней секунде).
	// Чужой ход / GetGame по-прежнему дожимают протухший deadline.
	actor := durakTurnActorIdx(state)
	if v, e := strconv.Atoi(m["turn_actor_idx"]); e == nil && v >= 0 && v < len(state.PlayerIDs) {
		actor = v
	}
	if idx != actor {
		h.applyDurakTurnTimeout(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		if m["status"] != gameStatusActive {
			WriteErr(w, r, http.StatusBadRequest, "wrong game type or state")
			return
		}
		state, err = durak.Decode(m["state"])
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "bad state")
			return
		}
		idx = state.PlayerIndex(userID.String())
		if idx < 0 {
			WriteErr(w, r, http.StatusForbidden, "not a player")
			return
		}
	}
	switch body.Type {
	case "attack":
		cards, err := parseDurakAttackCards(body)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "bad card")
			return
		}
		if err := state.AttackMany(idx, cards); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "defend":
		card, err := durak.ParseCard(body.Card)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "bad card")
			return
		}
		pairIdx := -1
		if body.PairIndex != nil {
			pairIdx = *body.PairIndex
		}
		if err := state.Defend(idx, card, pairIdx); err != nil {
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
	case "done":
		// Атакующий закончил подкид вдогонку после «Беру».
		if err := state.Done(idx); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	case "pass":
		// Отказ подкидывать (3–4 игрока); когда все пасанули — бито/взятие.
		if err := state.Pass(idx); err != nil {
			WriteErr(w, r, http.StatusBadRequest, err.Error())
			return
		}
	default:
		WriteErr(w, r, http.StatusBadRequest, "unknown move type")
		return
	}
	// Обновить турн-deadline + кто владеет таймером (для корректного таймаута).
	encoded, _ := durak.Encode(state)
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	fields := []any{"state", encoded}
	if state.Status == durak.StatusActive && state.Phase == durak.PhaseBitoReveal {
		// Пауза показа стола: без таймера хода / forfeit, через 2с — отбой.
		revealAt := time.Now().UTC().Add(state.ActiveRevealDelay()).UnixMilli()
		fields = append(fields,
			"bito_reveal_at", strconv.FormatInt(revealAt, 10),
			"take_reveal_at", "0",
			"throw_reveal_at", "0",
			"turn_deadline", "0",
			"turn_actor_idx", "-1",
		)
	} else if state.Status == durak.StatusActive && state.Phase == durak.PhaseTakeReveal {
		// Пауза перед взятием: все видят подкид, через 2с — карты защитнику.
		revealAt := time.Now().UTC().Add(state.ActiveRevealDelay()).UnixMilli()
		fields = append(fields,
			"take_reveal_at", strconv.FormatInt(revealAt, 10),
			"bito_reveal_at", "0",
			"throw_reveal_at", "0",
			"turn_deadline", "0",
			"turn_actor_idx", "-1",
		)
	} else if turnT > 0 && state.Status == durak.StatusActive {
		fields = append(fields,
			"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
			"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
			"bito_reveal_at", "0",
			"take_reveal_at", "0",
			"throw_reveal_at", "0",
			"deal_grace_until", "0",
		)
	} else {
		fields = append(fields, "bito_reveal_at", "0", "take_reveal_at", "0", "throw_reveal_at", "0")
	}
	if state.Status == durak.StatusOver {
		fields = append(fields, durakOverRedisFields(state)...)
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)

	// Вышедшие «в ноль» сразу → observation + монеты (не ждать конца партии).
	h.promoteDurakFinishedPlayers(ctx, gameID, m, state)

	// Broadcast.
	h.broadcastDurakState(ctx, gameID, m, state, nil)
	if state.Status == durak.StatusActive && state.Phase == durak.PhaseBitoReveal {
		h.scheduleDurakBitoReveal(gameID, state.ActiveRevealDelay())
	}
	if state.Status == durak.StatusActive && state.Phase == durak.PhaseTakeReveal {
		h.scheduleDurakTakeReveal(gameID, state.ActiveRevealDelay())
	}
	if state.Status == durak.StatusOver {
		if state.LoserIndex < 0 {
			m["draw"] = "1"
		}
		h.onDurakGameFinished(ctx, gameID, m, state)
	} else if state.Status == durak.StatusActive {
		if actor := durakTurnActorIdx(state); actor >= 0 && actor < len(state.PlayerIDs) {
			h.notifyYourTurnUser(gameID, state.PlayerIDs[actor], durakGameType)
		}
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
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
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
	if state.IsEliminated(idx) {
		WriteErr(w, r, http.StatusBadRequest, "already forfeited")
		return
	}
	continues := state.Eliminate(idx)
	encoded, _ := durak.Encode(state)
	if continues {
		// Партия идёт: не ставим forfeit на игру — иначе в конце у
		// оставшихся будет «Соперник сдался», хотя сдался третий раньше.
		fields := []any{"state", encoded}
		if turnT, e := strconv.Atoi(m["turn_time_sec"]); e == nil && turnT > 0 {
			fields = append(fields,
				"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
				"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
			)
		}
		h.Rdb.HSet(ctx, "game:"+gameID, fields...)
		// Сбрасываем «липкий» forfeit от прошлой сдачи (если был).
		h.Rdb.HDel(ctx, "game:"+gameID, "forfeit")
		moveActiveToObserving(ctx, h.Rdb, userID, gameID)
		h.broadcastDurakState(ctx, gameID, m, state, map[string]any{
			"forfeit":      true,
			"left_user_id": userID.String(),
		})
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok": true, "status": gameStatusActive, "eliminated": true, "forfeit": true,
		})
		return
	}
	fields := []any{"state", encoded, "status", durakStatusOver, "forfeit", "1"}
	if state.LoserIndex >= 0 && state.LoserIndex < len(state.PlayerIDs) {
		fields = append(fields, "loser", state.PlayerIDs[state.LoserIndex])
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.broadcastDurakState(ctx, gameID, m, state, map[string]any{"forfeit": true})
	h.onDurakGameFinished(ctx, gameID, m, state)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "status": durakStatusOver, "forfeit": true})
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
	mod, _ := h.games().Get(durakGameType)
	if mod != nil && !mod.SupportsDrawOffer(len(players)) {
		WriteErr(w, r, http.StatusBadRequest, "draw only in 1v1")
		return
	}
	if mod == nil && len(players) != 2 {
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
	h.broadcastDurakState(ctx, gameID, m, nil, nil)
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
	h.broadcastDurakState(ctx, gameID, m, state, nil)
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
	h.rememberLobby(lobbyID)
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	deckSize, _ := strconv.Atoi(m["deck_size"])
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	stake, _ := strconv.Atoi(m["stake_bronze"])
	if stake < 2 {
		stake = 2
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
	h.trackUserInvites(ctx, lobbyID, invitees)
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
	legalTransfer := s.LegalTransferCards(myIdx)
	turnDeadline := int64(0)
	if v, err := strconv.ParseInt(m["turn_deadline"], 10, 64); err == nil {
		turnDeadline = v
	}
	turnT, _ := strconv.Atoi(m["turn_time_sec"])
	// Статус/ничья из state — чтобы UI не расходился с Redis hash.
	status := m["status"]
	draw := m["draw"] == "1"
	if s.Status == durak.StatusOver {
		status = durakStatusOver
		if s.LoserIndex < 0 {
			draw = true
		}
	}
	return map[string]any{
		"id":            gameID,
		"game_type":     durakGameType,
		"status":        status,
		"draw":          draw,
		"draw_offer_by": strings.TrimSpace(m["draw_offer_by"]),
		"forfeit":       m["forfeit"] == "1",
		"timeout":       m["timeout"] == "1",
		"lobby_id":      m["lobby_id"],
		"chat_id":       m["chat_id"],
		"mode":          string(s.Mode),
		"deck_size":     s.DeckSize,
		"player_ids":    s.PlayerIDs,
		"hands":         hands,
		"deck_count":    len(s.Deck),
		"trump":         s.Trump.String(),
		"trump_card":    s.TrumpCard,
		"lead_trump": func() any {
			// Пока стол пуст в первом отбое — карта, которой открыли ход.
			if s.Status != durak.StatusActive || s.RoundEnded ||
				len(s.Table) > 0 || s.LastWasTake || len(s.BitoPile) > 0 {
				return nil
			}
			if c := s.LeadTrump(); c != nil {
				return *c
			}
			return nil
		}(),
		"table":          s.Table,
		"bito_count":     len(s.BitoPile),
		"attacker_index": s.AttackerIndex,
		"defender_index": s.DefenderIndex(),
		"phase":          string(s.Phase),
		"last_was_take":  s.LastWasTake,
		"first_round":    s.Status == durak.StatusActive && !s.RoundEnded && len(s.BitoPile) == 0 && !s.LastWasTake,
		"my_index":       myIdx,
		"legal_attack":   legalAttack,
		"legal_defend":   legalDefend,
		"legal_transfer": legalTransfer,
		"can_throw_in":   s.CanThrowIn(myIdx),
		"thrower_index":  s.ThrowerIndex,
		"turn_actor_idx": durakTurnActorIdx(s),
		"loser_index": func() int {
			if s.Status != durak.StatusOver {
				return -1
			}
			return s.LoserIndex
		}(),
		"finished":      s.FinishedIndices,
		"tied_leaders":  s.TiedLeaders,
		"eliminated":    s.EliminatedIndices,
		"turn_time_sec": turnT,
		"turn_deadline": turnDeadline,
		"stake_bronze":  func() int { v, _ := strconv.Atoi(m["stake_bronze"]); return v }(),
	}
}

// durakMayArmTurnClock — можно ли сейчас впервые включить таймер хода.
// Пауза показа стола и ещё не вышедший deal_grace — нет.
func durakMayArmTurnClock(phase durak.TurnPhase, deadline, graceUntil, nowUnix int64) bool {
	if deadline > 0 {
		return false
	}
	if phase == durak.PhaseBitoReveal || phase == durak.PhaseTakeReveal {
		return false
	}
	if graceUntil > 0 && nowUnix < graceUntil {
		return false
	}
	return true
}

// durakTurnActorIdx — чей таймер хода (защитник / атакующий / текущий подкидывающий).
// Вышедших «в ноль» и сдавшихся пропускаем — иначе таймер залипает на победителе.
func durakTurnActorIdx(state *durak.State) int {
	if state.Phase == durak.PhaseBitoReveal || state.Phase == durak.PhaseTakeReveal {
		return -1 // пауза показа стола — ничей таймер
	}
	pick := func(idx int) int {
		if idx >= 0 && idx < len(state.PlayerIDs) && state.IsAlive(idx) {
			return idx
		}
		if idx >= 0 {
			return state.NextAliveAfter(idx)
		}
		return state.AttackerIndex
	}
	switch state.Phase {
	case durak.PhaseDefend:
		return pick(state.DefenderIndex())
	case durak.PhaseThrowIn, durak.PhaseAttackFollow, durak.PhaseTakeFollow:
		if state.ThrowerIndex >= 0 && state.ThrowerIndex < len(state.PlayerIDs) {
			return pick(state.ThrowerIndex)
		}
		return pick(state.AttackerIndex)
	default:
		return pick(state.AttackerIndex)
	}
}

// applyDurakTurnTimeout — если истёк ход, проигрывает владелец deadline (не «текущая» фаза после гонки с ходом).
func (h *GamesHandler) applyDurakTurnTimeout(ctx context.Context, gameID string, m map[string]string) {
	if m["status"] != gameStatusActive {
		return
	}
	// Пауза показа отбоя / взятия — не сдача, а дожать по таймеру reveal.
	if st, err := durak.Decode(m["state"]); err == nil {
		if st.Phase == durak.PhaseBitoReveal {
			_ = h.healDurakBitoReveal(ctx, gameID, m, st)
			return
		}
		if st.Phase == durak.PhaseTakeReveal {
			_ = h.healDurakTakeReveal(ctx, gameID, m, st)
			return
		}
	}
	// Стартовая раздача ещё идёт — таймер не тикает.
	if graceUntil, gerr := strconv.ParseInt(m["deal_grace_until"], 10, 64); gerr == nil && graceUntil > 0 {
		if time.Now().UTC().Unix() < graceUntil {
			return
		}
		if h.armDurakTurnAfterDeal(ctx, gameID, m) {
			m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		}
	}
	turnDeadline, err := strconv.ParseInt(m["turn_deadline"], 10, 64)
	// 0 = нет лимита / пауза reveal / до раздачи — не считаем просрочкой.
	if err != nil || turnDeadline <= 0 {
		return
	}
	// now == deadline уже считается истечением (клиент показывает 0 с).
	if time.Now().UTC().Unix() < turnDeadline {
		return
	}
	// Перечитать Redis: ход на последней секунде мог уже обновить deadline/фазу.
	fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(fresh) == 0 || fresh["status"] != gameStatusActive {
		return
	}
	freshDL, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDL != turnDeadline {
		// Deadline сменился успешным ходом — таймаут по старому снимку не применяем.
		return
	}
	if time.Now().UTC().Unix() < freshDL {
		return
	}
	state, err := durak.Decode(fresh["state"])
	if err != nil || state.Status != durak.StatusActive {
		return
	}
	// Пауза показа стола — только отбой / взятие, без сдачи по таймеру.
	if state.Phase == durak.PhaseBitoReveal {
		_ = h.healDurakBitoReveal(ctx, gameID, fresh, state)
		return
	}
	if state.Phase == durak.PhaseTakeReveal {
		_ = h.healDurakTakeReveal(ctx, gameID, fresh, state)
		return
	}
	phaseActor := durakTurnActorIdx(state)
	if phaseActor < 0 || phaseActor >= len(state.PlayerIDs) || !state.IsAlive(phaseActor) {
		return
	}
	redisActor := -1
	if v, e := strconv.Atoi(fresh["turn_actor_idx"]); e == nil {
		redisActor = v
	}
	// Залипший deadline прошлого хода (actor не совпадает с фазой) — не сдаём,
	// а подтягиваем таймер под текущего игрока.
	if redisActor >= 0 && redisActor != phaseActor {
		if turnT, e := strconv.Atoi(fresh["turn_time_sec"]); e == nil && turnT > 0 {
			h.Rdb.HSet(ctx, "game:"+gameID,
				"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
				"turn_actor_idx", strconv.Itoa(phaseActor),
			)
		}
		return
	}
	timedOutIdx := phaseActor
	// Пачка подкида («Все») или вдогонка после «Беру»: по таймауту — Done, без сдачи.
	if state.Phase == durak.PhaseTakeFollow || state.Phase == durak.PhaseThrowIn {
		if err := state.Done(timedOutIdx); err != nil {
			_ = state.Done(state.ThrowerIndex)
		}
		encoded, err := durak.Encode(state)
		if err != nil {
			return
		}
		fields := []any{"state", encoded}
		if state.Status == durak.StatusActive && state.Phase == durak.PhaseTakeReveal {
			revealAt := time.Now().UTC().Add(state.ActiveRevealDelay()).UnixMilli()
			fields = append(fields,
				"take_reveal_at", strconv.FormatInt(revealAt, 10),
				"bito_reveal_at", "0",
				"throw_reveal_at", "0",
				"turn_deadline", "0",
				"turn_actor_idx", "-1",
			)
		} else if state.Status == durak.StatusOver {
			fields = append(fields, durakOverRedisFields(state)...)
		} else if turnT, e := strconv.Atoi(fresh["turn_time_sec"]); e == nil && turnT > 0 {
			fields = append(fields,
				"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
				"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
				"take_reveal_at", "0",
				"throw_reveal_at", "0",
			)
		}
		h.Rdb.HSet(ctx, "game:"+gameID, fields...)
		h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
		h.promoteDurakFinishedPlayers(ctx, gameID, fresh, state)
		h.broadcastDurakState(ctx, gameID, fresh, state, nil)
		if state.Status == durak.StatusActive && state.Phase == durak.PhaseTakeReveal {
			h.scheduleDurakTakeReveal(gameID, state.ActiveRevealDelay())
		}
		if state.Status == durak.StatusOver {
			if state.LoserIndex < 0 {
				fresh["draw"] = "1"
			}
			h.onDurakGameFinished(ctx, gameID, fresh, state)
		}
		return
	}
	continues := state.Eliminate(timedOutIdx)
	encoded, err := durak.Encode(state)
	if err != nil {
		return
	}
	if continues {
		// Как с forfeit: mid-game вылет по времени не помечает всю партию
		// timeout — иначе победителю в конце покажут «время соперника вышло».
		fields := []any{"state", encoded}
		if turnT, e := strconv.Atoi(fresh["turn_time_sec"]); e == nil && turnT > 0 {
			fields = append(fields,
				"turn_deadline", strconv.FormatInt(time.Now().UTC().Unix()+int64(turnT), 10),
				"turn_actor_idx", strconv.Itoa(durakTurnActorIdx(state)),
			)
		}
		h.Rdb.HSet(ctx, "game:"+gameID, fields...)
		h.Rdb.HDel(ctx, "game:"+gameID, "timeout")
		h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
		if timedOutIdx >= 0 && timedOutIdx < len(state.PlayerIDs) {
			if u, err := uuid.Parse(state.PlayerIDs[timedOutIdx]); err == nil && !isBot(state.PlayerIDs[timedOutIdx]) {
				moveActiveToObserving(ctx, h.Rdb, u, gameID)
			}
		}
		h.broadcastDurakState(ctx, gameID, fresh, state, map[string]any{
			"timeout": true,
		})
		return
	}
	fields := []any{
		"state", encoded,
		"status", durakStatusOver,
		"timeout", "1",
	}
	if state.LoserIndex >= 0 && state.LoserIndex < len(state.PlayerIDs) {
		fields = append(fields, "loser", state.PlayerIDs[state.LoserIndex])
	}
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
	h.broadcastDurakState(ctx, gameID, fresh, state, map[string]any{
		"timeout": true,
		"status":  durakStatusOver,
	})
	h.onDurakGameFinished(ctx, gameID, fresh, state)
}

// onDurakGameFinished — очистка active/observation, ставки, статистика.
func (h *GamesHandler) onDurakGameFinished(ctx context.Context, gameID string, m map[string]string, state *durak.State) {
	humans := durakHumans(m)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	// Очистить чат лобби (multi).
	lobbyID := strings.TrimSpace(m["lobby_id"])
	if lobbyID != "" {
		h.Rdb.Del(ctx, "lobby:"+lobbyID)
		h.forgetLobby(lobbyID)
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
	finishReason := "normal"
	if m["forfeit"] == "1" {
		finishReason = "forfeit"
	} else if m["timeout"] == "1" {
		finishReason = "timeout"
	} else if m["draw"] == "1" || state.LoserIndex < 0 {
		// Ничья по согласию или оба вышли (дурака нет).
		finishReason = "draw"
	}
	h.settleDurakCoins(ctx, gameID, m, state, stakeBronze)
	for _, uid := range humans {
		_ = store.IncrementGamesFinished(ctx, h.Pool, uid)
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, uid)
		notifyAchievementUnlocks(h.Hub, h.Push, uid, unlocked)
	}
	if m["draw"] != "1" && state.LoserIndex >= 0 && state.LoserIndex < len(state.PlayerIDs) {
		for i, pid := range state.PlayerIDs {
			if i == state.LoserIndex || isBot(pid) {
				continue
			}
			if u, err := uuid.Parse(pid); err == nil {
				_ = store.IncrementWinsByStake(ctx, h.Pool, u, stakeBronze)
				unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
				notifyAchievementUnlocks(h.Hub, h.Push, u, unlocked)
			}
		}
	}
	h.recordDurakGameResult(ctx, gameID, m, state, stakeBronze, finishReason)
}

// durakEarlyPaid — сколько уже начислено mid-game за место (early_paid:<userId>).
func (h *GamesHandler) durakEarlyPaid(ctx context.Context, gameID, playerID string) int {
	if h.Rdb == nil || playerID == "" {
		return 0
	}
	v, err := h.Rdb.HGet(ctx, "game:"+gameID, "early_paid:"+playerID).Int()
	if err != nil {
		return 0
	}
	if v < 0 {
		return 0
	}
	return v
}

// durakPayCreditDelta — доплатить credit − early_paid (не списываем лишнее).
func (h *GamesHandler) durakPayCreditDelta(ctx context.Context, gameID, playerID string, credit int) {
	if credit <= 0 || isBot(playerID) || h.Pool == nil {
		return
	}
	u, err := uuid.Parse(playerID)
	if err != nil {
		return
	}
	already := h.durakEarlyPaid(ctx, gameID, playerID)
	delta := credit - already
	if delta <= 0 {
		return
	}
	_ = store.AddCoins(ctx, h.Pool, u, delta)
}

// settleDurakCoins — банк stake×N по местам выхода:
// 3 игрока: 1-е 2/3, 2-е 1/3; 4 игрока: 1-е 2/4, 2-е и 3-е по 1/4; дурак — 0.
// Сдавшиеся долю не получают. 1×1 — весь банк победителю.
// Учитывает mid-game early_paid, чтобы не начислить дважды.
func (h *GamesHandler) settleDurakCoins(ctx context.Context, gameID string, m map[string]string, state *durak.State, stakeBronze int) {
	if stakeBronze <= 0 || h.Pool == nil || h.Rdb == nil {
		return
	}
	// Идемпотентность: GetGame/timeout/forfeit не должны начислить дважды.
	ok, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "coins_settled", "1").Result()
	if err != nil || !ok {
		return
	}
	ids := state.PlayerIDs
	if len(ids) == 0 {
		ids = parsePlayerIDsCSV(m["player_ids"])
	}
	if len(ids) < 2 {
		return
	}
	isDraw := m["draw"] == "1" || state.LoserIndex < 0 || state.LoserIndex >= len(ids)
	if isDraw {
		for _, pid := range ids {
			if isBot(pid) {
				continue
			}
			h.durakPayCreditDelta(ctx, gameID, pid, stakeBronze)
		}
		return
	}
	placeIdx := state.WinnerPlaceOrder()
	if len(placeIdx) == 0 {
		return
	}
	placeIDs := make([]string, 0, len(placeIdx))
	for _, i := range placeIdx {
		if i >= 0 && i < len(ids) {
			placeIDs = append(placeIDs, ids[i])
		}
	}
	if len(placeIDs) == 0 {
		return
	}
	// 1×1 vs бот: человек проиграл — без выплат; победил — банк stake×2.
	if len(ids) == 2 {
		winner := placeIDs[0]
		if isBot(winner) {
			return
		}
		h.durakPayCreditDelta(ctx, gameID, winner, stakeBronze*2)
		return
	}
	pot := stakeBronze * len(ids)
	// Ничья 1–2 (и т.п.): банк за 1/2/3 места делится поровну между лидерами.
	if state.TiedLeaders >= 2 {
		nTied := state.TiedLeaders
		if nTied > len(placeIDs) {
			nTied = len(placeIDs)
		}
		each := pot / nTied
		rem := pot % nTied
		for i := 0; i < nTied; i++ {
			credit := each
			if i == 0 {
				credit += rem
			}
			h.durakPayCreditDelta(ctx, gameID, placeIDs[i], credit)
		}
		return
	}
	nums := durak.PlaceShareNumerators(len(ids))
	if len(nums) == 0 {
		return
	}
	// Как SettleStakePotByShares: лишние доли → 1-му месту.
	shareNums := append([]int(nil), nums...)
	if len(placeIDs) < len(shareNums) {
		extra := 0
		for i := len(placeIDs); i < len(shareNums); i++ {
			extra += shareNums[i]
		}
		shareNums = shareNums[:len(placeIDs)]
		shareNums[0] += extra
	}
	denom := len(ids)
	credits := make([]int, len(placeIDs))
	paidTotal := 0
	for i := range placeIDs {
		if i >= len(shareNums) {
			break
		}
		credits[i] = pot * shareNums[i] / denom
		paidTotal += credits[i]
	}
	// Остаток от целочисленного деления — первому месту (человеку).
	if rem := pot - paidTotal; rem > 0 && len(credits) > 0 {
		for i, pid := range placeIDs {
			if isBot(pid) {
				continue
			}
			credits[i] += rem
			break
		}
	}
	for i, pid := range placeIDs {
		h.durakPayCreditDelta(ctx, gameID, pid, credits[i])
	}
}

func (h *GamesHandler) recordDurakGameResult(ctx context.Context, gameID string, m map[string]string, state *durak.State, stakeBronze int, finishReason string) {
	ids := state.PlayerIDs
	if len(ids) < 2 {
		ids = parsePlayerIDsCSV(m["player_ids"])
	}
	if len(ids) < 2 {
		return
	}
	deck := state.DeckSize
	if deck == 0 {
		deck, _ = strconv.Atoi(m["deck_size"])
	}
	if deck == 0 {
		deck = 36
	}
	mode := fmt.Sprintf("%d:%d", len(ids), deck)
	duration := 0
	if t, ok := parseGameStartedAt(m["started_at"]); ok {
		duration = clampNonNegative(int(time.Since(t).Seconds()))
	}
	var winnerID string
	isDraw := m["draw"] == "1" || state.LoserIndex < 0 || state.LoserIndex >= len(ids)
	if !isDraw && len(ids) == 2 {
		if state.LoserIndex == 0 {
			winnerID = ids[1]
		} else {
			winnerID = ids[0]
		}
	} else if !isDraw {
		places := state.WinnerPlaceOrder()
		if len(places) > 0 && places[0] >= 0 && places[0] < len(ids) {
			winnerID = ids[places[0]]
		}
	}
	write := func(rowID, xID, oID, winID string) {
		result := "draw"
		switch {
		case winID != "" && winID == xID:
			result = "x_won"
		case winID != "" && winID == oID:
			result = "o_won"
		}
		gr := store.GameResult{
			GameID:       rowID,
			GameType:     durakGameType,
			Result:       result,
			FinishReason: finishReason,
			StakeBronze:  stakeBronze,
			DurationSec:  duration,
			AgainstBot:   isBot(xID) || isBot(oID),
			GameMode:     mode,
		}
		if u, err := uuid.Parse(xID); err == nil {
			gr.XUserID = u
		}
		if u, err := uuid.Parse(oID); err == nil {
			gr.OUserID = u
		}
		if winID != "" && !isBot(winID) {
			if w, err := uuid.Parse(winID); err == nil {
				gr.WinnerUserID = &w
			}
		}
		_ = store.RecordGameResult(ctx, h.Pool, gr)
	}
	if len(ids) == 2 {
		write(gameID, ids[0], ids[1], winnerID)
		return
	}
	if winnerID == "" {
		for i := 1; i < len(ids); i++ {
			write(gameID+":"+ids[i], ids[0], ids[i], "")
		}
		return
	}
	for _, id := range ids {
		if id != winnerID {
			write(gameID+":"+id, winnerID, id, winnerID)
		}
	}
}
