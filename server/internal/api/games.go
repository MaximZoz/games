package api

import (
	"context"
	"encoding/json"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

const (
	lobbyStatusWaitingInvite    = "waiting_invite"
	lobbyStatusWaitingMatchmake = "waiting_matchmake"
	lobbyStatusInGame           = "in_game"
	gameStatusActive            = "active"
	gameStatusXWon              = "x_won"
	gameStatusOWon              = "o_won"
	gameStatusDraw              = "draw"
	lobbyTTL                    = 10 * time.Minute
)

// turn_time_sec: 0=unlimited, 10, 30, 60, 600
var validTurnTimeSec = map[int]bool{0: true, 10: true, 30: true, 60: true, 600: true}

// grid_size: 3, 4, 5
var validGridSize = map[int]bool{3: true, 4: true, 5: true}

func matchmakeKey(turnTimeSec, gridSize int) string {
	return "tictactoe:matchmake:" + strconv.Itoa(turnTimeSec) + ":" + strconv.Itoa(gridSize)
}

type GamesHandler struct {
	Pool        *pgxpool.Pool
	Rdb         *redis.Client
	Hub         *RealtimeHub
	Broadcaster *GamesBroadcaster
}

type CreateLobbyBody struct {
	Mode        string `json:"mode"`          // "invite" | "matchmake"
	TurnTimeSec int    `json:"turn_time_sec"` // 0=unlimited, 10, 30, 60, 600
	GridSize    int    `json:"grid_size"`     // 3, 4, 5
}

type InviteBody struct {
	FriendUserID string `json:"friend_user_id"`
}

type MoveBody struct {
	Cell int `json:"cell"` // 0 to N*N-1
}

type LobbyItem struct {
	ID          string  `json:"id"`
	CreatorID   string  `json:"creator_id"`
	CreatorName string  `json:"creator_name,omitempty"`
	OpponentID  *string `json:"opponent_id,omitempty"`
	Status      string  `json:"status"`
	GameID      *string `json:"game_id,omitempty"`
	CreatedAt   string  `json:"created_at"`
	TurnTimeSec int     `json:"turn_time_sec,omitempty"`
	GridSize    int     `json:"grid_size,omitempty"`
}

type GameStateItem struct {
	ID           string   `json:"id"`
	Board        []string `json:"board"` // N*N cells: "", "x", "o"
	GridSize     int      `json:"grid_size,omitempty"`
	Turn         string   `json:"turn"` // "x" | "o"
	Winner       *string  `json:"winner,omitempty"`
	Status       string   `json:"status"`
	Forfeit      bool     `json:"forfeit,omitempty"`
	Timeout      bool     `json:"timeout,omitempty"`
	TurnTimeSec  int      `json:"turn_time_sec,omitempty"`
	TurnDeadline *int64   `json:"turn_deadline,omitempty"` // Unix sec, when current player's turn expires
	WinningCells []int    `json:"winning_cells,omitempty"` // Индексы 3 клеток победной линии
	XUserID      string   `json:"x_user_id"`
	OUserID      string   `json:"o_user_id"`
	XDisplayName *string  `json:"x_display_name,omitempty"`
	ODisplayName *string  `json:"o_display_name,omitempty"`
	XAvatarKind  string   `json:"x_avatar_kind,omitempty"`
	XAvatarValue *string  `json:"x_avatar_value,omitempty"`
	OAvatarKind  string   `json:"o_avatar_kind,omitempty"`
	OAvatarValue *string  `json:"o_avatar_value,omitempty"`
}

func (h *GamesHandler) requireRedis(w http.ResponseWriter) bool {
	if h.Rdb == nil {
		http.Error(w, "games service unavailable (Redis required)", http.StatusServiceUnavailable)
		return false
	}
	return true
}

func (h *GamesHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !h.requireRedis(w) {
		return
	}
	path := strings.TrimPrefix(r.URL.Path, "/api/games/tictactoe/")
	parts := strings.Split(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
		return
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreateLobby(w, r)
		return
	case path == "rematch" && r.Method == http.MethodPost:
		h.Rematch(w, r)
		return
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListLobbies(w, r)
		return
	case len(parts) >= 2 && parts[0] == "lobby":
		lobbyID := parts[1]
		if lobbyID == "" {
			http.Error(w, "lobby id required", http.StatusBadRequest)
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "invite" && r.Method == http.MethodPost:
			h.InviteToLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "join" && r.Method == http.MethodPost:
			h.JoinLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
		return
	case len(parts) >= 2 && parts[0] == "game":
		gameID := parts[1]
		if gameID == "" {
			http.Error(w, "game id required", http.StatusBadRequest)
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
			h.MakeMove(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.ForfeitGame(w, r, gameID)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
		return
	}

	http.Error(w, "not found", http.StatusNotFound)
}

func currentUserIDFromGames(r *http.Request) (uuid.UUID, bool) {
	return GetUserID(r.Context())
}

func (h *GamesHandler) CreateLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body CreateLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	mode := strings.TrimSpace(strings.ToLower(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		http.Error(w, "mode must be invite or matchmake", http.StatusBadRequest)
		return
	}
	turnTimeSec := body.TurnTimeSec
	if !validTurnTimeSec[turnTimeSec] {
		http.Error(w, "turn_time_sec must be 0, 10, 30, 60 or 600", http.StatusBadRequest)
		return
	}
	gridSize := body.GridSize
	if !validGridSize[gridSize] {
		gridSize = 3
	}

	ctx := r.Context()

	if mode == "matchmake" {
		otherEntry, err := h.rdbRPOPMatchmake(ctx, turnTimeSec, gridSize)
		if err == nil && otherEntry != "" {
			parts := strings.SplitN(otherEntry, ":", 2)
			otherUserID := parts[0]
			otherLobbyID := ""
			if len(parts) > 1 {
				otherLobbyID = parts[1]
			}
			otherUUID, err := uuid.Parse(otherUserID)
			if err == nil && otherUUID != userID {
				if otherLobbyID != "" {
					h.Rdb.Del(ctx, "lobby:"+otherLobbyID)
				}
				gameID, lobbyID, err := h.createGameFromMatch(ctx, userID, otherUUID, turnTimeSec, gridSize)
				if err != nil {
					http.Error(w, "server error", http.StatusInternalServerError)
					return
				}
				clearUserActiveLobby(ctx, h.Rdb, userID)
				clearUserActiveLobby(ctx, h.Rdb, otherUUID)
				setUserActiveGame(ctx, h.Rdb, userID, gameID)
				setUserActiveGame(ctx, h.Rdb, otherUUID, gameID)
				h.publishGameStarted([]uuid.UUID{userID, otherUUID}, gameID, lobbyID)
				writeJSON(w, http.StatusOK, map[string]any{
					"lobby_id": lobbyID,
					"game_id":  gameID,
					"matched":  true,
				})
				return
			}
		}
	}

	lobbyID := uuid.New().String()
	status := lobbyStatusWaitingInvite
	if mode == "matchmake" {
		status = lobbyStatusWaitingMatchmake
	}

	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", "tictactoe",
		"creator_id", userID.String(),
		"status", status,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if mode == "matchmake" {
		mmKey := matchmakeKey(turnTimeSec, gridSize)
		pipe.LPush(ctx, mmKey, userID.String()+":"+lobbyID)
		pipe.Expire(ctx, mmKey, 5*time.Minute)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id":   lobbyID,
		"status":     status,
		"created_at": now,
		"creator_id": userID.String(),
	})
}

type RematchBody struct {
	GameID string `json:"game_id"`
}

func (h *GamesHandler) Rematch(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body RematchBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	gameID := strings.TrimSpace(body.GameID)
	if gameID == "" {
		http.Error(w, "game_id required", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	gameKey := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, gameKey).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}

	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if xUserID != userID.String() && oUserID != userID.String() {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	status := m["status"]
	if status == gameStatusActive {
		http.Error(w, "game is not over", http.StatusBadRequest)
		return
	}

	opponentID := oUserID
	if userID.String() == oUserID {
		opponentID = xUserID
	}
	opponentUUID, err := uuid.Parse(opponentID)
	if err != nil {
		http.Error(w, "invalid opponent", http.StatusInternalServerError)
		return
	}

	// Всегда создаём лобби и отправляем приглашение. Игра начнётся только после
	// явного принятия соперником (JoinLobby). Нет автоприсоединения — согласие
	// обнуляется после каждой игры, второй игрок должен подтвердить реванш.
	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	invitedKey := key + ":invited"
	now := time.Now().UTC().Format(time.RFC3339Nano)
	turnTimeSec := 0
	gridSize := 3
	if tt := m["turn_time_sec"]; tt != "" {
		if n, e := strconv.Atoi(tt); e == nil && validTurnTimeSec[n] {
			turnTimeSec = n
		}
	}
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", "tictactoe",
		"creator_id", userID.String(),
		"status", lobbyStatusWaitingInvite,
		"invite_target_id", opponentID,
		"created_at", now,
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	pipe.SAdd(ctx, invitedKey, opponentID)
	pipe.Expire(ctx, invitedKey, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	creator, _ := store.GetUserByID(ctx, h.Pool, userID)
	creatorName := "Игрок"
	if creator != nil && creator.DisplayName != nil && *creator.DisplayName != "" {
		creatorName = *creator.DisplayName
	}
	h.broadcast([]uuid.UUID{opponentUUID}, map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    userID.String(),
		"creator_name":  creatorName,
		"game_type":     "tictactoe",
		"turn_time_sec": turnTimeSec,
		"grid_size":     gridSize,
	})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

func (h *GamesHandler) rdbRPOPMatchmake(ctx context.Context, turnTimeSec, gridSize int) (string, error) {
	return h.Rdb.RPop(ctx, matchmakeKey(turnTimeSec, gridSize)).Result()
}

func emptyBoardJSON(gridSize int) string {
	n := gridSize * gridSize
	if n <= 0 || n > 25 {
		n = 9
	}
	b := make([]string, n)
	for i := range b {
		b[i] = ""
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

func (h *GamesHandler) createGameFromMatch(ctx context.Context, user1, user2 uuid.UUID, turnTimeSec, gridSize int) (gameID, lobbyID string, err error) {
	gameID = uuid.New().String()
	lobbyID = uuid.New().String()

	xUserID := user1.String()
	oUserID := user2.String()
	if rand.Intn(2) == 1 {
		xUserID, oUserID = oUserID, xUserID
	}

	board := emptyBoardJSON(gridSize)
	key := "game:" + gameID
	lobbyKey := "lobby:" + lobbyID

	pipe := h.Rdb.Pipeline()
	gameFields := []any{
		"board", board,
		"turn", "x",
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"x_user_id", xUserID,
		"o_user_id", oUserID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, key, gameFields...)
	pipe.Expire(ctx, key, 24*time.Hour)

	pipe.HSet(ctx, lobbyKey,
		"game_type", "tictactoe",
		"creator_id", user1.String(),
		"opponent_id", user2.String(),
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"created_at", time.Now().UTC().Format(time.RFC3339Nano),
		"mode", "matchmake",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
	)
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)

	_, err = pipe.Exec(ctx)
	return gameID, lobbyID, err
}

func (h *GamesHandler) ListLobbies(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	keys, err := h.Rdb.Keys(ctx, "lobby:*").Result()
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	var lobbies []LobbyItem
	for _, key := range keys {
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["status"] != lobbyStatusWaitingMatchmake {
			continue
		}
		creatorID := m["creator_id"]
		if creatorID == userID.String() {
			continue
		}
		creatorName := "Игрок"
		if creatorUUID, err := uuid.Parse(creatorID); err == nil {
			if creator, _ := store.GetUserByID(ctx, h.Pool, creatorUUID); creator != nil && creator.DisplayName != nil && *creator.DisplayName != "" {
				creatorName = *creator.DisplayName
			}
		}
		id := strings.TrimPrefix(key, "lobby:")
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		gridSize, _ := strconv.Atoi(m["grid_size"])
		if !validGridSize[gridSize] {
			gridSize = 3
		}
		lobbies = append(lobbies, LobbyItem{
			ID:          id,
			CreatorID:   creatorID,
			CreatorName: creatorName,
			Status:      m["status"],
			CreatedAt:   m["created_at"],
			TurnTimeSec: turnTimeSec,
			GridSize:    gridSize,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"lobbies": lobbies})
}

func (h *GamesHandler) GetLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	creatorID := m["creator_id"]
	opponentID := m["opponent_id"]
	gameID := m["game_id"]
	status := m["status"]

	if creatorID != userID.String() && opponentID != userID.String() {
		if status != lobbyStatusWaitingMatchmake {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
	}

	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}
	item := LobbyItem{
		ID:          lobbyID,
		CreatorID:   creatorID,
		Status:      status,
		CreatedAt:   m["created_at"],
		TurnTimeSec: turnTimeSec,
		GridSize:    gridSize,
	}
	if opponentID != "" {
		item.OpponentID = &opponentID
	}
	if gameID != "" {
		item.GameID = &gameID
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(item)
}

func (h *GamesHandler) InviteToLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body InviteBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	friendID, err := uuid.Parse(strings.TrimSpace(body.FriendUserID))
	if err != nil {
		http.Error(w, "invalid friend_user_id", http.StatusBadRequest)
		return
	}
	if friendID == userID {
		http.Error(w, "cannot invite yourself", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if m["creator_id"] != userID.String() {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if m["status"] != lobbyStatusWaitingInvite {
		http.Error(w, "lobby not in invite mode", http.StatusBadRequest)
		return
	}

	friends, err := store.ListFriendships(ctx, h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	var isFriend bool
	for _, f := range friends {
		if f.User.ID == friendID {
			isFriend = true
			break
		}
	}
	if !isFriend {
		http.Error(w, "user is not your friend", http.StatusForbidden)
		return
	}

	invitedKey := key + ":invited"
	h.Rdb.SAdd(ctx, invitedKey, friendID.String())
	h.Rdb.Expire(ctx, invitedKey, lobbyTTL)
	h.Rdb.HSet(ctx, key, "invite_target_id", friendID.String())
	h.Rdb.Expire(ctx, key, lobbyTTL)

	creator, _ := store.GetUserByID(ctx, h.Pool, userID)
	creatorName := "Игрок"
	if creator != nil && creator.DisplayName != nil && *creator.DisplayName != "" {
		creatorName = *creator.DisplayName
	}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}

	h.broadcast([]uuid.UUID{friendID}, map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    userID.String(),
		"creator_name":  creatorName,
		"game_type":     "tictactoe",
		"turn_time_sec": turnTimeSec,
		"grid_size":     gridSize,
	})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"invited": true})
}

func (h *GamesHandler) JoinLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	creatorID := m["creator_id"]
	status := m["status"]
	inviteTarget := m["invite_target_id"]
	invitedKey := key + ":invited"

	if status == lobbyStatusInGame {
		http.Error(w, "игра уже началась с другим соперником", http.StatusConflict)
		return
	}

	creatorUUID, _ := uuid.Parse(creatorID)

	// При одновременном реванше оба нажимают «Принять» — блокировка, чтобы создать только одну игру.
	if status == lobbyStatusWaitingInvite {
		lockKey := "rematch_lock:" + minUUID(creatorUUID, userID) + ":" + maxUUID(creatorUUID, userID)
		ok, _ := h.Rdb.SetNX(ctx, lockKey, "1", 15*time.Second).Result()
		if !ok {
			time.Sleep(300 * time.Millisecond)
			for _, u := range []uuid.UUID{creatorUUID, userID} {
				if gid, _ := h.Rdb.Get(ctx, userActiveGameKey(u)).Result(); gid != "" {
					if gm, _ := h.Rdb.HGet(ctx, "game:"+gid, "status").Result(); gm == gameStatusActive {
						http.Error(w, "у вас или соперника уже есть активная игра", http.StatusConflict)
						return
					}
				}
			}
			http.Error(w, "игра уже создана, обновите страницу", http.StatusConflict)
			return
		}
		defer h.Rdb.Del(ctx, lockKey)
	}

	if status == lobbyStatusWaitingInvite {
		okInv, _ := h.Rdb.SIsMember(ctx, invitedKey, userID.String()).Result()
		if !okInv && inviteTarget != userID.String() {
			http.Error(w, "you are not invited", http.StatusForbidden)
			return
		}
	} else if status == lobbyStatusWaitingMatchmake {
		if creatorID == userID.String() {
			http.Error(w, "cannot join own lobby", http.StatusBadRequest)
			return
		}
	}

	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}

	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	xUserID := creatorID
	oUserID := userID.String()
	if rand.Intn(2) == 1 {
		xUserID, oUserID = oUserID, xUserID
	}
	board := emptyBoardJSON(gridSize)

	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key, "opponent_id", userID.String(), "status", lobbyStatusInGame, "game_id", gameID)
	pipe.Expire(ctx, key, 24*time.Hour)
	if status == lobbyStatusWaitingMatchmake {
		pipe.LRem(ctx, matchmakeKey(turnTimeSec, gridSize), 0, creatorID+":"+lobbyID)
	}

	gameFields := []any{
		"board", board,
		"turn", "x",
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"x_user_id", xUserID,
		"o_user_id", oUserID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, gameKey, gameFields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)

	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	clearUserActiveLobby(ctx, h.Rdb, creatorUUID)
	clearUserActiveLobby(ctx, h.Rdb, userID)
	setUserActiveGame(ctx, h.Rdb, creatorUUID, gameID)
	setUserActiveGame(ctx, h.Rdb, userID, gameID)

	// Удалить «обратное» лобби (joiner создал своё, invite_target=creator), чтобы второй запрос получил 404
	if status == lobbyStatusWaitingInvite {
		keys, _ := h.Rdb.Keys(ctx, "lobby:*").Result()
		for _, k := range keys {
			lm, _ := h.Rdb.HGetAll(ctx, k).Result()
			if lm["creator_id"] == userID.String() && lm["invite_target_id"] == creatorID && lm["status"] == lobbyStatusWaitingInvite {
				h.Rdb.Del(ctx, k)
				h.Rdb.Del(ctx, k+":invited")
				break
			}
		}
	}

	h.broadcast([]uuid.UUID{creatorUUID, userID}, map[string]any{
		"type":        "lobby_updated",
		"lobby_id":    lobbyID,
		"game_id":     gameID,
		"opponent_id": userID.String(),
	})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"joined":  true,
		"game_id": gameID,
		"status":  lobbyStatusInGame,
	})
}

func (h *GamesHandler) LeaveLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	creatorID := m["creator_id"]
	opponentID := m["opponent_id"]
	status := m["status"]

	if status == lobbyStatusInGame {
		http.Error(w, "game already started", http.StatusBadRequest)
		return
	}

	if creatorID != userID.String() && opponentID != userID.String() {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	otherUserID := creatorID
	if creatorID == userID.String() {
		otherUserID = opponentID
	}
	// Для invite-лобби opponent_id пуст, уведомляем invite_target
	if otherUserID == "" && status == lobbyStatusWaitingInvite {
		otherUserID = m["invite_target_id"]
	}
	if otherUserID != "" {
		otherUUID, err := uuid.Parse(otherUserID)
		if err == nil {
			h.broadcast([]uuid.UUID{otherUUID}, map[string]any{
				"type":     "lobby_updated",
				"lobby_id": lobbyID,
				"left":     true,
			})
		}
	}

	clearUserActiveLobby(ctx, h.Rdb, userID)
	h.Rdb.Del(ctx, key)
	if status == lobbyStatusWaitingMatchmake {
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		gridSize, _ := strconv.Atoi(m["grid_size"])
		if !validGridSize[gridSize] {
			gridSize = 3
		}
		h.Rdb.LRem(ctx, matchmakeKey(turnTimeSec, gridSize), 0, userID.String()+":"+lobbyID)
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"left": true})
}

func (h *GamesHandler) DeclineInvite(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	if m["status"] != lobbyStatusWaitingInvite {
		http.Error(w, "lobby invite expired", http.StatusBadRequest)
		return
	}
	if m["invite_target_id"] != userID.String() {
		http.Error(w, "you are not invited", http.StatusForbidden)
		return
	}

	creatorID := m["creator_id"]
	creatorUUID, _ := uuid.Parse(creatorID)
	h.Rdb.Del(ctx, key)
	clearUserActiveLobby(ctx, h.Rdb, userID)

	h.broadcast([]uuid.UUID{creatorUUID}, map[string]any{
		"type":     "invite_declined",
		"lobby_id": lobbyID,
	})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"declined": true})
}

// applyGameTimeout checks if turn_deadline passed; if so, current turn player loses (timeout). Returns true if applied.
func (h *GamesHandler) applyGameTimeout(ctx context.Context, key string, m map[string]string) bool {
	if m["status"] != gameStatusActive {
		return false
	}
	dl := m["turn_deadline"]
	if dl == "" {
		return false
	}
	deadline, err := strconv.ParseInt(dl, 10, 64)
	if err != nil || time.Now().UTC().Unix() <= deadline {
		return false
	}
	turn := m["turn"]
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	winner := "o"
	if turn == "o" {
		winner = "x"
	}
	status := gameStatusOWon
	if winner == "x" {
		status = gameStatusXWon
	}
	h.Rdb.HSet(ctx, key, "status", status, "winner", winner, "timeout", "1")
	h.Rdb.Expire(ctx, key, 24*time.Hour)
	xUUID, _ := uuid.Parse(xUserID)
	oUUID, _ := uuid.Parse(oUserID)
	clearUserActiveGame(ctx, h.Rdb, xUUID)
	clearUserActiveGame(ctx, h.Rdb, oUUID)
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	h.broadcast([]uuid.UUID{xUUID, oUUID}, map[string]any{
		"type": "game_state", "game_id": strings.TrimPrefix(key, "game:"),
		"board": board, "turn": turn, "winner": winner, "status": status, "timeout": true,
	})
	return true
}

func (h *GamesHandler) GetGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}
	if h.applyGameTimeout(ctx, key, m) {
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
	}

	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if xUserID != userID.String() && oUserID != userID.String() {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	item := GameStateItem{
		ID:       gameID,
		Board:    board,
		Turn:     m["turn"],
		Status:   m["status"],
		GridSize: gridSize,
		XUserID:  xUserID,
		OUserID:  oUserID,
		Forfeit:  m["forfeit"] == "1",
		Timeout:  m["timeout"] == "1",
	}
	if w := m["winner"]; w != "" {
		item.Winner = &w
		if line := checkWinLine(board, w, gridSize); len(line) == 3 {
			item.WinningCells = line
		}
	}
	if tt, _ := strconv.Atoi(m["turn_time_sec"]); tt > 0 {
		item.TurnTimeSec = tt
	}
	if dl := m["turn_deadline"]; dl != "" {
		if d, e := strconv.ParseInt(dl, 10, 64); e == nil {
			item.TurnDeadline = &d
		}
	}

	xUUID, _ := uuid.Parse(xUserID)
	oUUID, _ := uuid.Parse(oUserID)
	if xu, err := store.GetUserByID(ctx, h.Pool, xUUID); err == nil {
		if xu.DisplayName != nil && *xu.DisplayName != "" {
			item.XDisplayName = xu.DisplayName
		}
		item.XAvatarKind = xu.AvatarKind
		item.XAvatarValue = xu.AvatarValue
	}
	if ou, err := store.GetUserByID(ctx, h.Pool, oUUID); err == nil {
		if ou.DisplayName != nil && *ou.DisplayName != "" {
			item.ODisplayName = ou.DisplayName
		}
		item.OAvatarKind = ou.AvatarKind
		item.OAvatarValue = ou.AvatarValue
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(item)
}

func (h *GamesHandler) MakeMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body MoveBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	maxCell := gridSize*gridSize - 1
	if body.Cell < 0 || body.Cell > maxCell {
		http.Error(w, "cell must be 0-"+strconv.Itoa(maxCell), http.StatusBadRequest)
		return
	}
	if h.applyGameTimeout(ctx, key, m) {
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
		gridSize := 3
		if gs := m["grid_size"]; gs != "" {
			if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
				gridSize = n
			}
		}
		board := parseBoard(m["board"], gridSize)
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"game_id": gameID, "board": board,
			"turn": m["turn"], "winner": m["winner"], "status": m["status"],
			"timeout": true,
		})
		return
	}

	if m["status"] != gameStatusActive {
		http.Error(w, "game is over", http.StatusBadRequest)
		return
	}

	turn := m["turn"]
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if (turn == "x" && xUserID != userID.String()) || (turn == "o" && oUserID != userID.String()) {
		http.Error(w, "not your turn", http.StatusBadRequest)
		return
	}

	board := parseBoard(m["board"], gridSize)
	if board[body.Cell] != "" {
		http.Error(w, "cell already taken", http.StatusBadRequest)
		return
	}

	board[body.Cell] = turn
	nextTurn := "o"
	if turn == "o" {
		nextTurn = "x"
	}
	newBoard := formatBoard(board)
	status := gameStatusActive
	winner := turn

	winningCells := checkWinLine(board, turn, gridSize)
	if len(winningCells) == 3 {
		status = gameStatusXWon
		if turn == "o" {
			status = gameStatusOWon
		}
	} else if isDraw(board, gridSize) {
		status = gameStatusDraw
		winner = ""
	} else {
		winner = ""
	}

	pipe := h.Rdb.Pipeline()
	setFields := []any{"board", newBoard, "turn", nextTurn, "status", status}
	if winner != "" {
		setFields = append(setFields, "winner", turn)
	}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	if turnTimeSec > 0 && status == gameStatusActive {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		setFields = append(setFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	} else if turnTimeSec > 0 && status != gameStatusActive {
		pipe.HDel(ctx, key, "turn_deadline")
	}
	pipe.HSet(ctx, key, setFields...)
	pipe.Expire(ctx, key, 24*time.Hour)

	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	if status != gameStatusActive {
		xUUID, _ := uuid.Parse(xUserID)
		oUUID, _ := uuid.Parse(oUserID)
		clearUserActiveGame(ctx, h.Rdb, xUUID)
		clearUserActiveGame(ctx, h.Rdb, oUUID)
	}

	opponentID := xUserID
	if userID.String() == xUserID {
		opponentID = oUserID
	}
	opponentUUID, _ := uuid.Parse(opponentID)
	winnerVal := winner
	if winner != "" {
		winnerVal = turn
	}
	broadcastPayload := map[string]any{
		"type": "game_state", "game_id": gameID,
		"board": board, "turn": nextTurn, "winner": winnerVal, "status": status,
	}
	if len(winningCells) == 3 {
		broadcastPayload["winning_cells"] = winningCells
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		broadcastPayload["turn_deadline"] = deadline
		broadcastPayload["turn_time_sec"] = turnTimeSec
	}
	h.broadcast([]uuid.UUID{userID, opponentUUID}, broadcastPayload)

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"game_id":   gameID,
		"board":     board,
		"turn":      nextTurn,
		"winner":    winner,
		"status":    status,
		"grid_size": gridSize,
		"x_user_id": xUserID,
		"o_user_id": oUserID,
	}
	if len(winningCells) == 3 {
		resp["winning_cells"] = winningCells
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		resp["turn_time_sec"] = turnTimeSec
		resp["turn_deadline"] = time.Now().UTC().Unix() + int64(turnTimeSec)
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *GamesHandler) ForfeitGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if xUserID != userID.String() && oUserID != userID.String() {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if m["status"] != gameStatusActive {
		http.Error(w, "game is over", http.StatusBadRequest)
		return
	}
	// Сдавшийся проигрывает — побеждает соперник.
	status := gameStatusOWon // X сдался → O победил
	if userID.String() == oUserID {
		status = gameStatusXWon // O сдался → X победил
	}
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key, "status", status, "forfeit", "1")
	pipe.Expire(ctx, key, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	xUUID, _ := uuid.Parse(xUserID)
	oUUID, _ := uuid.Parse(oUserID)
	clearUserActiveGame(ctx, h.Rdb, xUUID)
	clearUserActiveGame(ctx, h.Rdb, oUUID)
	winnerVal := "o"
	if status == gameStatusXWon {
		winnerVal = "x"
	}
	h.broadcast([]uuid.UUID{xUUID, oUUID}, map[string]any{
		"type":    "game_state",
		"game_id": gameID,
		"board":   board,
		"turn":    m["turn"],
		"winner":  winnerVal,
		"status":  status,
		"forfeit": true,
	})
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"status": status, "forfeit": true})
}

func (h *GamesHandler) publishGameStarted(userIDs []uuid.UUID, gameID, lobbyID string) {
	h.broadcast(userIDs, map[string]any{
		"type":     "game_started",
		"game_id":  gameID,
		"lobby_id": lobbyID,
	})
}

func (h *GamesHandler) broadcast(userIDs []uuid.UUID, payload map[string]any) {
	if h.Broadcaster != nil && h.Broadcaster.Rdb != nil {
		h.Broadcaster.Publish(userIDs, payload)
	} else if h.Hub != nil {
		h.Hub.PublishToUsers(userIDs, payload)
	}
}

func userActiveGameKey(userID uuid.UUID) string  { return "user:" + userID.String() + ":active_game" }
func userActiveLobbyKey(userID uuid.UUID) string { return "user:" + userID.String() + ":active_lobby" }

func setUserActiveGame(ctx context.Context, rdb *redis.Client, userID uuid.UUID, gameID string) {
	if rdb == nil {
		return
	}
	rdb.Set(ctx, userActiveGameKey(userID), gameID, 24*time.Hour)
}
func clearUserActiveGame(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if rdb == nil {
		return
	}
	rdb.Del(ctx, userActiveGameKey(userID))
}
func setUserActiveLobby(ctx context.Context, rdb *redis.Client, userID uuid.UUID, lobbyID string) {
	if rdb == nil {
		return
	}
	rdb.Set(ctx, userActiveLobbyKey(userID), lobbyID, lobbyTTL)
}
func clearUserActiveLobby(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if rdb == nil {
		return
	}
	rdb.Del(ctx, userActiveLobbyKey(userID))
}

func (h *GamesHandler) GetActive(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ctx := r.Context()

	gameID, err := h.Rdb.Get(ctx, userActiveGameKey(userID)).Result()
	if err == nil && gameID != "" {
		m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		if err == nil && len(m) > 0 && m["status"] == gameStatusActive {
			isMyTurn := (m["turn"] == "x" && m["x_user_id"] == userID.String()) ||
				(m["turn"] == "o" && m["o_user_id"] == userID.String())
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"type":       "game",
				"game_id":    gameID,
				"is_my_turn": isMyTurn,
			})
			return
		}
		clearUserActiveGame(ctx, h.Rdb, userID)
	}

	lobbyID, err := h.Rdb.Get(ctx, userActiveLobbyKey(userID)).Result()
	if err == nil && lobbyID != "" {
		_, err := h.Rdb.HGetAll(ctx, "lobby:"+lobbyID).Result()
		if err == nil {
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"type":     "lobby",
				"lobby_id": lobbyID,
			})
			return
		}
		clearUserActiveLobby(ctx, h.Rdb, userID)
	}

	w.WriteHeader(http.StatusNoContent)
}

func minUUID(a, b uuid.UUID) string {
	if a.String() < b.String() {
		return a.String()
	}
	return b.String()
}

func maxUUID(a, b uuid.UUID) string {
	if a.String() > b.String() {
		return a.String()
	}
	return b.String()
}

func parseBoard(s string, gridSize int) []string {
	var b []string
	_ = json.Unmarshal([]byte(s), &b)
	n := gridSize * gridSize
	if n <= 0 || n > 25 {
		n = 9
	}
	if len(b) != n {
		return make([]string, n)
	}
	return b
}

func formatBoard(b []string) string {
	if len(b) == 0 {
		b = make([]string, 9)
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

// checkWin: классические правила — 3 в ряд (горизонталь, вертикаль, диагональ) для любого размера поля.
func checkWin(board []string, mark string, gridSize int) bool {
	return len(checkWinLine(board, mark, gridSize)) == 3
}

// checkWinLine возвращает индексы 3 клеток победной линии или nil.
func checkWinLine(board []string, mark string, gridSize int) []int {
	n := gridSize * gridSize
	if len(board) < n {
		return nil
	}
	// Горизонтали
	for row := 0; row < gridSize; row++ {
		for col := 0; col <= gridSize-3; col++ {
			i := row*gridSize + col
			if board[i] == mark && board[i+1] == mark && board[i+2] == mark {
				return []int{i, i + 1, i + 2}
			}
		}
	}
	// Вертикали
	for col := 0; col < gridSize; col++ {
		for row := 0; row <= gridSize-3; row++ {
			i := row*gridSize + col
			if board[i] == mark && board[i+gridSize] == mark && board[i+2*gridSize] == mark {
				return []int{i, i + gridSize, i + 2*gridSize}
			}
		}
	}
	// Диагональ \
	for row := 0; row <= gridSize-3; row++ {
		for col := 0; col <= gridSize-3; col++ {
			i := row*gridSize + col
			if board[i] == mark && board[i+gridSize+1] == mark && board[i+2*(gridSize+1)] == mark {
				return []int{i, i + gridSize + 1, i + 2*(gridSize+1)}
			}
		}
	}
	// Диагональ /
	for row := 0; row <= gridSize-3; row++ {
		for col := 2; col < gridSize; col++ {
			i := row*gridSize + col
			if board[i] == mark && board[i+gridSize-1] == mark && board[i+2*(gridSize-1)] == mark {
				return []int{i, i + gridSize - 1, i + 2*(gridSize-1)}
			}
		}
	}
	return nil
}

func isDraw(board []string, gridSize int) bool {
	n := gridSize * gridSize
	if len(board) < n {
		return false
	}
	for _, c := range board {
		if c == "" {
			return false
		}
	}
	return true
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
