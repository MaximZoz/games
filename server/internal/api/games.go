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
	botUserID                   = "bot:ttt"
	botTimeoutSeconds           = 30
)

// turn_time_sec: 0=unlimited, 10, 30, 60, 600
var validTurnTimeSec = map[int]bool{0: true, 10: true, 30: true, 60: true, 600: true}

// grid_size: 3, 4, 5, 6, 7, 8
var validGridSize = map[int]bool{3: true, 4: true, 5: true, 6: true, 7: true, 8: true}

func matchmakeKey(turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) string {
	sr := "0"
	if swapRule {
		sr = "1"
	}
	fmr := "0"
	if firstMoveRestriction {
		fmr = "1"
	}
	return "tictactoe:matchmake:" + strconv.Itoa(turnTimeSec) + ":" + strconv.Itoa(gridSize) + ":" + sr + ":" + fmr + ":" + strconv.Itoa(stakeBronze)
}

type GamesHandler struct {
	Pool        *pgxpool.Pool
	Rdb         *redis.Client
	Hub         *RealtimeHub
	Broadcaster *GamesBroadcaster
}

type CreateLobbyBody struct {
	Mode                 string `json:"mode"`                   // "invite" | "matchmake"
	TurnTimeSec          int    `json:"turn_time_sec"`          // 0=unlimited, 10, 30, 60, 600
	GridSize             int    `json:"grid_size"`              // 3, 4, 5
	SwapRule             bool   `json:"swap_rule"`              // смена сторон после 1-го хода
	FirstMoveRestriction bool   `json:"first_move_restriction"` // первый ход не в центр
	StakeBronze          int    `json:"stake_bronze"`           // ставка в бронзовых (мин 1)
	AddBotsAfter30s      bool   `json:"add_bots_after_30s"`     // в matchmake: через 30 с добавить бота
}

type InviteBody struct {
	FriendUserID string `json:"friend_user_id"`
}

type MoveBody struct {
	Cell int `json:"cell"` // 0 to N*N-1
}

type LobbyItem struct {
	ID                   string  `json:"id"`
	CreatorID            string  `json:"creator_id"`
	CreatorName          string  `json:"creator_name,omitempty"`
	OpponentID           *string `json:"opponent_id,omitempty"`
	Status               string  `json:"status"`
	GameID               *string `json:"game_id,omitempty"`
	CreatedAt            string  `json:"created_at"`
	TurnTimeSec          int     `json:"turn_time_sec,omitempty"`
	GridSize             int     `json:"grid_size,omitempty"`
	SwapRule             bool    `json:"swap_rule,omitempty"`
	FirstMoveRestriction bool    `json:"first_move_restriction,omitempty"`
	StakeBronze          int     `json:"stake_bronze,omitempty"`
}

type GameStateItem struct {
	ID                   string   `json:"id"`
	Board                []string `json:"board"` // N*N cells: "", "x", "o"
	GridSize             int      `json:"grid_size,omitempty"`
	Turn                 string   `json:"turn"` // "x" | "o"
	Winner               *string  `json:"winner,omitempty"`
	Status               string   `json:"status"`
	Forfeit              bool     `json:"forfeit,omitempty"`
	Timeout              bool     `json:"timeout,omitempty"`
	TurnTimeSec          int      `json:"turn_time_sec,omitempty"`
	TurnDeadline         *int64   `json:"turn_deadline,omitempty"`
	WinningCells         []int    `json:"winning_cells,omitempty"`
	XUserID              string   `json:"x_user_id"`
	OUserID              string   `json:"o_user_id"`
	SwapRule             bool     `json:"swap_rule,omitempty"`
	FirstMoveRestriction bool     `json:"first_move_restriction,omitempty"`
	CanSwap              bool     `json:"can_swap,omitempty"` // O может сменить стороны
	StakeBronze          int      `json:"stake_bronze,omitempty"`
	XDisplayName         *string  `json:"x_display_name,omitempty"`
	ODisplayName         *string  `json:"o_display_name,omitempty"`
	XAvatarKind          string   `json:"x_avatar_kind,omitempty"`
	XAvatarValue         *string  `json:"x_avatar_value,omitempty"`
	XFrameColor          string   `json:"x_frame_color,omitempty"`
	XFrameCode           string   `json:"x_frame_code,omitempty"`
	OAvatarKind          string   `json:"o_avatar_kind,omitempty"`
	OAvatarValue         *string  `json:"o_avatar_value,omitempty"`
	OFrameColor          string   `json:"o_frame_color,omitempty"`
	OFrameCode           string   `json:"o_frame_code,omitempty"`
}

type gameUserLookup func(context.Context, uuid.UUID) (*store.User, error)

func addGamePlayerMetadata(ctx context.Context, payload map[string]any, xUserID, oUserID string, lookup gameUserLookup) {
	addPlayerMetadata := func(side, userID string) {
		if isBot(userID) {
			payload[side+"_display_name"] = "Бот"
			return
		}
		userUUID, err := uuid.Parse(userID)
		if err != nil {
			return
		}
		user, err := lookup(ctx, userUUID)
		if err != nil || user == nil {
			return
		}
		if user.DisplayName != nil && *user.DisplayName != "" {
			payload[side+"_display_name"] = *user.DisplayName
		}
		if user.AvatarKind != "" {
			payload[side+"_avatar_kind"] = user.AvatarKind
		}
		if user.AvatarValue != nil {
			payload[side+"_avatar_value"] = *user.AvatarValue
		}
	}

	addPlayerMetadata("x", xUserID)
	addPlayerMetadata("o", oUserID)
}

func (h *GamesHandler) addGamePlayerMetadata(ctx context.Context, payload map[string]any, xUserID, oUserID string) {
	addGamePlayerMetadata(ctx, payload, xUserID, oUserID, func(ctx context.Context, userID uuid.UUID) (*store.User, error) {
		return store.GetUserByID(ctx, h.Pool, userID)
	})
	h.addGamePlayerFrames(ctx, payload, xUserID, oUserID)
}

func (h *GamesHandler) addGamePlayerFrames(ctx context.Context, payload map[string]any, xUserID, oUserID string) {
	ids := make([]uuid.UUID, 0, 2)
	var xID, oID uuid.UUID
	var xOK, oOK bool
	if !isBot(xUserID) {
		if id, err := uuid.Parse(xUserID); err == nil {
			xID, xOK = id, true
			ids = append(ids, id)
		}
	}
	if !isBot(oUserID) {
		if id, err := uuid.Parse(oUserID); err == nil {
			oID, oOK = id, true
			ids = append(ids, id)
		}
	}
	if len(ids) == 0 {
		return
	}
	frames, err := store.EquippedFramesMap(ctx, h.Pool, ids)
	if err != nil {
		return
	}
	if xOK {
		if f, ok := frames[xID]; ok {
			payload["x_frame_color"] = f.Color
			payload["x_frame_code"] = f.Code
		}
	}
	if oOK {
		if f, ok := frames[oID]; ok {
			payload["o_frame_color"] = f.Color
			payload["o_frame_code"] = f.Code
		}
	}
}

func (h *GamesHandler) requireRedis(w http.ResponseWriter) bool {
	if h.Rdb == nil {
		http.Error(w, "games service unavailable (Redis required)", http.StatusServiceUnavailable)
		return false
	}
	return true
}

func (h *GamesHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Настройки создания игры живут в Postgres и не зависят от Redis.
	if r.URL.Path == "/api/games/settings" {
		h.GameSettings(w, r)
		return
	}
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
		case len(parts) == 3 && parts[2] == "swap" && r.Method == http.MethodPost:
			h.SwapSides(w, r, gameID)
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
	stakeBronze := body.StakeBronze
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	ctx := r.Context()
	mayStake, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if !mayStake {
		http.Error(w, "stake not unlocked", http.StatusForbidden)
		return
	}
	balance, err := store.GetBalance(ctx, h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if balance < stakeBronze {
		http.Error(w, "insufficient balance", http.StatusPaymentRequired)
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
	swapRule := body.SwapRule
	firstMoveRestriction := body.FirstMoveRestriction
	addBotsAfter30s := body.AddBotsAfter30s

	if mode == "matchmake" {
		otherEntry, err := h.rdbRPOPMatchmake(ctx, turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)
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
				gameID, lobbyID, err := h.createGameFromMatch(ctx, userID, otherUUID, turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)
				if err != nil {
					if err == store.ErrStakeNotAllowed {
						http.Error(w, "stake not unlocked", http.StatusForbidden)
						return
					}
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
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"add_bots_after_30s", strconv.FormatBool(addBotsAfter30s),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if mode == "matchmake" {
		mmKey := matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)
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
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction := m["first_move_restriction"] == "true"
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
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
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
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
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
	broadcastData := map[string]any{
		"type":                   "game_invite",
		"lobby_id":               lobbyID,
		"creator_id":             userID.String(),
		"creator_name":           creatorName,
		"game_type":              "tictactoe",
		"turn_time_sec":          turnTimeSec,
		"grid_size":              gridSize,
		"swap_rule":              swapRule,
		"first_move_restriction": firstMoveRestriction,
		"stake_bronze":           stakeBronze,
	}
	if creatorAvatarKind != "" {
		broadcastData["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		broadcastData["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast([]uuid.UUID{opponentUUID}, broadcastData)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

func (h *GamesHandler) rdbRPOPMatchmake(ctx context.Context, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) (string, error) {
	return h.Rdb.RPop(ctx, matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)).Result()
}

func emptyBoardJSON(gridSize int) string {
	n := gridSize * gridSize
	if n <= 0 || n > 64 {
		n = 9
	}
	b := make([]string, n)
	for i := range b {
		b[i] = ""
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

func (h *GamesHandler) createGameFromMatch(ctx context.Context, user1, user2 uuid.UUID, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) (gameID, lobbyID string, err error) {
	for _, uid := range []uuid.UUID{user1, user2} {
		ok, e := store.UserMayStake(ctx, h.Pool, uid, stakeBronze)
		if e != nil {
			return "", "", e
		}
		if !ok {
			return "", "", store.ErrStakeNotAllowed
		}
	}
	if err := store.DeductCoinsTwo(ctx, h.Pool, user1, user2, stakeBronze); err != nil {
		return "", "", err
	}
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
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
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
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
	)
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)

	_, err = pipe.Exec(ctx)
	return gameID, lobbyID, err
}

// createGameWithBot создаёт игру пользователь vs бот и обновляет существующее лобби.
func (h *GamesHandler) createGameWithBot(ctx context.Context, userID uuid.UUID, existingLobbyID string, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) (gameID string, err error) {
	ok, e := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if e != nil {
		return "", e
	}
	if !ok {
		return "", store.ErrStakeNotAllowed
	}
	if err := store.DeductCoins(ctx, h.Pool, userID, stakeBronze); err != nil {
		return "", err
	}
	gameID = uuid.New().String()

	xUserID := userID.String()
	oUserID := botUserID
	if rand.Intn(2) == 1 {
		xUserID, oUserID = oUserID, xUserID
	}

	board := emptyBoardJSON(gridSize)
	key := "game:" + gameID
	lobbyKey := "lobby:" + existingLobbyID

	pipe := h.Rdb.Pipeline()
	gameFields := []any{
		"board", board,
		"turn", "x",
		"status", gameStatusActive,
		"lobby_id", existingLobbyID,
		"x_user_id", xUserID,
		"o_user_id", oUserID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"grid_size", strconv.Itoa(gridSize),
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, key, gameFields...)
	pipe.Expire(ctx, key, 24*time.Hour)

	pipe.HSet(ctx, lobbyKey,
		"opponent_id", botUserID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
	)
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)

	_, err = pipe.Exec(ctx)
	return gameID, err
}

func isBot(userID string) bool { return strings.HasPrefix(userID, "bot:") }

func validMoves(board []string, gridSize int, turn string, firstMoveRestriction bool) []int {
	var out []int
	centerIdxs := centerCellIndices(gridSize)
	for i, c := range board {
		if c != "" {
			continue
		}
		if firstMoveRestriction && turn == "x" {
			moveCount := 0
			for _, b := range board {
				if b != "" {
					moveCount++
				}
			}
			if moveCount == 0 {
				skip := false
				for _, ci := range centerIdxs {
					if i == ci {
						skip = true
						break
					}
				}
				if skip {
					continue
				}
			}
		}
		out = append(out, i)
	}
	return out
}

// cellCompletesWin проверяет, даёт ли ход в cell победную линию.
func cellCompletesWin(board []string, cell int, mark string, gridSize int) bool {
	cp := make([]string, len(board))
	copy(cp, board)
	cp[cell] = mark
	return len(checkWinLine(cp, mark, gridSize)) == winLength(gridSize)
}

// botPickCellSmart — осмысленный ход: победа > блок > минимакс (3x3) > центр > случайный.
func botPickCellSmart(board []string, gridSize int, turn string, firstMoveRestriction bool) int {
	moves := validMoves(board, gridSize, turn, firstMoveRestriction)
	if len(moves) == 0 {
		return -1
	}
	opponent := "o"
	if turn == "o" {
		opponent = "x"
	}
	// 1. Победа в один ход
	for _, cell := range moves {
		if cellCompletesWin(board, cell, turn, gridSize) {
			return cell
		}
	}
	// 2. Блокировать победу соперника
	for _, cell := range moves {
		if cellCompletesWin(board, cell, opponent, gridSize) {
			return cell
		}
	}
	// 3. Для 3x3 — минимакс
	if gridSize == 3 {
		if cell := botMinimax(board, turn, firstMoveRestriction); cell >= 0 {
			return cell
		}
	}
	// 4. Предпочтение центру (для нечётных сеток)
	centerIdxs := centerCellIndices(gridSize)
	for _, ci := range centerIdxs {
		for _, m := range moves {
			if m == ci {
				return m
			}
		}
	}
	// 5. Случайный ход
	return moves[rand.Intn(len(moves))]
}

func botMinimax(board []string, botMark string, firstMoveRestriction bool) int {
	moves := validMoves(board, 3, botMark, firstMoveRestriction)
	if len(moves) == 0 {
		return -1
	}
	opponent := "o"
	if botMark == "o" {
		opponent = "x"
	}
	bestScore := -20
	var bestCell int = -1
	for _, cell := range moves {
		cp := make([]string, len(board))
		copy(cp, board)
		cp[cell] = botMark
		score := minimaxMin(cp, opponent, botMark, firstMoveRestriction)
		if score > bestScore {
			bestScore = score
			bestCell = cell
		}
	}
	return bestCell
}

func minimaxMax(board []string, botMark string, firstMoveRestriction bool) int {
	if checkWin(board, "o", 3) {
		if botMark == "o" {
			return 10
		}
		return -10
	}
	if checkWin(board, "x", 3) {
		if botMark == "x" {
			return 10
		}
		return -10
	}
	if isDraw(board, 3) {
		return 0
	}
	moves := validMoves(board, 3, botMark, firstMoveRestriction)
	opponent := "o"
	if botMark == "o" {
		opponent = "x"
	}
	best := -20
	for _, cell := range moves {
		cp := make([]string, len(board))
		copy(cp, board)
		cp[cell] = botMark
		s := minimaxMin(cp, opponent, botMark, firstMoveRestriction)
		if s > best {
			best = s
		}
	}
	return best
}

func minimaxMin(board []string, opponent string, botMark string, firstMoveRestriction bool) int {
	if checkWin(board, "o", 3) {
		if botMark == "o" {
			return 10
		}
		return -10
	}
	if checkWin(board, "x", 3) {
		if botMark == "x" {
			return 10
		}
		return -10
	}
	if isDraw(board, 3) {
		return 0
	}
	moves := validMoves(board, 3, opponent, firstMoveRestriction)
	best := 20
	for _, cell := range moves {
		cp := make([]string, len(board))
		copy(cp, board)
		cp[cell] = opponent
		s := minimaxMax(cp, botMark, firstMoveRestriction)
		if s < best {
			best = s
		}
	}
	return best
}

func (h *GamesHandler) applyBotMove(ctx context.Context, key string, m map[string]string) bool {
	time.Sleep(1 * time.Second) // Задержка хода бота для естественности
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	turn := m["turn"]
	firstMoveRestriction := m["first_move_restriction"] == "true"
	board := parseBoard(m["board"], gridSize)
	cell := botPickCellSmart(board, gridSize, turn, firstMoveRestriction)
	if cell < 0 {
		return false
	}
	board[cell] = turn
	nextTurn := "o"
	if turn == "o" {
		nextTurn = "x"
	}
	newBoard := formatBoard(board)
	status := gameStatusActive
	winner := turn
	winningCells := checkWinLine(board, turn, gridSize)
	if len(winningCells) == winLength(gridSize) {
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
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
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
		return false
	}
	if status != gameStatusActive {
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.onGameFinished(ctx, xUserID, oUserID, stakeBronze, status)
		for _, u := range humanUserIDs(xUserID, oUserID) {
			clearUserActiveGame(ctx, h.Rdb, u)
		}
		h.broadcast(humanUserIDs(xUserID, oUserID), map[string]any{
			"type": "game_state", "game_id": strings.TrimPrefix(key, "game:"),
			"board": board, "turn": nextTurn, "winner": winner, "status": status,
		})
	}
	return true
}

func humanUserIDs(xUserID, oUserID string) []uuid.UUID {
	var out []uuid.UUID
	for _, id := range []string{xUserID, oUserID} {
		if !isBot(id) {
			if u, e := uuid.Parse(id); e == nil {
				out = append(out, u)
			}
		}
	}
	return out
}

// StartBotTimeoutTicker проверяет лобби с add_bots_after_30s: через 30 с без соперника добавляет бота.
func StartBotTimeoutTicker(ctx context.Context, h *GamesHandler) {
	if h == nil || h.Rdb == nil {
		return
	}
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			h.tickBotTimeout(ctx)
		}
	}
}

func (h *GamesHandler) tickBotTimeout(ctx context.Context) {
	keys, err := h.Rdb.Keys(ctx, "lobby:*").Result()
	if err != nil || len(keys) == 0 {
		return
	}
	now := time.Now().UTC()
	for _, key := range keys {
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["status"] != lobbyStatusWaitingMatchmake || m["add_bots_after_30s"] != "true" {
			continue
		}
		createdAt, err := time.Parse(time.RFC3339Nano, m["created_at"])
		if err != nil {
			continue
		}
		if now.Sub(createdAt) < botTimeoutSeconds*time.Second {
			continue
		}
		lobbyID := strings.TrimPrefix(key, "lobby:")
		creatorID := m["creator_id"]
		creatorUUID, err := uuid.Parse(creatorID)
		if err != nil {
			continue
		}
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		gridSize, _ := strconv.Atoi(m["grid_size"])
		if !validGridSize[gridSize] {
			gridSize = 3
		}
		swapRule := m["swap_rule"] == "true"
		firstMoveRestriction := m["first_move_restriction"] == "true"
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 1 {
			stakeBronze = 1
		}
		mmKey := matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)
		h.Rdb.LRem(ctx, mmKey, 0, creatorID+":"+lobbyID)
		// Игры с ботом всегда на 1 бронзовую
		gameID, err := h.createGameWithBot(ctx, creatorUUID, lobbyID, turnTimeSec, gridSize, swapRule, firstMoveRestriction, 1)
		if err != nil {
			continue
		}
		clearUserActiveLobby(ctx, h.Rdb, creatorUUID)
		setUserActiveGame(ctx, h.Rdb, creatorUUID, gameID)
		h.publishGameStarted([]uuid.UUID{creatorUUID}, gameID, lobbyID)
		return
	}
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
		swapRule := m["swap_rule"] == "true"
		firstMoveRestriction := m["first_move_restriction"] == "true"
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		lobbies = append(lobbies, LobbyItem{
			ID:                   id,
			CreatorID:            creatorID,
			CreatorName:          creatorName,
			Status:               m["status"],
			CreatedAt:            m["created_at"],
			TurnTimeSec:          turnTimeSec,
			GridSize:             gridSize,
			SwapRule:             swapRule,
			FirstMoveRestriction: firstMoveRestriction,
			StakeBronze:          stakeBronze,
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

	// Участники всегда видят лобби. Для открытого поиска и invite-по-ссылке
	// любой авторизованный пользователь может просмотреть waiting-лобби.
	if creatorID != userID.String() && opponentID != userID.String() {
		if status != lobbyStatusWaitingMatchmake && status != lobbyStatusWaitingInvite {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
	}

	creatorName := "Игрок"
	if creatorUUID, err := uuid.Parse(creatorID); err == nil {
		if creator, _ := store.GetUserByID(ctx, h.Pool, creatorUUID); creator != nil && creator.DisplayName != nil && *creator.DisplayName != "" {
			creatorName = *creator.DisplayName
		}
	}

	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction := m["first_move_restriction"] == "true"
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	item := LobbyItem{
		ID:                   lobbyID,
		CreatorID:            creatorID,
		CreatorName:          creatorName,
		Status:               status,
		CreatedAt:            m["created_at"],
		TurnTimeSec:          turnTimeSec,
		GridSize:             gridSize,
		SwapRule:             swapRule,
		FirstMoveRestriction: firstMoveRestriction,
		StakeBronze:          stakeBronze,
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
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction := m["first_move_restriction"] == "true"

	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	inviteData := map[string]any{
		"type":                   "game_invite",
		"lobby_id":               lobbyID,
		"creator_id":             userID.String(),
		"creator_name":           creatorName,
		"game_type":              "tictactoe",
		"turn_time_sec":          turnTimeSec,
		"grid_size":              gridSize,
		"swap_rule":              swapRule,
		"first_move_restriction": firstMoveRestriction,
		"stake_bronze":           stakeBronze,
	}
	if creatorAvatarKind != "" {
		inviteData["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		inviteData["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast([]uuid.UUID{friendID}, inviteData)

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

	if status == lobbyStatusInGame {
		http.Error(w, "игра уже началась с другим соперником", http.StatusConflict)
		return
	}

	if creatorID == userID.String() {
		http.Error(w, "cannot join own lobby", http.StatusBadRequest)
		return
	}

	// waiting_invite: вход по прямой ссылке или по приглашению друга (UUID лобби — секрет).
	// waiting_matchmake: любой соперник из очереди/списка открытых лобби.
	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		http.Error(w, "lobby not joinable", http.StatusBadRequest)
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

	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	gridSize, _ := strconv.Atoi(m["grid_size"])
	if !validGridSize[gridSize] {
		gridSize = 3
	}
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction := m["first_move_restriction"] == "true"
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	bal, err := store.GetBalance(ctx, h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if bal < stakeBronze {
		http.Error(w, "insufficient balance", http.StatusPaymentRequired)
		return
	}
	creatorBal, err := store.GetBalance(ctx, h.Pool, creatorUUID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if creatorBal < stakeBronze {
		http.Error(w, "creator has insufficient balance", http.StatusConflict)
		return
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
		pipe.LRem(ctx, matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze), 0, creatorID+":"+lobbyID)
	}

	if err := store.DeductCoinsTwo(ctx, h.Pool, creatorUUID, userID, stakeBronze); err != nil {
		http.Error(w, "insufficient balance", http.StatusPaymentRequired)
		return
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
		"swap_rule", strconv.FormatBool(swapRule),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
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
		h.Rdb.Del(ctx, key+":invited")
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
		swapRule := m["swap_rule"] == "true"
		firstMoveRestriction := m["first_move_restriction"] == "true"
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.Rdb.LRem(ctx, matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze), 0, userID.String()+":"+lobbyID)
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
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	h.onGameFinished(ctx, xUserID, oUserID, stakeBronze, status)
	for _, u := range humanUserIDs(xUserID, oUserID) {
		clearUserActiveGame(ctx, h.Rdb, u)
	}
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	h.broadcast(humanUserIDs(xUserID, oUserID), map[string]any{
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

	// Если сейчас ход бота — выполняем ход перед возвратом состояния
	turn := m["turn"]
	botTurn := (turn == "x" && isBot(xUserID)) || (turn == "o" && isBot(oUserID))
	if botTurn && m["status"] == gameStatusActive {
		if h.applyBotMove(ctx, key, m) {
			m, _ = h.Rdb.HGetAll(ctx, key).Result()
		}
	}

	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction := m["first_move_restriction"] == "true"
	swapped := m["swapped"] == "true"
	canSwap := false
	if swapRule && !swapped && m["turn"] == "o" {
		cnt := 0
		for _, c := range board {
			if c != "" {
				cnt++
			}
		}
		canSwap = cnt == 1
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	item := GameStateItem{
		ID:                   gameID,
		Board:                board,
		Turn:                 m["turn"],
		Status:               m["status"],
		GridSize:             gridSize,
		XUserID:              xUserID,
		OUserID:              oUserID,
		SwapRule:             swapRule,
		FirstMoveRestriction: firstMoveRestriction,
		CanSwap:              canSwap,
		StakeBronze:          stakeBronze,
		Forfeit:              m["forfeit"] == "1",
		Timeout:              m["timeout"] == "1",
	}
	if w := m["winner"]; w != "" {
		item.Winner = &w
		if line := checkWinLine(board, w, gridSize); len(line) == winLength(gridSize) {
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

	botName := "Бот"
	frameIDs := make([]uuid.UUID, 0, 2)
	var xUUID, oUUID uuid.UUID
	var xParsed, oParsed bool
	if isBot(xUserID) {
		item.XDisplayName = &botName
	} else if id, err := uuid.Parse(xUserID); err == nil {
		xUUID, xParsed = id, true
		frameIDs = append(frameIDs, id)
		if xu, err := store.GetUserByID(ctx, h.Pool, id); err == nil {
			if xu.DisplayName != nil && *xu.DisplayName != "" {
				item.XDisplayName = xu.DisplayName
			}
			item.XAvatarKind = xu.AvatarKind
			item.XAvatarValue = xu.AvatarValue
		}
	}
	if isBot(oUserID) {
		item.ODisplayName = &botName
	} else if id, err := uuid.Parse(oUserID); err == nil {
		oUUID, oParsed = id, true
		frameIDs = append(frameIDs, id)
		if ou, err := store.GetUserByID(ctx, h.Pool, id); err == nil {
			if ou.DisplayName != nil && *ou.DisplayName != "" {
				item.ODisplayName = ou.DisplayName
			}
			item.OAvatarKind = ou.AvatarKind
			item.OAvatarValue = ou.AvatarValue
		}
	}
	if frames, err := store.EquippedFramesMap(ctx, h.Pool, frameIDs); err == nil {
		if xParsed {
			if f, ok := frames[xUUID]; ok {
				item.XFrameColor = f.Color
				item.XFrameCode = f.Code
			}
		}
		if oParsed {
			if f, ok := frames[oUUID]; ok {
				item.OFrameColor = f.Color
				item.OFrameCode = f.Code
			}
		}
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
		resp := map[string]any{
			"game_id": gameID, "board": board,
			"turn": m["turn"], "winner": m["winner"], "status": m["status"],
			"timeout": true, "grid_size": gridSize,
			"x_user_id": m["x_user_id"], "o_user_id": m["o_user_id"],
		}
		h.addGamePlayerMetadata(ctx, resp, m["x_user_id"], m["o_user_id"])
		_ = json.NewEncoder(w).Encode(resp)
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

	firstMoveRestriction := m["first_move_restriction"] == "true"
	if firstMoveRestriction && turn == "x" {
		board := parseBoard(m["board"], gridSize)
		moveCount := 0
		for _, c := range board {
			if c != "" {
				moveCount++
			}
		}
		if moveCount == 0 {
			for _, c := range centerCellIndices(gridSize) {
				if c == body.Cell {
					http.Error(w, "first move cannot be in center", http.StatusBadRequest)
					return
				}
			}
		}
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
	if len(winningCells) == winLength(gridSize) {
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
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.onGameFinished(ctx, xUserID, oUserID, stakeBronze, status)
		for _, uid := range []string{xUserID, oUserID} {
			if !isBot(uid) {
				if u, e := uuid.Parse(uid); e == nil {
					clearUserActiveGame(ctx, h.Rdb, u)
				}
			}
		}
	}

	winnerVal := winner
	if winner != "" {
		winnerVal = turn
	}
	swapRule := m["swap_rule"] == "true"
	firstMoveRestriction = m["first_move_restriction"] == "true"
	swapped := m["swapped"] == "true"
	canSwap := false
	if swapRule && !swapped && nextTurn == "o" && status == gameStatusActive {
		cnt := 0
		for _, c := range board {
			if c != "" {
				cnt++
			}
		}
		canSwap = cnt == 1
	}
	broadcastPayload := map[string]any{
		"type": "game_state", "game_id": gameID,
		"board": board, "turn": nextTurn, "winner": winnerVal, "status": status,
		"swap_rule": swapRule, "first_move_restriction": firstMoveRestriction, "can_swap": canSwap,
	}
	if len(winningCells) == winLength(gridSize) {
		broadcastPayload["winning_cells"] = winningCells
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		broadcastPayload["turn_deadline"] = deadline
		broadcastPayload["turn_time_sec"] = turnTimeSec
	}
	h.broadcast(humanUserIDs(xUserID, oUserID), broadcastPayload)

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
	if len(winningCells) == winLength(gridSize) {
		resp["winning_cells"] = winningCells
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		resp["turn_time_sec"] = turnTimeSec
		resp["turn_deadline"] = time.Now().UTC().Unix() + int64(turnTimeSec)
	}
	h.addGamePlayerMetadata(ctx, resp, xUserID, oUserID)
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *GamesHandler) SwapSides(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["status"] != gameStatusActive {
		http.Error(w, "game is over", http.StatusBadRequest)
		return
	}

	swapRule := m["swap_rule"] == "true"
	if !swapRule {
		http.Error(w, "swap not allowed in this game", http.StatusBadRequest)
		return
	}

	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if oUserID != userID.String() {
		http.Error(w, "only O can swap", http.StatusBadRequest)
		return
	}
	if m["turn"] != "o" {
		http.Error(w, "can only swap on your turn after X's first move", http.StatusBadRequest)
		return
	}

	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	moveCount := 0
	for _, c := range board {
		if c != "" {
			moveCount++
		}
	}
	if moveCount != 1 {
		http.Error(w, "can only swap after X's first move", http.StatusBadRequest)
		return
	}

	newXUserID := oUserID
	newOUserID := xUserID
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key, "x_user_id", newXUserID, "o_user_id", newOUserID, "turn", "o", "swapped", "true")
	pipe.Expire(ctx, key, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	xUUID, _ := uuid.Parse(newXUserID)
	oUUID, _ := uuid.Parse(newOUserID)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	broadcastPayload := map[string]any{
		"type":      "game_state",
		"game_id":   gameID,
		"board":     board,
		"turn":      "o",
		"status":    gameStatusActive,
		"x_user_id": newXUserID,
		"o_user_id": newOUserID,
		"swap_rule": true,
		"can_swap":  false,
		"swapped":   true,
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		broadcastPayload["turn_deadline"] = deadline
		broadcastPayload["turn_time_sec"] = turnTimeSec
	}
	h.broadcast([]uuid.UUID{xUUID, oUUID}, broadcastPayload)

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"game_id":   gameID,
		"board":     board,
		"turn":      "o",
		"status":    gameStatusActive,
		"x_user_id": newXUserID,
		"o_user_id": newOUserID,
		"swapped":   true,
	}
	h.addGamePlayerMetadata(ctx, resp, newXUserID, newOUserID)
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
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	h.onGameFinished(ctx, xUserID, oUserID, stakeBronze, status)
	for _, u := range humanUserIDs(xUserID, oUserID) {
		clearUserActiveGame(ctx, h.Rdb, u)
	}
	winnerVal := "o"
	if status == gameStatusXWon {
		winnerVal = "x"
	}
	h.broadcast(humanUserIDs(xUserID, oUserID), map[string]any{
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

// onGameFinished — монеты + счётчик партий/достижения для людей (не ботов).
func (h *GamesHandler) onGameFinished(ctx context.Context, xUserID, oUserID string, stakeBronze int, status string) {
	h.settleGameCoins(ctx, xUserID, oUserID, stakeBronze, status)
	h.recordGameFinished(ctx, xUserID, oUserID)
	h.recordGameWin(ctx, xUserID, oUserID, stakeBronze, status)
}

func (h *GamesHandler) recordGameWin(ctx context.Context, xUserID, oUserID string, stakeBronze int, status string) {
	winnerID := ""
	switch status {
	case gameStatusXWon:
		winnerID = xUserID
	case gameStatusOWon:
		winnerID = oUserID
	default:
		return
	}
	if winnerID == "" || isBot(winnerID) {
		return
	}
	uid, err := uuid.Parse(winnerID)
	if err != nil {
		return
	}
	if err := store.IncrementWinsByStake(ctx, h.Pool, uid, stakeBronze); err != nil {
		return
	}
	_ = store.EvaluateAndUnlock(ctx, h.Pool, uid)
}

func (h *GamesHandler) recordGameFinished(ctx context.Context, xUserID, oUserID string) {
	for _, raw := range []string{xUserID, oUserID} {
		if raw == "" || isBot(raw) {
			continue
		}
		uid, err := uuid.Parse(raw)
		if err != nil {
			continue
		}
		if err := store.IncrementGamesFinished(ctx, h.Pool, uid); err != nil {
			continue
		}
		_ = store.EvaluateAndUnlock(ctx, h.Pool, uid)
	}
}

func (h *GamesHandler) settleGameCoins(ctx context.Context, xUserID, oUserID string, stakeBronze int, status string) {
	if stakeBronze <= 0 || xUserID == "" || oUserID == "" {
		return
	}
	if isBot(xUserID) || isBot(oUserID) {
		// Один из игроков — бот. Возвращаем монеты человеку при ничьей/проигрыше, даём 2*stake при победе.
		humanID := xUserID
		if isBot(xUserID) {
			humanID = oUserID
		}
		humanUUID, err := uuid.Parse(humanID)
		if err != nil {
			return
		}
		winner := ""
		if status == gameStatusXWon {
			winner = "x"
		} else if status == gameStatusOWon {
			winner = "o"
		}
		if winner == "" {
			_ = store.AddCoins(ctx, h.Pool, humanUUID, stakeBronze)
		} else if (winner == "x" && xUserID == humanID) || (winner == "o" && oUserID == humanID) {
			_ = store.AddCoins(ctx, h.Pool, humanUUID, stakeBronze*2)
		}
		return
	}
	xUUID, _ := uuid.Parse(xUserID)
	oUUID, _ := uuid.Parse(oUserID)
	winner := ""
	if status == gameStatusXWon {
		winner = "x"
	} else if status == gameStatusOWon {
		winner = "o"
	}
	_ = store.SettleGameCoins(ctx, h.Pool, xUUID, oUUID, stakeBronze, winner)
}

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
				"lobby_id":   m["lobby_id"],
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

// centerCellIndices возвращает индексы центральных клеток (запрещены для первого хода при first_move_restriction).
func centerCellIndices(gridSize int) []int {
	switch gridSize {
	case 3:
		return []int{4}
	case 4:
		return []int{5, 6, 9, 10}
	case 5:
		return []int{12}
	case 6:
		return []int{14, 15, 20, 21}
	case 7:
		return []int{24}
	case 8:
		return []int{27, 28, 35, 36}
	default:
		return nil
	}
}

func parseBoard(s string, gridSize int) []string {
	var b []string
	_ = json.Unmarshal([]byte(s), &b)
	n := gridSize * gridSize
	if n <= 0 || n > 64 {
		n = 9
	}
	if len(b) != n {
		return make([]string, n)
	}
	return b
}

// winLength: для 3–5 — N в ряд, для 6–8 — 5 в ряд (гомоку).
func winLength(gridSize int) int {
	if gridSize >= 6 {
		return 5
	}
	return gridSize
}

func formatBoard(b []string) string {
	if len(b) == 0 {
		b = make([]string, 9)
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

// checkWin: N в ряд для 3–5, 5 в ряд для 6–8 (гомоку).
func checkWin(board []string, mark string, gridSize int) bool {
	wl := winLength(gridSize)
	return len(checkWinLine(board, mark, gridSize)) == wl
}

// checkWinLine возвращает индексы клеток победной линии или nil.
func checkWinLine(board []string, mark string, gridSize int) []int {
	n := gridSize * gridSize
	wl := winLength(gridSize)
	if len(board) < n || wl > gridSize {
		return nil
	}
	// Горизонтали
	for row := 0; row < gridSize; row++ {
		for col := 0; col <= gridSize-wl; col++ {
			line := make([]int, wl)
			all := true
			for k := 0; k < wl; k++ {
				idx := row*gridSize + col + k
				line[k] = idx
				if board[idx] != mark {
					all = false
					break
				}
			}
			if all {
				return line
			}
		}
	}
	// Вертикали
	for col := 0; col < gridSize; col++ {
		for row := 0; row <= gridSize-wl; row++ {
			line := make([]int, wl)
			all := true
			for k := 0; k < wl; k++ {
				idx := (row+k)*gridSize + col
				line[k] = idx
				if board[idx] != mark {
					all = false
					break
				}
			}
			if all {
				return line
			}
		}
	}
	// Диагональ \
	for row := 0; row <= gridSize-wl; row++ {
		for col := 0; col <= gridSize-wl; col++ {
			line := make([]int, wl)
			all := true
			for k := 0; k < wl; k++ {
				idx := (row+k)*gridSize + (col + k)
				line[k] = idx
				if board[idx] != mark {
					all = false
					break
				}
			}
			if all {
				return line
			}
		}
	}
	// Диагональ /
	for row := 0; row <= gridSize-wl; row++ {
		for col := wl - 1; col <= gridSize-1; col++ {
			line := make([]int, wl)
			all := true
			for k := 0; k < wl; k++ {
				idx := (row+k)*gridSize + (col - k)
				line[k] = idx
				if board[idx] != mark {
					all = false
					break
				}
			}
			if all {
				return line
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
