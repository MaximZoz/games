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

	"multigames/server/internal/gameengine"
	"multigames/server/internal/i18n"
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
	gameStatusTWon              = "t_won"
	gameStatusSWon              = "s_won"
	gameStatusDraw              = "draw"
	lobbyTTL                    = 10 * time.Minute
	botUserID                   = "bot:ttt"
	botTimeoutSeconds           = 30
)

// turn_time_sec: 0=unlimited, 20, 60, 600
var validTurnTimeSec = map[int]bool{0: true, 20: true, 60: true, 600: true}

// legacy grid sizes (старые клиенты); новые режимы задаются variant.
var validGridSize = map[int]bool{3: true, 4: true, 5: true, 6: true, 7: true, 8: true, 9: true, 10: true, 15: true}

func matchmakeKey(turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) string {
	// Устарело: оставляем для LeaveLobby cleanup старых ключей.
	_ = swapRule
	_ = firstMoveRestriction
	return "tictactoe:matchmake:" + strconv.Itoa(turnTimeSec) + ":" + strconv.Itoa(gridSize) + ":0:0:" + strconv.Itoa(stakeBronze)
}

type GamesHandler struct {
	Pool        *pgxpool.Pool
	Rdb         *redis.Client
	Hub         *RealtimeHub
	Broadcaster *GamesBroadcaster
	Push        *WebPushSender
}

type CreateLobbyBody struct {
	Mode                 string `json:"mode"`                   // "invite" | "matchmake"
	TurnTimeSec          int    `json:"turn_time_sec"`          // 0=unlimited, 10, 30, 60, 600
	Variant              string `json:"variant"`                // classic|gomoku|ultimate|multi3|multi4
	GridSize             int    `json:"grid_size"`              // legacy; перекрывается variant
	SwapRule             bool   `json:"swap_rule"`              // deprecated, игнорируется
	FirstMoveRestriction bool   `json:"first_move_restriction"` // deprecated, игнорируется
	StakeBronze          int    `json:"stake_bronze"`           // ставка в бронзовых (мин 1)
	AddBotsAfter30s      bool   `json:"add_bots_after_30s"`     // в matchmake: через 30 с добавить бота
}

type InviteBody struct {
	FriendUserID string `json:"friend_user_id"`
}

type MoveBody struct {
	Cell int `json:"cell"` // 0 to N*N-1
}

type LobbyPlayerItem struct {
	ID           string  `json:"id"`
	DisplayName  string  `json:"display_name,omitempty"`
	AvatarKind   string  `json:"avatar_kind,omitempty"`
	AvatarValue  *string `json:"avatar_value,omitempty"`
}

type LobbyItem struct {
	ID                   string            `json:"id"`
	CreatorID            string            `json:"creator_id"`
	CreatorName          string            `json:"creator_name,omitempty"`
	OpponentID           *string           `json:"opponent_id,omitempty"`
	Status               string            `json:"status"`
	Mode                 string            `json:"mode,omitempty"`
	GameID               *string           `json:"game_id,omitempty"`
	CreatedAt            string            `json:"created_at"`
	TurnTimeSec          int               `json:"turn_time_sec,omitempty"`
	Variant              string            `json:"variant,omitempty"`
	GridSize             int               `json:"grid_size,omitempty"`
	MaxPlayers           int               `json:"max_players,omitempty"`
	PlayersCount         int               `json:"players_count,omitempty"`
	PlayerIDs            []string          `json:"player_ids,omitempty"`
	Players              []LobbyPlayerItem `json:"players,omitempty"`
	ChatID               string            `json:"chat_id,omitempty"`
	SwapRule             bool              `json:"swap_rule,omitempty"`              // deprecated
	FirstMoveRestriction bool              `json:"first_move_restriction,omitempty"` // deprecated
	StakeBronze          int               `json:"stake_bronze,omitempty"`
}

type GameStateItem struct {
	ID                   string   `json:"id"`
	Board                []string `json:"board"` // клетки: "", "x", "o", "t", "s"
	Variant              string   `json:"variant,omitempty"`
	GridSize             int      `json:"grid_size,omitempty"`
	Turn                 string   `json:"turn"` // mark
	Winner               *string  `json:"winner,omitempty"`
	Status               string   `json:"status"`
	Forfeit              bool     `json:"forfeit,omitempty"`
	Timeout              bool     `json:"timeout,omitempty"`
	TurnTimeSec          int      `json:"turn_time_sec,omitempty"`
	TurnDeadline         *int64   `json:"turn_deadline,omitempty"`
	WinningCells         []int    `json:"winning_cells,omitempty"`
	XUserID              string   `json:"x_user_id"`
	OUserID              string   `json:"o_user_id"`
	TUserID              string   `json:"t_user_id,omitempty"`
	SUserID              string   `json:"s_user_id,omitempty"`
	NextBoard            *int     `json:"next_board,omitempty"` // ultimate: -1|0..8
	MetaBoard            []string `json:"meta_board,omitempty"`
	MaxPlayers           int      `json:"max_players,omitempty"`
	SwapRule             bool     `json:"swap_rule,omitempty"`
	FirstMoveRestriction bool     `json:"first_move_restriction,omitempty"`
	CanSwap              bool     `json:"can_swap,omitempty"` // всегда false
	StakeBronze          int      `json:"stake_bronze,omitempty"`
	// Кто предложил ничью (user id); пусто — предложения нет.
	DrawOfferBy          string   `json:"draw_offer_by,omitempty"`
	ChatID               string   `json:"chat_id,omitempty"`
	EliminatedMarks      []string `json:"eliminated_marks,omitempty"`
	XDisplayName         *string  `json:"x_display_name,omitempty"`
	ODisplayName         *string  `json:"o_display_name,omitempty"`
	TDisplayName         *string  `json:"t_display_name,omitempty"`
	SDisplayName         *string  `json:"s_display_name,omitempty"`
	XAvatarKind          string   `json:"x_avatar_kind,omitempty"`
	XAvatarValue         *string  `json:"x_avatar_value,omitempty"`
	XFrameColor          string   `json:"x_frame_color,omitempty"`
	XFrameCode           string   `json:"x_frame_code,omitempty"`
	OAvatarKind          string   `json:"o_avatar_kind,omitempty"`
	OAvatarValue         *string  `json:"o_avatar_value,omitempty"`
	OFrameColor          string   `json:"o_frame_color,omitempty"`
	OFrameCode           string   `json:"o_frame_code,omitempty"`
	TAvatarKind          string   `json:"t_avatar_kind,omitempty"`
	TAvatarValue         *string  `json:"t_avatar_value,omitempty"`
	TFrameColor          string   `json:"t_frame_color,omitempty"`
	TFrameCode           string   `json:"t_frame_code,omitempty"`
	SAvatarKind          string   `json:"s_avatar_kind,omitempty"`
	SAvatarValue         *string  `json:"s_avatar_value,omitempty"`
	SFrameColor          string   `json:"s_frame_color,omitempty"`
	SFrameCode           string   `json:"s_frame_code,omitempty"`
}

type gameUserLookup func(context.Context, uuid.UUID) (*store.User, error)

func addGamePlayerMetadata(ctx context.Context, payload map[string]any, xUserID, oUserID string, lookup gameUserLookup) {
	addGamePlayerMetadataSides(ctx, payload, map[string]string{"x": xUserID, "o": oUserID}, lookup)
}

func addGamePlayerMetadataSides(ctx context.Context, payload map[string]any, sides map[string]string, lookup gameUserLookup) {
	for side, userID := range sides {
		userID = strings.TrimSpace(userID)
		if userID == "" {
			continue
		}
		if isBot(userID) {
			payload[side+"_display_name"] = "Бот"
			continue
		}
		userUUID, err := uuid.Parse(userID)
		if err != nil {
			continue
		}
		user, err := lookup(ctx, userUUID)
		if err != nil || user == nil {
			continue
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
}

func (h *GamesHandler) addGamePlayerMetadata(ctx context.Context, payload map[string]any, xUserID, oUserID string) {
	h.addGamePlayerMetadataFromMap(ctx, payload, map[string]string{
		"x": xUserID,
		"o": oUserID,
	})
}

func (h *GamesHandler) addGamePlayerMetadataFromMap(ctx context.Context, payload map[string]any, sides map[string]string) {
	addGamePlayerMetadataSides(ctx, payload, sides, func(ctx context.Context, userID uuid.UUID) (*store.User, error) {
		return store.GetUserByID(ctx, h.Pool, userID)
	})
	ids := make([]uuid.UUID, 0, len(sides))
	for _, uid := range sides {
		if isBot(uid) {
			continue
		}
		if u, e := uuid.Parse(uid); e == nil {
			ids = append(ids, u)
		}
	}
	frames, err := store.EquippedFramesMap(ctx, h.Pool, ids)
	if err != nil {
		return
	}
	for side, uid := range sides {
		if isBot(uid) {
			continue
		}
		u, e := uuid.Parse(uid)
		if e != nil {
			continue
		}
		if f, ok := frames[u]; ok {
			payload[side+"_frame_color"] = f.Color
			payload[side+"_frame_code"] = f.Code
		}
	}
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

func (h *GamesHandler) requireRedis(w http.ResponseWriter, r *http.Request) bool {
	if h.Rdb == nil {
		WriteErr(w, r, http.StatusServiceUnavailable, "games service unavailable (Redis required)")
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
	// Статистика и head-to-head тоже в Postgres — работают без Redis.
	if r.URL.Path == "/api/games/stats" && r.Method == http.MethodGet {
		h.GetStats(w, r)
		return
	}
	if r.URL.Path == "/api/games/head-to-head" && r.Method == http.MethodGet {
		h.GetHeadToHead(w, r)
		return
	}
	if !h.requireRedis(w, r) {
		return
	}
	if strings.HasPrefix(r.URL.Path, "/api/games/durak/") {
		h.serveDurak(w, r)
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
			WriteErr(w, r, http.StatusBadRequest, "lobby id required")
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
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
		return
	case len(parts) >= 2 && parts[0] == "game":
		gameID := parts[1]
		if gameID == "" {
			WriteErr(w, r, http.StatusBadRequest, "game id required")
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
		case len(parts) == 3 && parts[2] == "draw-offer" && r.Method == http.MethodPost:
			h.OfferDraw(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw-accept" && r.Method == http.MethodPost:
			h.AcceptDraw(w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
		return
	}

	WriteErr(w, r, http.StatusNotFound, "not found")
}

func currentUserIDFromGames(r *http.Request) (uuid.UUID, bool) {
	return GetUserID(r.Context())
}

func (h *GamesHandler) CreateLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body CreateLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	mode := strings.TrimSpace(strings.ToLower(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		WriteErr(w, r, http.StatusBadRequest, "mode must be invite or matchmake")
		return
	}
	stakeBronze := body.StakeBronze
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	ctx := r.Context()
	mayStake, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !mayStake {
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
		return
	}
	balance, err := store.GetBalance(ctx, h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if balance < stakeBronze {
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		return
	}
	turnTimeSec := body.TurnTimeSec
	if !validTurnTimeSec[turnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	cfg, variant := resolveVariantConfig(body.Variant, body.GridSize)
	gridSize := cfg.GridSize
	// Смена сторон / запрет центра удалены.
	swapRule := false
	firstMoveRestriction := false
	addBotsAfter30s := body.AddBotsAfter30s
	// multi «Найти игру»: mode остаётся matchmake (публичное лобби),
	// статус waiting_invite — чтобы добирать игроков до N через JoinLobby.
	openMultiFind := cfg.MaxPlayers > 2 && mode == "matchmake"

	// Уже в живой партии — нельзя создавать/матчмейкать новую.
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}

	// Multi find: схлопнуть с уже открытым лобби тех же правил (2/3, 3/4…).
	if openMultiFind {
		lockKey := fmt.Sprintf("open_multi_lock:%d:%s:%d", turnTimeSec, variant, stakeBronze)
		locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result()
		if locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existingID := h.findOpenMultiLobbyID(ctx, userID, turnTimeSec, string(variant), stakeBronze, cfg.MaxPlayers); existingID != "" {
			if h.mergeIntoOpenMultiLobby(w, r, ctx, userID, existingID, turnTimeSec, variant, gridSize, stakeBronze, cfg) {
				return
			}
			// Лобби успели закрыть — создаём новое ниже.
		}
	}

	if mode == "matchmake" && !openMultiFind {
		otherEntry, err := h.Rdb.RPop(ctx, matchmakeKeyVariant(turnTimeSec, variant, stakeBronze)).Result()
		if err == nil && otherEntry != "" {
			parts := strings.SplitN(otherEntry, ":", 2)
			otherUserID := parts[0]
			otherLobbyID := ""
			if len(parts) > 1 {
				otherLobbyID = parts[1]
			}
			otherUUID, err := uuid.Parse(otherUserID)
			if err == nil && otherUUID != userID {
				// Переиспользуем лобби ожидающего: он сидит на /lobby/{id},
				// и клиент принимает game_started только с тем же lobby_id.
				reuseLobbyID := ""
				if otherLobbyID != "" {
					lm, lerr := h.Rdb.HGetAll(ctx, "lobby:"+otherLobbyID).Result()
					if lerr == nil && len(lm) > 0 && lm["status"] == lobbyStatusWaitingMatchmake {
						reuseLobbyID = otherLobbyID
					} else {
						h.Rdb.Del(ctx, "lobby:"+otherLobbyID)
					}
				}
				gameID, lobbyID, err := h.createGameFromMatch(ctx, userID, otherUUID, reuseLobbyID, turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze, string(variant))
				if err != nil {
					if err == store.ErrStakeNotAllowed {
						WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
						return
					}
					WriteErr(w, r, http.StatusInternalServerError, "server error")
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
	if mode == "matchmake" && !openMultiFind {
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
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
		"player_ids", userID.String(),
		"swap_rule", "false",
		"first_move_restriction", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
		"add_bots_after_30s", strconv.FormatBool(addBotsAfter30s),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if mode == "matchmake" && !openMultiFind {
		mmKey := matchmakeKeyVariant(turnTimeSec, variant, stakeBronze)
		pipe.LPush(ctx, mmKey, userID.String()+":"+lobbyID)
		pipe.Expire(ctx, mmKey, 5*time.Minute)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	chatIDStr := ""
	if cfg.MaxPlayers > 2 {
		title := "Крестики-нолики"
		switch variant {
		case gameengine.VariantMulti3:
			title = "На троих"
		case gameengine.VariantMulti4:
			title = "На четверых"
		}
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{userID}, title, "tictactoe"); cerr == nil {
			chatIDStr = cid.String()
			h.Rdb.HSet(ctx, key, "chat_id", chatIDStr)
			h.broadcast([]uuid.UUID{userID}, map[string]any{
				"type": "chat_list_changed",
			})
		}
	}

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"lobby_id":   lobbyID,
		"status":     status,
		"created_at": now,
		"creator_id": userID.String(),
	}
	if chatIDStr != "" {
		resp["chat_id"] = chatIDStr
	}
	_ = json.NewEncoder(w).Encode(resp)
}

// findOpenMultiLobbyID — открытое multi-лобби «Найти игру» с теми же правилами и свободным слотом.
func (h *GamesHandler) findOpenMultiLobbyID(
	ctx context.Context,
	excludeUser uuid.UUID,
	turnTimeSec int,
	variantStr string,
	stakeBronze, maxPlayers int,
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
		if m["mode"] != "matchmake" {
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
		tt, _ := strconv.Atoi(m["turn_time_sec"])
		if tt != turnTimeSec {
			continue
		}
		stakes, _ := strconv.Atoi(m["stake_bronze"])
		if stakes < 1 {
			stakes = 1
		}
		if stakes != stakeBronze {
			continue
		}
		_, v := resolveVariantConfig(m["variant"], func() int {
			gs, _ := strconv.Atoi(m["grid_size"])
			return gs
		}())
		if string(v) != variantStr {
			continue
		}
		mp, _ := strconv.Atoi(m["max_players"])
		if mp < 1 {
			mp = maxPlayers
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) == 0 {
			players = []string{m["creator_id"]}
		}
		already := false
		for _, p := range players {
			if p == excludeUser.String() {
				already = true
				break
			}
		}
		if already || len(players) >= mp {
			continue
		}
		return strings.TrimPrefix(key, "lobby:")
	}
	return ""
}

// mergeIntoOpenMultiLobby добавляет игрока в существующее open multi-лобби.
// true — ответ уже записан в w.
func (h *GamesHandler) mergeIntoOpenMultiLobby(
	w http.ResponseWriter,
	r *http.Request,
	ctx context.Context,
	userID uuid.UUID,
	lobbyID string,
	turnTimeSec int,
	variant gameengine.Variant,
	gridSize, stakeBronze int,
	cfg gameengine.Config,
) bool {
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return false
	}
	st := m["status"]
	if st != lobbyStatusWaitingInvite && st != lobbyStatusWaitingMatchmake {
		return false
	}
	if m["mode"] != "matchmake" || strings.TrimSpace(m["invite_target_id"]) != "" {
		return false
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if len(players) == 0 {
		players = []string{m["creator_id"]}
	}
	for _, p := range players {
		if p == userID.String() {
			setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
			writeJSON(w, http.StatusOK, map[string]any{
				"lobby_id":   lobbyID,
				"status":     st,
				"created_at": m["created_at"],
				"creator_id": m["creator_id"],
				"chat_id":    m["chat_id"],
			})
			return true
		}
	}
	if len(players) >= cfg.MaxPlayers {
		return false
	}

	players = append(players, userID.String())
	notify := make([]uuid.UUID, 0, len(players))
	for _, p := range players {
		if u, e := uuid.Parse(p); e == nil {
			notify = append(notify, u)
		}
	}
	chatIDStr := m["chat_id"]
	if cfg.MaxPlayers > 2 {
		title := "На троих"
		if variant == gameengine.VariantMulti4 {
			title = "На четверых"
		}
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, notify, title, "tictactoe"); cerr == nil {
			chatIDStr = cid.String()
		}
	}

	// Ещё не полный состав — только дописываем игрока.
	if len(players) < cfg.MaxPlayers {
		pipe := h.Rdb.Pipeline()
		pipe.HSet(ctx, key,
			"player_ids", formatPlayerIDsCSV(players),
			"opponent_id", userID.String(),
			"variant", string(variant),
			"max_players", strconv.Itoa(cfg.MaxPlayers),
		)
		if chatIDStr != "" {
			pipe.HSet(ctx, key, "chat_id", chatIDStr)
		}
		pipe.Expire(ctx, key, lobbyTTL)
		if _, err := pipe.Exec(ctx); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return true
		}
		payload := map[string]any{
			"type":          "lobby_updated",
			"lobby_id":      lobbyID,
			"player_ids":    players,
			"players_count": len(players),
			"max_players":   cfg.MaxPlayers,
			"players":       h.loadLobbyPlayers(ctx, players),
		}
		if chatIDStr != "" {
			payload["chat_id"] = chatIDStr
		}
		h.broadcast(notify, payload)
		h.broadcast(notify, map[string]any{"type": "chat_list_changed"})
		setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
		resp := map[string]any{
			"lobby_id":   lobbyID,
			"status":     st,
			"created_at": m["created_at"],
			"creator_id": m["creator_id"],
		}
		if chatIDStr != "" {
			resp["chat_id"] = chatIDStr
		}
		writeJSON(w, http.StatusOK, resp)
		return true
	}

	// Полный состав — стартуем через обычный JoinLobby (идемпотентно допишет/запустит).
	// Откатываем append: JoinLobby сам добавит игрока.
	// Здесь players уже с новым — запускаем игру напрямую.
	uuids := notify
	for _, u := range uuids {
		pb, e := store.GetBalance(ctx, h.Pool, u)
		if e != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return true
		}
		if pb < stakeBronze {
			WriteErr(w, r, http.StatusConflict, "a player has insufficient balance")
			return true
		}
	}
	if err := store.DeductCoinsMany(ctx, h.Pool, uuids, stakeBronze); err != nil {
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		return true
	}
	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	assignment := assignMarksRandom(cfg.Marks, players, rand.Shuffle)
	board := emptyBoardJSON(gridSize)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"opponent_id", userID.String(),
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"variant", string(variant),
		"player_ids", formatPlayerIDsCSV(players),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
	)
	if chatIDStr != "" {
		pipe.HSet(ctx, key, "chat_id", chatIDStr)
	}
	pipe.Expire(ctx, key, 24*time.Hour)
	gameFields := []any{
		"board", board,
		"turn", cfg.Marks[0],
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
		"swap_rule", "false",
		"first_move_restriction", "false",
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", time.Now().UTC().Format(time.RFC3339Nano),
	}
	if chatIDStr != "" {
		gameFields = append(gameFields, "chat_id", chatIDStr)
	}
	gameFields = append(gameFields, markFieldsForRedis(assignment)...)
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, gameKey, gameFields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return true
	}
	for _, u := range uuids {
		clearUserActiveLobby(ctx, h.Rdb, u)
		setUserActiveGame(ctx, h.Rdb, u, gameID)
	}
	startPayload := map[string]any{
		"type":        "lobby_updated",
		"lobby_id":    lobbyID,
		"game_id":     gameID,
		"opponent_id": userID.String(),
	}
	if chatIDStr != "" {
		startPayload["chat_id"] = chatIDStr
	}
	h.broadcast(uuids, startPayload)
	h.publishGameStarted(uuids, gameID, lobbyID)
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id": lobbyID,
		"game_id":  gameID,
		"matched":  true,
	})
	return true
}

type RematchBody struct {
	GameID string `json:"game_id"`
}

func (h *GamesHandler) Rematch(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body RematchBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	gameID := strings.TrimSpace(body.GameID)
	if gameID == "" {
		WriteErr(w, r, http.StatusBadRequest, "game_id required")
		return
	}

	ctx := r.Context()
	gameKey := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, gameKey).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}

	me := userID.String()
	if markForUserID(m, me) == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}

	status := m["status"]
	if status == gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is not over")
		return
	}

	// Multi: приглашаем всех участников прошлой партии (включая вышедших с экрана).
	// 1v1: одного соперника — как раньше.
	inviteeIDs := rematchInviteeIDs(m, me)
	if len(inviteeIDs) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents to rematch")
		return
	}
	invitees := make([]uuid.UUID, 0, len(inviteeIDs))
	for _, id := range inviteeIDs {
		u, e := uuid.Parse(id)
		if e != nil {
			continue
		}
		invitees = append(invitees, u)
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusInternalServerError, "invalid opponent")
		return
	}

	// Всегда создаём лобби и отправляем приглашение. Игра начнётся только после
	// явного принятия (JoinLobby) всеми нужными игроками.
	lobbyID := uuid.New().String()
	key := "lobby:" + lobbyID
	invitedKey := key + ":invited"
	now := time.Now().UTC().Format(time.RFC3339Nano)
	turnTimeSec := 0
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		if gs := m["grid_size"]; gs != "" {
			if n, e := strconv.Atoi(gs); e == nil {
				return n
			}
		}
		return 3
	}())
	gridSize := cfg.GridSize
	if tt := m["turn_time_sec"]; tt != "" {
		if n, e := strconv.Atoi(tt); e == nil && validTurnTimeSec[n] {
			turnTimeSec = n
		}
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	// Для совместимости DeclineInvite/старых клиентов: первый invitee в invite_target_id.
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", "tictactoe",
		"creator_id", me,
		"status", lobbyStatusWaitingInvite,
		"invite_target_id", inviteeIDs[0],
		"created_at", now,
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
		"player_ids", me,
		"swap_rule", "false",
		"first_move_restriction", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	for _, id := range inviteeIDs {
		pipe.SAdd(ctx, invitedKey, id)
	}
	pipe.Expire(ctx, invitedKey, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	chatIDStr := ""
	if cfg.MaxPlayers > 2 {
		title := "Крестики-нолики"
		switch variant {
		case gameengine.VariantMulti3:
			title = "На троих"
		case gameengine.VariantMulti4:
			title = "На четверых"
		}
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, []uuid.UUID{userID}, title, "tictactoe"); cerr == nil {
			chatIDStr = cid.String()
			h.Rdb.HSet(ctx, key, "chat_id", chatIDStr)
			h.broadcast([]uuid.UUID{userID}, map[string]any{
				"type": "chat_list_changed",
			})
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
	broadcastData := map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    me,
		"creator_name":  creatorName,
		"game_type":     "tictactoe",
		"turn_time_sec": turnTimeSec,
		"variant":       string(variant),
		"grid_size":     gridSize,
		"max_players":   cfg.MaxPlayers,
		"stake_bronze":  stakeBronze,
	}
	if creatorAvatarKind != "" {
		broadcastData["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		broadcastData["creator_avatar_value"] = creatorAvatarValue
	}
	// WS + push всем соперникам (в т.ч. кто уже ушёл с экрана игры).
	h.broadcast(invitees, broadcastData)

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"lobby_id":      lobbyID,
		"status":        lobbyStatusWaitingInvite,
		"matched":       false,
		"invited_count": len(invitees),
		"max_players":   cfg.MaxPlayers,
	}
	if chatIDStr != "" {
		resp["chat_id"] = chatIDStr
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *GamesHandler) rdbRPOPMatchmake(ctx context.Context, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) (string, error) {
	return h.Rdb.RPop(ctx, matchmakeKey(turnTimeSec, gridSize, swapRule, firstMoveRestriction, stakeBronze)).Result()
}

func emptyBoardJSON(gridSize int) string {
	n := gridSize * gridSize
	// ultimate: grid_size=9 → 81 клетка; gomoku 15 → 225.
	if gridSize == 9 {
		n = 81
	}
	if n <= 0 || n > 225 {
		n = 9
	}
	b := make([]string, n)
	for i := range b {
		b[i] = ""
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

// createGameFromMatch создаёт игру после матчмейкинга.
// Если existingLobbyID не пуст — обновляет лобби ожидающего (чтобы WS
// game_started совпал с URL /lobby/{id} и сразу увёл его в игру).
func (h *GamesHandler) createGameFromMatch(ctx context.Context, user1, user2 uuid.UUID, existingLobbyID string, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int, variantStr string) (gameID, lobbyID string, err error) {
	_ = swapRule
	_ = firstMoveRestriction
	cfg, variant := resolveVariantConfig(variantStr, gridSize)
	gridSize = cfg.GridSize
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
	reuseLobby := strings.TrimSpace(existingLobbyID)
	lobbyID = reuseLobby
	if lobbyID == "" {
		lobbyID = uuid.New().String()
	}

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
		"mark_x", xUserID,
		"mark_o", oUserID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
		"swap_rule", "false",
		"first_move_restriction", "false",
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", time.Now().UTC().Format(time.RFC3339Nano),
	}
	if variant == gameengine.VariantUltimate {
		gameFields = append(gameFields, "next_board", "-1", "meta_board", formatMetaBoard(make([]string, 9)))
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, key, gameFields...)
	pipe.Expire(ctx, key, 24*time.Hour)

	if reuseLobby != "" {
		pipe.HSet(ctx, lobbyKey,
			"opponent_id", user1.String(),
			"status", lobbyStatusInGame,
			"game_id", gameID,
			"variant", string(variant),
		)
	} else {
		pipe.HSet(ctx, lobbyKey,
			"game_type", "tictactoe",
			"creator_id", user1.String(),
			"opponent_id", user2.String(),
			"status", lobbyStatusInGame,
			"game_id", gameID,
			"created_at", time.Now().UTC().Format(time.RFC3339Nano),
			"mode", "matchmake",
			"turn_time_sec", strconv.Itoa(turnTimeSec),
			"variant", string(variant),
			"grid_size", strconv.Itoa(gridSize),
			"max_players", strconv.Itoa(cfg.MaxPlayers),
			"swap_rule", "false",
			"first_move_restriction", "false",
			"stake_bronze", strconv.Itoa(stakeBronze),
		)
	}
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)

	_, err = pipe.Exec(ctx)
	return gameID, lobbyID, err
}

// createGameWithBot создаёт игру пользователь vs бот и обновляет существующее лобби.
func (h *GamesHandler) createGameWithBot(ctx context.Context, userID uuid.UUID, existingLobbyID string, turnTimeSec, gridSize int, swapRule, firstMoveRestriction bool, stakeBronze int) (gameID string, err error) {
	_ = swapRule
	_ = firstMoveRestriction
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
	variantStr := ""
	if existingLobbyID != "" {
		if lm, lerr := h.Rdb.HGetAll(ctx, "lobby:"+existingLobbyID).Result(); lerr == nil {
			variantStr = lm["variant"]
			if gs, e := strconv.Atoi(lm["grid_size"]); e == nil && gs > 0 {
				gridSize = gs
			}
		}
	}
	cfg, variant := resolveVariantConfig(variantStr, gridSize)
	// Бот только для 2-игровых режимов.
	if cfg.MaxPlayers != 2 {
		cfg, variant = resolveVariantConfig(string(gameengine.VariantClassic), 3)
	}
	gridSize = cfg.GridSize
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
		"mark_x", xUserID,
		"mark_o", oUserID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", "2",
		"swap_rule", "false",
		"first_move_restriction", "false",
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", time.Now().UTC().Format(time.RFC3339Nano),
	}
	if variant == gameengine.VariantUltimate {
		gameFields = append(gameFields, "next_board", "-1", "meta_board", formatMetaBoard(make([]string, 9)))
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
		"variant", string(variant),
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
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	eng, err := gameengine.New(variant)
	if err != nil {
		return false
	}
	st := engineStateFromRedis(m, cfg)
	legal := eng.LegalCells(st)
	if len(legal) == 0 {
		return false
	}
	cell := -1
	// Для классики — умный ход; иначе случайный легальный.
	if variant == gameengine.VariantClassic {
		cell = botPickCellSmart(st.Board, cfg.GridSize, st.Turn, false)
	}
	if cell < 0 {
		cell = legal[rand.Intn(len(legal))]
	}
	res, err := eng.ApplyMove(st, cell)
	if err != nil {
		return false
	}
	status, winner := statusFromEngineResult(res)
	pipe := h.Rdb.Pipeline()
	setFields := []any{
		"board", formatBoard(res.State.Board),
		"turn", res.State.Turn,
		"status", status,
	}
	if winner != "" {
		setFields = append(setFields, "winner", winner)
	}
	if variant == gameengine.VariantUltimate {
		setFields = append(setFields,
			"next_board", strconv.Itoa(res.State.NextBoard),
			"meta_board", formatMetaBoard(res.State.MetaBoard),
		)
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
	humans := humanUserIDsFromGame(m)
	if status != gameStatusActive {
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		finishedID := strings.TrimPrefix(key, "game:")
		h.onGameFinishedWithMap(ctx, finishedID, m, cfg.GridSize, stakeBronze, status, "normal", m["started_at"])
		clearUsersFinishedGame(ctx, h.Rdb, humans, finishedID)
		payload := map[string]any{
			"type": "game_state", "game_id": strings.TrimPrefix(key, "game:"),
			"board": res.State.Board, "turn": res.State.Turn, "winner": winner, "status": status,
			"variant": string(variant),
		}
		if len(res.WinningCells) > 0 {
			payload["winning_cells"] = res.WinningCells
		}
		h.broadcast(humans, payload)
	} else {
		gameID := strings.TrimPrefix(key, "game:")
		payload := map[string]any{
			"type": "game_state", "game_id": gameID,
			"board": res.State.Board, "turn": res.State.Turn, "status": status,
			"variant": string(variant),
		}
		if variant == gameengine.VariantUltimate {
			payload["next_board"] = res.State.NextBoard
			payload["meta_board"] = res.State.MetaBoard
		}
		if turnTimeSec > 0 {
			deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
			payload["turn_deadline"] = deadline
			payload["turn_time_sec"] = turnTimeSec
		}
		h.broadcast(humans, payload)
		h.notifyYourTurn(gameID, res.State.Turn, m)
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
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
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
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	ctx := r.Context()
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	var lobbies []LobbyItem
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil {
			continue
		}
		status := m["status"]
		// Публичный список: 1v1 matchmake + открытый multi find (mode=matchmake).
		// «Своя игра» (mode=invite) и реванш сюда не попадают.
		switch status {
		case lobbyStatusWaitingMatchmake:
			// ok
		case lobbyStatusWaitingInvite:
			if m["mode"] != "matchmake" {
				continue
			}
			if strings.TrimSpace(m["invite_target_id"]) != "" {
				continue
			}
		default:
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
		cfg, variant := resolveVariantConfig(m["variant"], gridSize)
		maxPlayers, _ := strconv.Atoi(m["max_players"])
		if maxPlayers < 1 {
			maxPlayers = cfg.MaxPlayers
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) == 0 {
			players = []string{creatorID}
		}
		if len(players) >= maxPlayers {
			continue
		}
		swapRule := m["swap_rule"] == "true"
		firstMoveRestriction := m["first_move_restriction"] == "true"
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		lobbies = append(lobbies, LobbyItem{
			ID:                   id,
			CreatorID:            creatorID,
			CreatorName:          creatorName,
			Status:               status,
			Mode:                 m["mode"],
			CreatedAt:            m["created_at"],
			TurnTimeSec:          turnTimeSec,
			Variant:              string(variant),
			GridSize:             cfg.GridSize,
			MaxPlayers:           maxPlayers,
			PlayersCount:         len(players),
			PlayerIDs:            players,
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
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		// TTL/уже закрыто — убрать устаревшие ссылки и групповой чат лобби.
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}

	creatorID := m["creator_id"]
	opponentID := m["opponent_id"]
	gameID := m["game_id"]
	status := m["status"]

	// Участники всегда видят лобби. Для открытого поиска и invite-по-ссылке
	// любой авторизованный пользователь может просмотреть waiting-лобби.
	inLobby := creatorID == userID.String() || opponentID == userID.String()
	if !inLobby {
		for _, p := range parsePlayerIDsCSV(m["player_ids"]) {
			if p == userID.String() {
				inLobby = true
				break
			}
		}
	}
	if !inLobby {
		if status != lobbyStatusWaitingMatchmake && status != lobbyStatusWaitingInvite {
			WriteErr(w, r, http.StatusForbidden, "forbidden")
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
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	gridSize := cfg.GridSize
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	playerIDs := parsePlayerIDsCSV(m["player_ids"])
	if len(playerIDs) == 0 {
		playerIDs = []string{creatorID}
	}
	chatIDStr := strings.TrimSpace(m["chat_id"])
	// Multi: синхронизируем групповой чат с текущим составом (реванш/старые лобби
	// могли остаться без chat_id или без записи в chat_members).
	if cfg.MaxPlayers > 2 &&
		(status == lobbyStatusWaitingInvite || status == lobbyStatusWaitingMatchmake || status == lobbyStatusInGame) {
		memberUUIDs := make([]uuid.UUID, 0, len(playerIDs))
		for _, p := range playerIDs {
			if u, e := uuid.Parse(p); e == nil {
				memberUUIDs = append(memberUUIDs, u)
			}
		}
		title := "Крестики-нолики"
		switch variant {
		case gameengine.VariantMulti3:
			title = "На троих"
		case gameengine.VariantMulti4:
			title = "На четверых"
		}
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, memberUUIDs, title, "tictactoe"); cerr == nil {
			chatIDStr = cid.String()
			if m["chat_id"] != chatIDStr {
				h.Rdb.HSet(ctx, key, "chat_id", chatIDStr)
			}
		}
	}
	item := LobbyItem{
		ID:           lobbyID,
		CreatorID:    creatorID,
		CreatorName:  creatorName,
		Status:       status,
		Mode:         m["mode"],
		CreatedAt:    m["created_at"],
		TurnTimeSec:  turnTimeSec,
		Variant:      string(variant),
		GridSize:     gridSize,
		MaxPlayers:   cfg.MaxPlayers,
		PlayersCount: len(playerIDs),
		PlayerIDs:    playerIDs,
		Players:      h.loadLobbyPlayers(ctx, playerIDs),
		ChatID:       chatIDStr,
		StakeBronze:  stakeBronze,
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

func (h *GamesHandler) loadLobbyPlayers(ctx context.Context, playerIDs []string) []LobbyPlayerItem {
	uids := make([]uuid.UUID, 0, len(playerIDs))
	for _, idStr := range playerIDs {
		if uid, err := uuid.Parse(idStr); err == nil {
			uids = append(uids, uid)
		}
	}
	users, _ := store.GetUsersByIDs(ctx, h.Pool, uids)
	out := make([]LobbyPlayerItem, 0, len(playerIDs))
	for _, idStr := range playerIDs {
		p := LobbyPlayerItem{ID: idStr, DisplayName: "Игрок"}
		uid, err := uuid.Parse(idStr)
		if err != nil {
			out = append(out, p)
			continue
		}
		if u := users[uid]; u != nil {
			if u.DisplayName != nil && *u.DisplayName != "" {
				p.DisplayName = *u.DisplayName
			}
			p.AvatarKind = u.AvatarKind
			p.AvatarValue = u.AvatarValue
		}
		out = append(out, p)
	}
	return out
}

func (h *GamesHandler) InviteToLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body InviteBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	friendID, err := uuid.Parse(strings.TrimSpace(body.FriendUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid friend_user_id")
		return
	}
	if friendID == userID {
		WriteErr(w, r, http.StatusBadRequest, "cannot invite yourself")
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["status"] != lobbyStatusWaitingInvite {
		WriteErr(w, r, http.StatusBadRequest, "lobby not in invite mode")
		return
	}
	// Приглашать может любой участник лобби (не только создатель) —
	// иначе после Join в multi «Своя игра» кнопка «Пригласить» даёт 403.
	players := parsePlayerIDsCSV(m["player_ids"])
	if len(players) == 0 {
		players = []string{m["creator_id"]}
	}
	isMember := false
	for _, p := range players {
		if p == userID.String() {
			isMember = true
			break
		}
	}
	if !isMember && m["creator_id"] != userID.String() {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	// Уже в лобби — повторно не зовём.
	for _, p := range players {
		if p == friendID.String() {
			WriteErr(w, r, http.StatusBadRequest, "user already in lobby")
			return
		}
	}

	friends, err := store.ListFriendships(ctx, h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
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
		WriteErr(w, r, http.StatusForbidden, "user is not your friend")
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
	cfg, variant := resolveVariantConfig(m["variant"], gridSize)
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 2 {
		maxPlayers = cfg.MaxPlayers
	}
	// game_type берём из лобби — handler общий для всех игр (durak и др.).
	gameType := strings.TrimSpace(m["game_type"])
	if gameType == "" {
		gameType = "tictactoe"
	}
	inviteData := map[string]any{
		"type":                   "game_invite",
		"lobby_id":               lobbyID,
		"creator_id":             userID.String(),
		"creator_name":           creatorName,
		"game_type":              gameType,
		"turn_time_sec":          turnTimeSec,
		"max_players":            maxPlayers,
		"stake_bronze":           stakeBronze,
	}
	if gameType == durakGameType {
		deckSize, _ := strconv.Atoi(m["deck_size"])
		if deckSize == 0 {
			deckSize = 36
		}
		gm := strings.TrimSpace(m["game_mode"])
		if gm == "" {
			gm = "podkidnoi"
		}
		inviteData["deck_size"] = deckSize
		inviteData["game_mode"] = gm
	} else {
		inviteData["variant"] = string(variant)
		inviteData["grid_size"] = cfg.GridSize
		inviteData["swap_rule"] = swapRule
		inviteData["first_move_restriction"] = firstMoveRestriction
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
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}

	creatorID := m["creator_id"]
	status := m["status"]

	if status == lobbyStatusInGame {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusConflict, "game already started with another opponent")
		return
	}

	if creatorID == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "cannot join own lobby")
		return
	}

	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		WriteErr(w, r, http.StatusBadRequest, "lobby not joinable")
		return
	}

	creatorUUID, _ := uuid.Parse(creatorID)

	if status == lobbyStatusWaitingInvite {
		lockKey := "rematch_lock:" + minUUID(creatorUUID, userID) + ":" + maxUUID(creatorUUID, userID)
		ok, _ := h.Rdb.SetNX(ctx, lockKey, "1", 15*time.Second).Result()
		if !ok {
			// Без Sleep на воркере — клиент сам обновит лобби/активную игру.
			for _, u := range []uuid.UUID{creatorUUID, userID} {
				if gid, _ := h.Rdb.Get(ctx, userActiveGameKey(u)).Result(); gid != "" {
					if gm, _ := h.Rdb.HGet(ctx, "game:"+gid, "status").Result(); gm == gameStatusActive {
						WriteErr(w, r, http.StatusConflict, "you or opponent already has an active game")
						return
					}
				}
			}
			WriteErr(w, r, http.StatusConflict, "game already created, refresh the page")
			return
		}
		defer h.Rdb.Del(ctx, lockKey)
	}

	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	gridSize := cfg.GridSize
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}

	players := parsePlayerIDsCSV(m["player_ids"])
	if len(players) == 0 {
		players = []string{creatorID}
	}
	alreadyMember := false
	for _, p := range players {
		if p == userID.String() {
			alreadyMember = true
			break
		}
	}
	// Уже в другой активной партии / своём лобби — нельзя принять новый инвайт.
	// Проверяем ДО alreadyMember: иначе повторный join в старое лобби реванша
	// обходил блокировку, пока идёт другая партия.
	// Выбывший в multi может смотреть и параллельно войти в новую игру.
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

	// Повторный join (двойной тап / перезаход) — не ошибка, а текущее состояние.
	if alreadyMember {
		setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
		chatIDStr := strings.TrimSpace(m["chat_id"])
		waitingMore := len(players) < cfg.MaxPlayers
		w.Header().Set("Content-Type", "application/json")
		resp := map[string]any{
			"joined":        true,
			"status":        status,
			"players_count": len(players),
			"max_players":   cfg.MaxPlayers,
			"waiting_more":  waitingMore,
			"already":       true,
		}
		if chatIDStr != "" {
			resp["chat_id"] = chatIDStr
		}
		if gid := strings.TrimSpace(m["game_id"]); gid != "" {
			resp["game_id"] = gid
			resp["waiting_more"] = false
		}
		_ = json.NewEncoder(w).Encode(resp)
		return
	}

	if len(players) >= cfg.MaxPlayers {
		WriteErr(w, r, http.StatusConflict, "lobby is full")
		return
	}

	bal, err := store.GetBalance(ctx, h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if bal < stakeBronze {
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		return
	}

	players = append(players, userID.String())
	if len(players) < cfg.MaxPlayers {
		// Ещё ждём игроков (multi3/multi4).
		pipe := h.Rdb.Pipeline()
		pipe.HSet(ctx, key,
			"player_ids", formatPlayerIDsCSV(players),
			"opponent_id", userID.String(),
			"variant", string(variant),
			"max_players", strconv.Itoa(cfg.MaxPlayers),
		)
		pipe.Expire(ctx, key, 24*time.Hour)
		if _, err := pipe.Exec(ctx); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		notify := make([]uuid.UUID, 0, len(players))
		memberUUIDs := make([]uuid.UUID, 0, len(players))
		for _, p := range players {
			if u, e := uuid.Parse(p); e == nil {
				notify = append(notify, u)
				memberUUIDs = append(memberUUIDs, u)
			}
		}
		chatIDStr := m["chat_id"]
		if cfg.MaxPlayers > 2 {
			title := "На троих"
			if variant == gameengine.VariantMulti4 {
				title = "На четверых"
			}
			if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, memberUUIDs, title, "tictactoe"); cerr == nil {
				chatIDStr = cid.String()
				h.Rdb.HSet(ctx, key, "chat_id", chatIDStr)
			}
		}
		payload := map[string]any{
			"type":          "lobby_updated",
			"lobby_id":      lobbyID,
			"player_ids":    players,
			"players_count": len(players),
			"max_players":   cfg.MaxPlayers,
			"players":       h.loadLobbyPlayers(ctx, players),
		}
		if chatIDStr != "" {
			payload["chat_id"] = chatIDStr
		}
		h.broadcast(notify, payload)
		h.broadcast(notify, map[string]any{"type": "chat_list_changed"})
		setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
		w.Header().Set("Content-Type", "application/json")
		resp := map[string]any{
			"joined":        true,
			"status":        status,
			"players_count": len(players),
			"max_players":   cfg.MaxPlayers,
			"waiting_more":  true,
		}
		if chatIDStr != "" {
			resp["chat_id"] = chatIDStr
		}
		_ = json.NewEncoder(w).Encode(resp)
		return
	}

	// Полный состав — стартуем игру.
	uuids := make([]uuid.UUID, 0, len(players))
	for _, p := range players {
		u, e := uuid.Parse(p)
		if e != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		uuids = append(uuids, u)
		pb, e := store.GetBalance(ctx, h.Pool, u)
		if e != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if pb < stakeBronze {
			WriteErr(w, r, http.StatusConflict, "a player has insufficient balance")
			return
		}
	}

	chatIDStr := m["chat_id"]
	if cfg.MaxPlayers > 2 {
		title := "На троих"
		if variant == gameengine.VariantMulti4 {
			title = "На четверых"
		}
		if cid, cerr := store.EnsureGameGroupChat(ctx, h.Pool, lobbyID, uuids, title, "tictactoe"); cerr == nil {
			chatIDStr = cid.String()
			h.Rdb.HSet(ctx, key, "chat_id", chatIDStr)
			h.broadcast(uuids, map[string]any{"type": "chat_list_changed"})
		}
	}

	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	assignment := assignMarksRandom(cfg.Marks, players, rand.Shuffle)
	board := emptyBoardJSON(gridSize)

	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"opponent_id", userID.String(),
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"variant", string(variant),
		"player_ids", formatPlayerIDsCSV(players),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
	)
	pipe.Expire(ctx, key, 24*time.Hour)
	if status == lobbyStatusWaitingMatchmake {
		pipe.LRem(ctx, matchmakeKeyVariant(turnTimeSec, variant, stakeBronze), 0, creatorID+":"+lobbyID)
	}

	if err := store.DeductCoinsMany(ctx, h.Pool, uuids, stakeBronze); err != nil {
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		return
	}

	gameFields := []any{
		"board", board,
		"turn", cfg.Marks[0],
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"variant", string(variant),
		"grid_size", strconv.Itoa(gridSize),
		"max_players", strconv.Itoa(cfg.MaxPlayers),
		"swap_rule", "false",
		"first_move_restriction", "false",
		"swapped", "false",
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", time.Now().UTC().Format(time.RFC3339Nano),
	}
	if chatIDStr != "" {
		gameFields = append(gameFields, "chat_id", chatIDStr)
	}
	gameFields = append(gameFields, markFieldsForRedis(assignment)...)
	if variant == gameengine.VariantUltimate {
		gameFields = append(gameFields, "next_board", "-1", "meta_board", formatMetaBoard(make([]string, 9)))
	}
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		gameFields = append(gameFields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, gameKey, gameFields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)

	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	for _, u := range uuids {
		clearUserActiveLobby(ctx, h.Rdb, u)
		setUserActiveGame(ctx, h.Rdb, u, gameID)
	}

	if status == lobbyStatusWaitingInvite {
		keys, _ := scanRedisKeys(ctx, h.Rdb, "lobby:*")
		for _, k := range keys {
			if k == key || strings.HasSuffix(k, ":invited") {
				continue
			}
			lm, _ := h.Rdb.HGetAll(ctx, k).Result()
			if lm["status"] != lobbyStatusWaitingInvite {
				continue
			}
			isReverse := lm["creator_id"] == userID.String() && lm["invite_target_id"] == creatorID
			isDupFromCreator := lm["creator_id"] == creatorID && lm["invite_target_id"] == userID.String()
			if !isReverse && !isDupFromCreator {
				continue
			}
			h.Rdb.Del(ctx, k)
			h.Rdb.Del(ctx, k+":invited")
			staleLobbyID := strings.TrimPrefix(k, "lobby:")
			if staleLobbyID != "" {
				h.cleanupInviteLobbyChatMessages(ctx, staleLobbyID)
				_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, staleLobbyID)
			}
			if isDupFromCreator && staleLobbyID != "" {
				h.broadcast([]uuid.UUID{userID}, map[string]any{
					"type":     "lobby_updated",
					"lobby_id": staleLobbyID,
					"left":     true,
				})
			}
		}
		h.Rdb.Del(ctx, key+":invited")
	}

	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)

	startPayload := map[string]any{
		"type":        "lobby_updated",
		"lobby_id":    lobbyID,
		"game_id":     gameID,
		"opponent_id": userID.String(),
	}
	if chatIDStr != "" {
		startPayload["chat_id"] = chatIDStr
	}
	h.broadcast(uuids, startPayload)
	h.publishGameStarted(uuids, gameID, lobbyID)

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"joined":  true,
		"game_id": gameID,
		"status":  lobbyStatusInGame,
	}
	if chatIDStr != "" {
		resp["chat_id"] = chatIDStr
	}
	_ = json.NewEncoder(w).Encode(resp)
}

// cleanupInviteLobbyChatMessages удаляет chat-сообщения со ссылкой на лобби
// (старт игры, закрытие лобби, отклонение инвайта) и шлёт realtime участникам.
func (h *GamesHandler) cleanupInviteLobbyChatMessages(ctx context.Context, lobbyID string) {
	if h == nil || h.Pool == nil {
		return
	}
	deleted, err := store.DeleteInviteLobbyShareMessages(ctx, h.Pool, lobbyID)
	if err != nil || len(deleted) == 0 {
		return
	}
	listChanged := make(map[uuid.UUID]struct{}, len(deleted)*2)
	for _, item := range deleted {
		h.broadcast([]uuid.UUID{item.LowUserID, item.HighUserID}, map[string]any{
			"type":       "chat_message_deleted",
			"chat_id":    item.ChatID.String(),
			"message_id": item.MessageID.String(),
		})
		listChanged[item.LowUserID] = struct{}{}
		listChanged[item.HighUserID] = struct{}{}
	}
	if len(listChanged) == 0 {
		return
	}
	ids := make([]uuid.UUID, 0, len(listChanged))
	for id := range listChanged {
		ids = append(ids, id)
	}
	h.broadcast(ids, map[string]any{"type": "chat_list_changed"})
}

// lobbyAudienceUUIDs — участники лобби + все, кому уже ушло приглашение
// (ещё не вступили в player_ids). Нужно, чтобы при роспуске снять карточки «Вас пригласили».
func (h *GamesHandler) lobbyAudienceUUIDs(ctx context.Context, key string, m map[string]string, playerIDs []string) []uuid.UUID {
	seen := make(map[string]struct{}, len(playerIDs)+4)
	out := make([]uuid.UUID, 0, len(playerIDs)+4)
	add := func(raw string) {
		s := strings.TrimSpace(raw)
		if s == "" {
			return
		}
		if _, ok := seen[s]; ok {
			return
		}
		u, err := uuid.Parse(s)
		if err != nil {
			return
		}
		seen[s] = struct{}{}
		out = append(out, u)
	}
	for _, p := range playerIDs {
		add(p)
	}
	add(m["creator_id"])
	add(m["opponent_id"])
	add(m["invite_target_id"])
	if h.Rdb != nil {
		if members, err := h.Rdb.SMembers(ctx, key+":invited").Result(); err == nil {
			for _, id := range members {
				add(id)
			}
		}
	}
	return out
}

func (h *GamesHandler) LeaveLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
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
		_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}

	creatorID := m["creator_id"]
	opponentID := m["opponent_id"]
	status := m["status"]
	players := parsePlayerIDsCSV(m["player_ids"])
	if len(players) == 0 {
		players = []string{creatorID}
	}

	if status == lobbyStatusInGame {
		WriteErr(w, r, http.StatusBadRequest, "game already started")
		return
	}

	inLobby := creatorID == userID.String() || opponentID == userID.String()
	for _, p := range players {
		if p == userID.String() {
			inLobby = true
			break
		}
	}
	if !inLobby {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}

	clearUserActiveLobby(ctx, h.Rdb, userID)

	// Создатель ушёл или остался один — закрываем лобби и групповой чат.
	dissolve := creatorID == userID.String()
	remaining := make([]string, 0, len(players))
	for _, p := range players {
		if p != userID.String() {
			remaining = append(remaining, p)
		}
	}
	if !dissolve && len(remaining) == 0 {
		dissolve = true
	}

	if dissolve {
		// Сначала собираем аудиторию (включая :invited), потом удаляем ключи.
		notifyIDs := h.lobbyAudienceUUIDs(ctx, key, m, players)
		h.Rdb.Del(ctx, key)
		h.Rdb.Del(ctx, key+":invited")
		if status == lobbyStatusWaitingMatchmake {
			turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
			stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
			_, variant := resolveVariantConfig(m["variant"], func() int {
				gs, _ := strconv.Atoi(m["grid_size"])
				return gs
			}())
			h.Rdb.LRem(ctx, matchmakeKeyVariant(turnTimeSec, variant, stakeBronze), 0, creatorID+":"+lobbyID)
		}
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
		h.broadcast(notifyIDs, map[string]any{
			"type":     "lobby_updated",
			"lobby_id": lobbyID,
			"left":     true,
			"closed":   true,
		})
		h.broadcast(notifyIDs, map[string]any{"type": "chat_list_changed"})
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"left": true, "closed": true})
		return
	}

	// Обычный участник вышел — лобби ждёт дальше.
	h.Rdb.HSet(ctx, key, "player_ids", formatPlayerIDsCSV(remaining))
	if opponentID == userID.String() {
		newOpp := ""
		for _, p := range remaining {
			if p != creatorID {
				newOpp = p
				break
			}
		}
		h.Rdb.HSet(ctx, key, "opponent_id", newOpp)
	}
	if chatIDStr := strings.TrimSpace(m["chat_id"]); chatIDStr != "" {
		if cid, e := uuid.Parse(chatIDStr); e == nil {
			_ = store.RemoveChatMember(ctx, h.Pool, cid, userID)
			h.broadcast([]uuid.UUID{userID}, map[string]any{"type": "chat_list_changed"})
		}
	}
	rest := make([]uuid.UUID, 0, len(remaining))
	for _, p := range remaining {
		if u, e := uuid.Parse(p); e == nil {
			rest = append(rest, u)
		}
	}
	h.broadcast(rest, map[string]any{
		"type":          "lobby_updated",
		"lobby_id":      lobbyID,
		"player_ids":    remaining,
		"players_count": len(remaining),
		"players":       h.loadLobbyPlayers(ctx, remaining),
		"left_user_id":  userID.String(),
	})
	h.broadcast(rest, map[string]any{"type": "chat_list_changed"})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"left": true, "closed": false})
}

func (h *GamesHandler) DeclineInvite(w http.ResponseWriter, r *http.Request, lobbyID string) {
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

	if m["status"] != lobbyStatusWaitingInvite {
		WriteErr(w, r, http.StatusBadRequest, "lobby invite expired")
		return
	}
	invitedKey := key + ":invited"
	isInvited, _ := h.Rdb.SIsMember(ctx, invitedKey, userID.String()).Result()
	if !isInvited && m["invite_target_id"] != userID.String() {
		WriteErr(w, r, http.StatusForbidden, "you are not invited")
		return
	}

	creatorID := m["creator_id"]
	creatorUUID, _ := uuid.Parse(creatorID)
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 1 {
		maxPlayers = 2
	}

	// Multi: один отказ не убивает реванш — убираем отказавшегося из invited.
	// Лобби закрываем, только если оставшихся приглашённых уже не хватает на состав.
	if maxPlayers > 2 {
		h.Rdb.SRem(ctx, invitedKey, userID.String())
		remaining, _ := h.Rdb.SMembers(ctx, invitedKey).Result()
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) == 0 {
			players = []string{creatorID}
		}
		canFill := len(players)+len(remaining) >= maxPlayers
		if canFill {
			// Частичный отказ: лобби живо, но инициатор реванша должен видеть,
			// кто уже ответил (зачёркивание в шапке игроков).
			h.broadcast([]uuid.UUID{creatorUUID}, map[string]any{
				"type":     "invite_declined",
				"lobby_id": lobbyID,
				"closed":   false,
				"user_id":  userID.String(),
			})
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"declined": true,
				"closed":   false,
			})
			return
		}
	}

	h.Rdb.Del(ctx, key)
	h.Rdb.Del(ctx, invitedKey)
	// Не трогаем active_game и чужие лобби — отказ от инвайта не должен
	// сбрасывать текущую партию отказавшегося.
	clearUserActiveLobbyIfMatch(ctx, h.Rdb, userID, lobbyID)
	clearUserActiveLobbyIfMatch(ctx, h.Rdb, creatorUUID, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)

	h.broadcast([]uuid.UUID{creatorUUID}, map[string]any{
		"type":     "invite_declined",
		"lobby_id": lobbyID,
		"closed":   true,
		"user_id":  userID.String(),
	})

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"declined": true, "closed": true})
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
	// При now == deadline время уже вышло (клиент показывает 0 с).
	if err != nil || time.Now().UTC().Unix() < deadline {
		return false
	}
	turn := m["turn"]
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	gridSize := cfg.GridSize
	gameID := strings.TrimPrefix(key, "game:")
	board := parseBoard(m["board"], gridSize)
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	humans := humanUserIDsFromGame(m)

	// Multi: таймаут = выбывание, как сдача.
	// Выбывший → observation (не active), пока партия не закроется.
	if cfg.MaxPlayers > 2 {
		eliminated := parseEliminatedMarks(m["eliminated_marks"])
		if !eliminated[turn] {
			eliminated[turn] = true
		}
		alive := aliveMarks(cfg.Marks, eliminated)
		elimCSV := formatEliminatedMarks(eliminated)
		if len(alive) <= 1 {
			winnerMark := ""
			if len(alive) == 1 {
				winnerMark = alive[0]
			}
			status := wonStatusForMark(winnerMark)
			h.Rdb.HSet(ctx, key,
				"status", status, "winner", winnerMark, "timeout", "1",
				"eliminated_marks", elimCSV,
			)
			h.Rdb.Expire(ctx, key, 24*time.Hour)
			h.onGameFinishedWithMap(ctx, gameID, m, gridSize, stakeBronze, status, "timeout", m["started_at"])
			clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
			h.broadcast(humans, map[string]any{
				"type": "game_state", "game_id": gameID,
				"board": board, "turn": winnerMark, "winner": winnerMark,
				"status": status, "timeout": true,
				"eliminated_marks": strings.Split(elimCSV, ","),
				"variant":         string(variant),
			})
			return true
		}
		next := nextAliveMark(cfg.Marks, turn, eliminated)
		fields := []any{"eliminated_marks", elimCSV, "turn", next, "timeout", "1"}
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		var newDeadline int64
		if turnTimeSec > 0 {
			newDeadline = time.Now().UTC().Unix() + int64(turnTimeSec)
			fields = append(fields, "turn_deadline", strconv.FormatInt(newDeadline, 10))
		}
		h.Rdb.HSet(ctx, key, fields...)
		h.Rdb.Expire(ctx, key, 24*time.Hour)
		// Выбывший: active снимаем, observation — пока партия не закончится.
		if timedOutID := markOwnerUserID(m, turn); timedOutID != "" {
			if u, e := uuid.Parse(timedOutID); e == nil {
				moveActiveToObserving(ctx, h.Rdb, u, gameID)
			}
		}
		payload := map[string]any{
			"type": "game_state", "game_id": gameID,
			"board": board, "turn": next, "status": gameStatusActive,
			"timeout": true, "eliminated_marks": strings.Split(elimCSV, ","),
			"variant": string(variant), "max_players": cfg.MaxPlayers,
		}
		if chatID := strings.TrimSpace(m["chat_id"]); chatID != "" {
			payload["chat_id"] = chatID
		}
		if turnTimeSec > 0 {
			payload["turn_time_sec"] = turnTimeSec
			payload["turn_deadline"] = newDeadline
		}
		h.broadcast(humans, payload)
		m2 := map[string]string{}
		for k, v := range m {
			m2[k] = v
		}
		m2["turn"] = next
		m2["eliminated_marks"] = elimCSV
		h.notifyYourTurn(gameID, next, m2)
		return true
	}

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
	h.onGameFinishedWithMap(ctx, gameID, m, gridSize, stakeBronze, status, "timeout", m["started_at"])
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	h.broadcast(humans, map[string]any{
		"type": "game_state", "game_id": gameID,
		"board": board, "turn": turn, "winner": winner, "status": status, "timeout": true,
	})
	return true
}

func (h *GamesHandler) GetGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if h.applyGameTimeout(ctx, key, m) {
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
	}

	allowed := false
	for _, id := range gamePlayerUserIDs(m) {
		if id == userID.String() {
			allowed = true
			break
		}
	}
	if !allowed {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}

	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	turn := m["turn"]
	botTurn := isBot(markOwnerUserID(m, turn))
	if botTurn && m["status"] == gameStatusActive {
		if h.applyBotMove(ctx, key, m) {
			m, _ = h.Rdb.HGetAll(ctx, key).Result()
		}
	}

	gridSize := cfg.GridSize
	board := parseBoard(m["board"], gridSize)
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	maxPlayers, _ := strconv.Atoi(m["max_players"])
	if maxPlayers < 1 {
		maxPlayers = cfg.MaxPlayers
	}
	elimMarks := parsePlayerIDsCSV(m["eliminated_marks"])
	item := GameStateItem{
		ID:              gameID,
		Board:           board,
		Turn:            m["turn"],
		Status:          m["status"],
		Variant:         string(variant),
		GridSize:        gridSize,
		MaxPlayers:      maxPlayers,
		XUserID:         m["x_user_id"],
		OUserID:         m["o_user_id"],
		TUserID:         m["t_user_id"],
		SUserID:         m["s_user_id"],
		CanSwap:         false,
		StakeBronze:     stakeBronze,
		Forfeit:         m["forfeit"] == "1",
		Timeout:         m["timeout"] == "1",
		DrawOfferBy:     m["draw_offer_by"],
		ChatID:          m["chat_id"],
		EliminatedMarks: elimMarks,
	}
	if variant == gameengine.VariantUltimate {
		nb := -1
		if v, e := strconv.Atoi(m["next_board"]); e == nil {
			nb = v
		}
		item.NextBoard = &nb
		item.MetaBoard = parseMetaBoard(m["meta_board"])
	}
	if w := m["winner"]; w != "" {
		item.Winner = &w
		eng, e := gameengine.New(variant)
		if e == nil {
			st := engineStateFromRedis(m, cfg)
			st.Status = "won"
			st.Winner = w
			// Подсветка: пересчёт по доске.
			if line := checkWinLine(board, w, gridSize); len(line) > 0 {
				item.WinningCells = line
			}
			_ = eng
		} else if line := checkWinLine(board, w, gridSize); len(line) > 0 {
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
	type sideMeta struct {
		uid   string
		setDN func(*string)
		setAK func(string)
		setAV func(*string)
		setFC func(string)
		setFCode func(string)
	}
	sides := []sideMeta{
		{
			uid: m["x_user_id"],
			setDN: func(v *string) { item.XDisplayName = v },
			setAK: func(v string) { item.XAvatarKind = v },
			setAV: func(v *string) { item.XAvatarValue = v },
			setFC: func(v string) { item.XFrameColor = v },
			setFCode: func(v string) { item.XFrameCode = v },
		},
		{
			uid: m["o_user_id"],
			setDN: func(v *string) { item.ODisplayName = v },
			setAK: func(v string) { item.OAvatarKind = v },
			setAV: func(v *string) { item.OAvatarValue = v },
			setFC: func(v string) { item.OFrameColor = v },
			setFCode: func(v string) { item.OFrameCode = v },
		},
		{
			uid: m["t_user_id"],
			setDN: func(v *string) { item.TDisplayName = v },
			setAK: func(v string) { item.TAvatarKind = v },
			setAV: func(v *string) { item.TAvatarValue = v },
			setFC: func(v string) { item.TFrameColor = v },
			setFCode: func(v string) { item.TFrameCode = v },
		},
		{
			uid: m["s_user_id"],
			setDN: func(v *string) { item.SDisplayName = v },
			setAK: func(v string) { item.SAvatarKind = v },
			setAV: func(v *string) { item.SAvatarValue = v },
			setFC: func(v string) { item.SFrameColor = v },
			setFCode: func(v string) { item.SFrameCode = v },
		},
	}
	frameIDs := make([]uuid.UUID, 0, 4)
	parsed := make(map[uuid.UUID]sideMeta, 4)
	for _, s := range sides {
		if strings.TrimSpace(s.uid) == "" {
			continue
		}
		if isBot(s.uid) {
			s.setDN(&botName)
			continue
		}
		id, err := uuid.Parse(s.uid)
		if err != nil {
			continue
		}
		frameIDs = append(frameIDs, id)
		parsed[id] = s
	}
	if users, err := store.GetUsersByIDs(ctx, h.Pool, frameIDs); err == nil {
		for id, s := range parsed {
			u := users[id]
			if u == nil {
				continue
			}
			if u.DisplayName != nil && *u.DisplayName != "" {
				s.setDN(u.DisplayName)
			}
			s.setAK(u.AvatarKind)
			s.setAV(u.AvatarValue)
		}
	}
	if frames, err := store.EquippedFramesMap(ctx, h.Pool, frameIDs); err == nil {
		for id, s := range parsed {
			if f, ok := frames[id]; ok {
				s.setFC(f.Color)
				s.setFCode(f.Code)
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(item)
}

func (h *GamesHandler) MakeMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body MoveBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	gridSize := cfg.GridSize
	maxCell := cfg.CellCount - 1
	if body.Cell < 0 || body.Cell > maxCell {
		WriteErr(w, r, http.StatusBadRequest, "cell must be 0-"+strconv.Itoa(maxCell))
		return
	}
	if h.applyGameTimeout(ctx, key, m) {
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
		board := parseBoard(m["board"], gridSize)
		w.Header().Set("Content-Type", "application/json")
		resp := map[string]any{
			"game_id": gameID, "board": board,
			"turn": m["turn"], "winner": m["winner"], "status": m["status"],
			"timeout": true, "grid_size": gridSize, "variant": string(variant),
			"max_players": cfg.MaxPlayers,
			"x_user_id":  m["x_user_id"], "o_user_id": m["o_user_id"],
		}
		if chatID := strings.TrimSpace(m["chat_id"]); chatID != "" {
			resp["chat_id"] = chatID
		}
		if m["t_user_id"] != "" {
			resp["t_user_id"] = m["t_user_id"]
		}
		if m["s_user_id"] != "" {
			resp["s_user_id"] = m["s_user_id"]
		}
		if elimCSV := strings.TrimSpace(m["eliminated_marks"]); elimCSV != "" {
			resp["eliminated_marks"] = strings.Split(elimCSV, ",")
		}
		h.addGamePlayerMetadataFromMap(ctx, resp, map[string]string{
			"x": m["x_user_id"], "o": m["o_user_id"],
			"t": m["t_user_id"], "s": m["s_user_id"],
		})
		_ = json.NewEncoder(w).Encode(resp)
		return
	}

	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}

	turn := m["turn"]
	myMark := markForUserID(m, userID.String())
	if myMark == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if parseEliminatedMarks(m["eliminated_marks"])[myMark] {
		WriteErr(w, r, http.StatusBadRequest, "you have forfeited")
		return
	}
	if markOwnerUserID(m, turn) != userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "not your turn")
		return
	}

	eng, err := gameengine.New(variant)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	st := engineStateFromRedis(m, cfg)
	res, err := eng.ApplyMove(st, body.Cell)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "illegal move")
		return
	}
	status, winner := statusFromEngineResult(res)
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	nextTurn := res.State.Turn
	if status == gameStatusActive {
		elim := parseEliminatedMarks(m["eliminated_marks"])
		nextTurn = skipToAliveTurn(cfg.Marks, nextTurn, elim)
		if elim[nextTurn] {
			// Все выбыли — не должно случиться; оставляем как есть.
		} else if nextTurn != res.State.Turn {
			res.State.Turn = nextTurn
		}
	}

	pipe := h.Rdb.Pipeline()
	setFields := []any{
		"board", formatBoard(res.State.Board),
		"turn", nextTurn,
		"status", status,
	}
	if winner != "" {
		setFields = append(setFields, "winner", winner)
	}
	if variant == gameengine.VariantUltimate {
		setFields = append(setFields,
			"next_board", strconv.Itoa(res.State.NextBoard),
			"meta_board", formatMetaBoard(res.State.MetaBoard),
		)
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
	hadDrawOffer := strings.TrimSpace(m["draw_offer_by"]) != ""
	if hadDrawOffer {
		pipe.HDel(ctx, key, "draw_offer_by")
	}

	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	humans := humanUserIDsFromGame(m)
	if status != gameStatusActive {
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.onGameFinishedWithMap(ctx, gameID, m, gridSize, stakeBronze, status, "normal", m["started_at"])
		clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	}

	broadcastPayload := map[string]any{
		"type": "game_state", "game_id": gameID,
		"board": res.State.Board, "turn": nextTurn, "winner": winner, "status": status,
		"variant": string(variant), "grid_size": gridSize, "can_swap": false,
	}
	if chatID := strings.TrimSpace(m["chat_id"]); chatID != "" {
		broadcastPayload["chat_id"] = chatID
	}
	if elimCSV := strings.TrimSpace(m["eliminated_marks"]); elimCSV != "" {
		broadcastPayload["eliminated_marks"] = strings.Split(elimCSV, ",")
	}
	if len(res.WinningCells) > 0 {
		broadcastPayload["winning_cells"] = res.WinningCells
	}
	if variant == gameengine.VariantUltimate {
		broadcastPayload["next_board"] = res.State.NextBoard
		broadcastPayload["meta_board"] = res.State.MetaBoard
	}
	if hadDrawOffer {
		broadcastPayload["draw_offer_by"] = ""
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		broadcastPayload["turn_deadline"] = deadline
		broadcastPayload["turn_time_sec"] = turnTimeSec
	}
	h.broadcast(humans, broadcastPayload)
	if status == gameStatusActive {
		// Обновляем turn в копии m для push.
		m2 := map[string]string{}
		for k, v := range m {
			m2[k] = v
		}
		m2["turn"] = nextTurn
		h.notifyYourTurn(gameID, nextTurn, m2)
	}

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"game_id":     gameID,
		"board":       res.State.Board,
		"turn":        nextTurn,
		"winner":      winner,
		"status":      status,
		"grid_size":   gridSize,
		"variant":     string(variant),
		"max_players": cfg.MaxPlayers,
		"x_user_id":   xUserID,
		"o_user_id":   oUserID,
		"can_swap":    false,
	}
	if chatID := strings.TrimSpace(m["chat_id"]); chatID != "" {
		resp["chat_id"] = chatID
	}
	if m["t_user_id"] != "" {
		resp["t_user_id"] = m["t_user_id"]
	}
	if m["s_user_id"] != "" {
		resp["s_user_id"] = m["s_user_id"]
	}
	if elimCSV := strings.TrimSpace(m["eliminated_marks"]); elimCSV != "" {
		resp["eliminated_marks"] = strings.Split(elimCSV, ",")
	}
	if len(res.WinningCells) > 0 {
		resp["winning_cells"] = res.WinningCells
	}
	if variant == gameengine.VariantUltimate {
		resp["next_board"] = res.State.NextBoard
		resp["meta_board"] = res.State.MetaBoard
	}
	if turnTimeSec > 0 && status == gameStatusActive {
		resp["turn_time_sec"] = turnTimeSec
		resp["turn_deadline"] = time.Now().UTC().Unix() + int64(turnTimeSec)
	}
	h.addGamePlayerMetadataFromMap(ctx, resp, map[string]string{
		"x": xUserID, "o": oUserID,
		"t": m["t_user_id"], "s": m["s_user_id"],
	})
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *GamesHandler) SwapSides(w http.ResponseWriter, r *http.Request, gameID string) {
	WriteErr(w, r, http.StatusGone, "swap sides removed")
}

func (h *GamesHandler) ForfeitGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	mark := markForUserID(m, userID.String())
	if mark == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	cfg, variant := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	gridSize := cfg.GridSize
	board := parseBoard(m["board"], gridSize)
	eliminated := parseEliminatedMarks(m["eliminated_marks"])
	if eliminated[mark] {
		WriteErr(w, r, http.StatusBadRequest, "already forfeited")
		return
	}

	// 2 игрока: сдача сразу завершает партию.
	if cfg.MaxPlayers <= 2 {
		status := gameStatusOWon
		winnerVal := "o"
		if mark == "o" {
			status = gameStatusXWon
			winnerVal = "x"
		}
		pipe := h.Rdb.Pipeline()
		pipe.HSet(ctx, key, "status", status, "forfeit", "1", "winner", winnerVal)
		pipe.Expire(ctx, key, 24*time.Hour)
		if _, err := pipe.Exec(ctx); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.onGameFinishedWithMap(ctx, gameID, m, gridSize, stakeBronze, status, "forfeit", m["started_at"])
		humansDone := humanUserIDsFromGame(m)
		clearUsersFinishedGame(ctx, h.Rdb, humansDone, gameID)
		h.broadcast(humansDone, map[string]any{
			"type": "game_state", "game_id": gameID,
			"board": board, "turn": m["turn"], "winner": winnerVal,
			"status": status, "forfeit": true, "variant": string(variant),
		})
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"status": status, "forfeit": true})
		return
	}

	// Multi: выбывание; играют оставшиеся, пока не останется один.
	// active_game держим до конца партии (см. applyGameTimeout).
	eliminated[mark] = true
	alive := aliveMarks(cfg.Marks, eliminated)
	elimCSV := formatEliminatedMarks(eliminated)
	humans := humanUserIDsFromGame(m)

	if len(alive) <= 1 {
		winnerMark := ""
		if len(alive) == 1 {
			winnerMark = alive[0]
		}
		status := wonStatusForMark(winnerMark)
		pipe := h.Rdb.Pipeline()
		pipe.HSet(ctx, key,
			"status", status,
			"winner", winnerMark,
			"forfeit", "1",
			"eliminated_marks", elimCSV,
		)
		pipe.Expire(ctx, key, 24*time.Hour)
		if _, err := pipe.Exec(ctx); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		h.onGameFinishedWithMap(ctx, gameID, m, gridSize, stakeBronze, status, "forfeit", m["started_at"])
		clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
		h.broadcast(humans, map[string]any{
			"type": "game_state", "game_id": gameID,
			"board": board, "turn": winnerMark, "winner": winnerMark,
			"status": status, "forfeit": true,
			"eliminated_marks": strings.Split(elimCSV, ","),
			"variant":         string(variant),
			"max_players":     cfg.MaxPlayers,
		})
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status": status, "forfeit": true, "winner": winnerMark,
			"eliminated_marks": strings.Split(elimCSV, ","),
		})
		return
	}

	turn := m["turn"]
	if turn == mark || eliminated[turn] {
		turn = nextAliveMark(cfg.Marks, mark, eliminated)
	}
	pipe := h.Rdb.Pipeline()
	fields := []any{"eliminated_marks", elimCSV, "turn", turn, "forfeit", "1"}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	if turnTimeSec > 0 {
		deadline := time.Now().UTC().Unix() + int64(turnTimeSec)
		fields = append(fields, "turn_deadline", strconv.FormatInt(deadline, 10))
	}
	pipe.HSet(ctx, key, fields...)
	pipe.Expire(ctx, key, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	// Выбывший больше не в active_game — observation до конца партии.
	moveActiveToObserving(ctx, h.Rdb, userID, gameID)
	payload := map[string]any{
		"type": "game_state", "game_id": gameID,
		"board": board, "turn": turn, "status": gameStatusActive,
		"forfeit": true, "eliminated_marks": strings.Split(elimCSV, ","),
		"variant": string(variant), "max_players": cfg.MaxPlayers,
		"left_user_id": userID.String(),
	}
	if chatID := strings.TrimSpace(m["chat_id"]); chatID != "" {
		payload["chat_id"] = chatID
	}
	if turnTimeSec > 0 {
		payload["turn_time_sec"] = turnTimeSec
		payload["turn_deadline"] = time.Now().UTC().Unix() + int64(turnTimeSec)
	}
	h.broadcast(humans, payload)
	m2 := map[string]string{}
	for k, v := range m {
		m2[k] = v
	}
	m2["turn"] = turn
	m2["eliminated_marks"] = elimCSV
	h.notifyYourTurn(gameID, turn, m2)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":           gameStatusActive,
		"forfeit":          true,
		"eliminated":       true,
		"turn":             turn,
		"eliminated_marks": strings.Split(elimCSV, ","),
	})
}

// OfferDraw предлагает ничью сопернику (только PvP 1v1).
func (h *GamesHandler) OfferDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	cfg, _ := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	if cfg.MaxPlayers > 2 {
		WriteErr(w, r, http.StatusBadRequest, "draw not available in multiplayer")
		return
	}
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if xUserID != userID.String() && oUserID != userID.String() {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	if isBot(xUserID) || isBot(oUserID) {
		WriteErr(w, r, http.StatusBadRequest, "draw not available vs bot")
		return
	}
	existing := strings.TrimSpace(m["draw_offer_by"])
	if existing == userID.String() {
		writeJSON(w, http.StatusOK, map[string]any{
			"offered":       true,
			"draw_offer_by": existing,
		})
		return
	}
	if existing != "" {
		WriteErr(w, r, http.StatusConflict, "opponent already offered draw")
		return
	}
	if err := h.Rdb.HSet(ctx, key, "draw_offer_by", userID.String()).Err(); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	// Предложение ничьи держится, пока кто-то не сделает ход или не примет её.
	// Сброс происходит в MakeMove (любой ход снимает draw_offer_by у обоих).
	h.broadcast(humanUserIDs(xUserID, oUserID), map[string]any{
		"type":          "game_state",
		"game_id":       gameID,
		"status":        gameStatusActive,
		"draw_offer_by": userID.String(),
	})
	writeJSON(w, http.StatusOK, map[string]any{
		"offered":       true,
		"draw_offer_by": userID.String(),
	})
}

// AcceptDraw принимает предложение ничьей от соперника.
func (h *GamesHandler) AcceptDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	cfg, _ := resolveVariantConfig(m["variant"], func() int {
		gs, _ := strconv.Atoi(m["grid_size"])
		return gs
	}())
	if cfg.MaxPlayers > 2 {
		WriteErr(w, r, http.StatusBadRequest, "draw not available in multiplayer")
		return
	}
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	if xUserID != userID.String() && oUserID != userID.String() {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	offerBy := strings.TrimSpace(m["draw_offer_by"])
	if offerBy == "" {
		WriteErr(w, r, http.StatusBadRequest, "no draw offer")
		return
	}
	if offerBy == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "cannot accept own draw offer")
		return
	}
	gridSize := 3
	if gs := m["grid_size"]; gs != "" {
		if n, e := strconv.Atoi(gs); e == nil && validGridSize[n] {
			gridSize = n
		}
	}
	board := parseBoard(m["board"], gridSize)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key, "status", gameStatusDraw)
	pipe.HDel(ctx, key, "draw_offer_by")
	pipe.Expire(ctx, key, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	h.onGameFinished(ctx, gameID, xUserID, oUserID, gridSize, stakeBronze, gameStatusDraw, "draw_agreement", m["started_at"])
	drawHumans := humanUserIDs(xUserID, oUserID)
	clearUsersFinishedGame(ctx, h.Rdb, drawHumans, gameID)
	h.broadcast(drawHumans, map[string]any{
		"type":    "game_state",
		"game_id": gameID,
		"board":   board,
		"turn":    m["turn"],
		"status":  gameStatusDraw,
	})
	writeJSON(w, http.StatusOK, map[string]any{"status": gameStatusDraw, "draw": true})
}

// publishGameStartedTyped — как publishGameStarted, но включает game_type в payload,
// чтобы клиент понял, в какой экран роутить `/games/<gameType>/game/...`.
func (h *GamesHandler) publishGameStartedTyped(userIDs []uuid.UUID, gameID, lobbyID, gameType string) {
	if gameType == "" {
		gameType = "tictactoe"
	}
	h.broadcast(userIDs, map[string]any{
		"type":      "game_started",
		"game_id":   gameID,
		"lobby_id":  lobbyID,
		"game_type": gameType,
	})
}

func (h *GamesHandler) publishGameStarted(userIDs []uuid.UUID, gameID, lobbyID string) {
	h.publishGameStartedTyped(userIDs, gameID, lobbyID, "tictactoe")
}

// notifyYourTurn шлёт Web Push игроку, чей сейчас ход (если это человек).
// Показ на клиенте подавляется SW, если пользователь уже смотрит этот матч.
func (h *GamesHandler) notifyYourTurn(gameID, nextTurn string, m map[string]string) {
	if h.Push == nil || strings.TrimSpace(gameID) == "" {
		return
	}
	nextID := markOwnerUserID(m, nextTurn)
	if nextID == "" || isBot(nextID) {
		return
	}
	uid, err := uuid.Parse(nextID)
	if err != nil {
		return
	}
	lang := i18n.LangRU
	h.Push.NotifyUsers([]uuid.UUID{uid}, store.WebPushCategoryGames, PushPayload{
		Title: i18n.Content(lang, "push.your_turn_title"),
		Body:  i18n.Content(lang, "push.your_turn_body"),
		URL:   "/games/tictactoe/game/" + gameID,
		Tag:   "game_turn_" + gameID,
		Kind:  "game_turn",
	})
}

func (h *GamesHandler) broadcast(userIDs []uuid.UUID, payload map[string]any) {
	if h.Broadcaster != nil && h.Broadcaster.Rdb != nil {
		h.Broadcaster.Publish(userIDs, payload)
	} else if h.Hub != nil {
		h.Hub.PublishToUsers(userIDs, payload)
	}
	if h.Push == nil || len(userIDs) == 0 {
		return
	}
	typ, _ := payload["type"].(string)
	if typ != "game_invite" {
		return
	}
	lang := i18n.LangRU
	name, _ := payload["creator_name"].(string)
	if strings.TrimSpace(name) == "" {
		name = i18n.Content(lang, "common.player")
	}
	lobbyID, _ := payload["lobby_id"].(string)
	gameType, _ := payload["game_type"].(string)
	if strings.TrimSpace(gameType) == "" {
		gameType = "tictactoe"
	}
	url := "/games"
	if lobbyID != "" {
		url = "/games/" + gameType + "/lobby/" + lobbyID
	}
	h.Push.NotifyUsers(userIDs, store.WebPushCategoryGames, PushPayload{
		Title: i18n.Content(lang, "push.game_invite_title"),
		Body:  i18n.Contentf(lang, "push.game_invite_body", map[string]string{"name": name}),
		URL:   url,
		Tag:   "game_invite_" + lobbyID,
		Kind:  "game_invite",
	})
}

func userActiveGameKey(userID uuid.UUID) string     { return "user:" + userID.String() + ":active_game" }
func userActiveLobbyKey(userID uuid.UUID) string    { return "user:" + userID.String() + ":active_lobby" }
func userObservingGameKey(userID uuid.UUID) string { return "user:" + userID.String() + ":observing_game" }

// blockingActiveGameID — id живой партии, где пользователь ещё играет (не наблюдает).
// Пустая строка = можно создавать/входить в другую игру.
func (h *GamesHandler) blockingActiveGameID(ctx context.Context, userID uuid.UUID) string {
	gid, err := h.Rdb.Get(ctx, userActiveGameKey(userID)).Result()
	if err != nil || gid == "" {
		return ""
	}
	gm, _ := h.Rdb.HGetAll(ctx, "game:"+gid).Result()
	if len(gm) == 0 || gm["status"] != gameStatusActive {
		// Протухший указатель после конца партии — не блокируем create/find.
		clearUserActiveGame(ctx, h.Rdb, userID)
		return ""
	}
	// Durak: участие определяется по player_ids CSV.
	if gm["game_type"] == durakGameType {
		players := parsePlayerIDsCSV(gm["player_ids"])
		for _, p := range players {
			if p == userID.String() {
				return gid
			}
		}
		clearUserActiveGame(ctx, h.Rdb, userID)
		return ""
	}
	mark := markForUserID(gm, userID.String())
	if mark == "" {
		clearUserActiveGame(ctx, h.Rdb, userID)
		return ""
	}
	// Выбывший не должен оставаться в active_game — переносим в observation.
	if parseEliminatedMarks(gm["eliminated_marks"])[mark] {
		clearUserActiveGame(ctx, h.Rdb, userID)
		setUserObservingGame(ctx, h.Rdb, userID, gid)
		return ""
	}
	return gid
}

// moveActiveToObserving — выбывание в multi: active снимаем, observation держим до конца партии.
func moveActiveToObserving(ctx context.Context, rdb *redis.Client, userID uuid.UUID, gameID string) {
	clearUserActiveGame(ctx, rdb, userID)
	setUserObservingGame(ctx, rdb, userID, gameID)
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

// onGameFinished — монеты + счётчик партий/достижения для людей (не ботов) +
// запись результата в историю game_results (для статистики и head-to-head).
func (h *GamesHandler) onGameFinished(
	ctx context.Context,
	gameID string,
	xUserID, oUserID string,
	gridSize, stakeBronze int,
	status, finishReason string,
	startedAtRaw string,
) {
	h.onGameFinishedWithMap(ctx, gameID, map[string]string{
		"x_user_id": xUserID,
		"o_user_id": oUserID,
	}, gridSize, stakeBronze, status, finishReason, startedAtRaw)
}

func (h *GamesHandler) onGameFinishedWithMap(
	ctx context.Context,
	gameID string,
	m map[string]string,
	gridSize, stakeBronze int,
	status, finishReason string,
	startedAtRaw string,
) {
	xUserID := m["x_user_id"]
	oUserID := m["o_user_id"]
	h.settleGameCoinsMulti(ctx, m, stakeBronze, status)
	for _, uid := range gamePlayerUserIDs(m) {
		if uid == "" || isBot(uid) {
			continue
		}
		if u, err := uuid.Parse(uid); err == nil {
			_ = store.IncrementGamesFinished(ctx, h.Pool, u)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
			notifyAchievementUnlocks(h.Push, u, unlocked)
		}
	}
	// Multi: лобби завершается вместе с партией → удаляем групповой чат.
	if lobbyID := strings.TrimSpace(m["lobby_id"]); lobbyID != "" {
		maxPlayers, _ := strconv.Atoi(m["max_players"])
		if maxPlayers > 2 || m["t_user_id"] != "" || m["s_user_id"] != "" {
			if h.Rdb != nil {
				h.Rdb.Del(ctx, "lobby:"+lobbyID)
				h.Rdb.Del(ctx, "lobby:"+lobbyID+":invited")
				if gameID != "" {
					h.Rdb.HDel(ctx, "game:"+gameID, "chat_id")
				}
			}
			_ = store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID)
			h.broadcast(humanUserIDsFromGame(m), map[string]any{
				"type":     "lobby_updated",
				"lobby_id": lobbyID,
				"left":     true,
				"closed":   true,
			})
			h.broadcast(humanUserIDsFromGame(m), map[string]any{"type": "chat_list_changed"})
		}
	}
	winnerMark := ""
	switch status {
	case gameStatusXWon:
		winnerMark = "x"
	case gameStatusOWon:
		winnerMark = "o"
	case gameStatusTWon:
		winnerMark = "t"
	case gameStatusSWon:
		winnerMark = "s"
	}
	if winnerMark != "" {
		if wid := markOwnerUserID(m, winnerMark); wid != "" && !isBot(wid) {
			if u, err := uuid.Parse(wid); err == nil {
				_ = store.IncrementWinsByStake(ctx, h.Pool, u, stakeBronze)
				unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
				notifyAchievementUnlocks(h.Push, u, unlocked)
			}
		}
	}
	h.recordGameResult(ctx, gameID, xUserID, oUserID, gridSize, stakeBronze, status, finishReason, startedAtRaw)
}

func (h *GamesHandler) settleGameCoinsMulti(ctx context.Context, m map[string]string, stakeBronze int, status string) {
	if stakeBronze <= 0 {
		return
	}
	players := gamePlayerUserIDs(m)
	if len(players) == 0 {
		return
	}
	winnerMark := ""
	switch status {
	case gameStatusXWon:
		winnerMark = "x"
	case gameStatusOWon:
		winnerMark = "o"
	case gameStatusTWon:
		winnerMark = "t"
	case gameStatusSWon:
		winnerMark = "s"
	}
	if len(players) == 2 {
		h.settleGameCoins(ctx, m["x_user_id"], m["o_user_id"], stakeBronze, status)
		return
	}
	// N игроков: банк stake*N победителю; при ничьей — возврат ставки каждому.
	if winnerMark == "" {
		for _, p := range players {
			if isBot(p) {
				continue
			}
			if u, e := uuid.Parse(p); e == nil {
				_ = store.AddCoins(ctx, h.Pool, u, stakeBronze)
			}
		}
		return
	}
	winnerID := markOwnerUserID(m, winnerMark)
	if winnerID == "" || isBot(winnerID) {
		return
	}
	if u, e := uuid.Parse(winnerID); e == nil {
		_ = store.AddCoins(ctx, h.Pool, u, stakeBronze*len(players))
	}
}

// recordGameResult сохраняет результат партии в game_results (для статистики).
func (h *GamesHandler) recordGameResult(
	ctx context.Context,
	gameID, xUserID, oUserID string,
	gridSize, stakeBronze int,
	status, finishReason, startedAtRaw string,
) {
	if gameID == "" || (xUserID == "" && oUserID == "") {
		return
	}
	// Определяем победителя по статусу.
	var winnerID string
	switch status {
	case gameStatusXWon:
		winnerID = xUserID
	case gameStatusOWon:
		winnerID = oUserID
	case gameStatusTWon, gameStatusSWon:
		// Для multi победитель уже в Redis; здесь x/o-only запись — winner пустой.
		winnerID = ""
	}
	againstBot := isBot(xUserID) || isBot(oUserID)

	gr := store.GameResult{
		GameID:       gameID,
		GameType:     "tictactoe",
		Result:       status,
		FinishReason: finishReason,
		GridSize:     gridSize,
		StakeBronze:  stakeBronze,
		AgainstBot:   againstBot,
	}
	if xID, err := uuid.Parse(xUserID); err == nil {
		gr.XUserID = xID
	}
	if oID, err := uuid.Parse(oUserID); err == nil {
		gr.OUserID = oID
	}
	if winnerID != "" && !isBot(winnerID) {
		if wID, err := uuid.Parse(winnerID); err == nil {
			gr.WinnerUserID = &wID
		}
	}
	if t, ok := parseGameStartedAt(startedAtRaw); ok {
		gr.DurationSec = clampNonNegative(int(time.Since(t).Seconds()))
	}
	_ = store.RecordGameResult(ctx, h.Pool, gr)
}

// parseGameStartedAt разбирает RFC3339Nano-время старта партии из Redis.
func parseGameStartedAt(raw string) (time.Time, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}, false
	}
	t, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil {
		return time.Time{}, false
	}
	return t, true
}

func clampNonNegative(v int) int {
	if v < 0 {
		return 0
	}
	return v
}

func (h *GamesHandler) recordGameWin(ctx context.Context, xUserID, oUserID string, stakeBronze int, status string) {
	winnerID := ""
	switch status {
	case gameStatusXWon:
		winnerID = xUserID
	case gameStatusOWon:
		winnerID = oUserID
	case gameStatusTWon, gameStatusSWon:
		return
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
	unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, uid)
	notifyAchievementUnlocks(h.Push, uid, unlocked)
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
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, uid)
		notifyAchievementUnlocks(h.Push, uid, unlocked)
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

// clearUserActiveLobbyIfMatch сбрасывает active_lobby только если он указывает
// на lobbyID — иначе отказ/закрытие чужого инвайта затирало текущую сессию.
func clearUserActiveLobbyIfMatch(ctx context.Context, rdb *redis.Client, userID uuid.UUID, lobbyID string) {
	if rdb == nil || lobbyID == "" {
		return
	}
	cur, err := rdb.Get(ctx, userActiveLobbyKey(userID)).Result()
	if err != nil || cur != lobbyID {
		return
	}
	rdb.Del(ctx, userActiveLobbyKey(userID))
}

func setUserObservingGame(ctx context.Context, rdb *redis.Client, userID uuid.UUID, gameID string) {
	if rdb == nil || gameID == "" {
		return
	}
	rdb.Set(ctx, userObservingGameKey(userID), gameID, 24*time.Hour)
}

func clearUserObservingGame(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if rdb == nil {
		return
	}
	rdb.Del(ctx, userObservingGameKey(userID))
}

func clearUserObservingGameIfMatch(ctx context.Context, rdb *redis.Client, userID uuid.UUID, gameID string) {
	if rdb == nil || gameID == "" {
		return
	}
	cur, err := rdb.Get(ctx, userObservingGameKey(userID)).Result()
	if err != nil || cur != gameID {
		return
	}
	rdb.Del(ctx, userObservingGameKey(userID))
}

// observationPayload — карточка «Наблюдение», пока партия ещё идёт.
func (h *GamesHandler) observationPayload(ctx context.Context, userID uuid.UUID) map[string]any {
	if h.Rdb == nil {
		return nil
	}
	gameID, err := h.Rdb.Get(ctx, userObservingGameKey(userID)).Result()
	if err != nil || gameID == "" {
		return nil
	}
	m, _ := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if len(m) == 0 || m["status"] != gameStatusActive {
		clearUserObservingGame(ctx, h.Rdb, userID)
		return nil
	}
	if markForUserID(m, userID.String()) == "" {
		clearUserObservingGame(ctx, h.Rdb, userID)
		return nil
	}
	return map[string]any{
		"game_id":  gameID,
		"lobby_id": m["lobby_id"],
	}
}

func writeActiveJSON(w http.ResponseWriter, active map[string]any, observation map[string]any) {
	if len(active) == 0 && len(observation) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	resp := map[string]any{}
	for k, v := range active {
		resp[k] = v
	}
	if len(observation) > 0 {
		resp["observation"] = observation
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *GamesHandler) GetActive(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()

	var active map[string]any

	gameID, err := h.Rdb.Get(ctx, userActiveGameKey(userID)).Result()
	if err == nil && gameID != "" {
		key := "game:" + gameID
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err == nil && len(m) > 0 {
			// Протухший ход применяем и здесь — иначе «Игры» показывает
			// чужой/старый ход, пока кто-то не откроет GetGame.
			if m["status"] == gameStatusActive && h.applyGameTimeout(ctx, key, m) {
				m, _ = h.Rdb.HGetAll(ctx, key).Result()
			}
		}
		if err == nil && len(m) > 0 && m["status"] == gameStatusActive {
			if m["game_type"] == durakGameType {
				// Durak: определяем участие по player_ids CSV (нет x/o marks).
				players := parsePlayerIDsCSV(m["player_ids"])
				inGame := false
				for _, p := range players {
					if p == userID.String() {
						inGame = true
						break
					}
				}
				if !inGame {
					clearUserActiveGame(ctx, h.Rdb, userID)
				} else {
					active = map[string]any{
						"type":      "game",
						"game_id":   gameID,
						"lobby_id":  m["lobby_id"],
						"game_type": durakGameType,
					}
				}
			} else {
				myMark := markForUserID(m, userID.String())
				if myMark == "" {
					clearUserActiveGame(ctx, h.Rdb, userID)
				} else if parseEliminatedMarks(m["eliminated_marks"])[myMark] {
					// Миграция: выбывший больше не в active, а в observation.
					moveActiveToObserving(ctx, h.Rdb, userID, gameID)
				} else {
					active = map[string]any{
						"type":       "game",
						"game_id":    gameID,
						"lobby_id":   m["lobby_id"],
						"is_my_turn": m["turn"] == myMark,
						"game_type":  "tictactoe",
					}
				}
			}
		} else {
			clearUserActiveGame(ctx, h.Rdb, userID)
		}
	}

	if len(active) == 0 {
		lobbyID, lerr := h.Rdb.Get(ctx, userActiveLobbyKey(userID)).Result()
		if lerr == nil && lobbyID != "" {
			m, merr := h.Rdb.HGetAll(ctx, "lobby:"+lobbyID).Result()
			if merr == nil && len(m) > 0 {
				gt := m["game_type"]
				if gt == "" {
					gt = "tictactoe"
				}
				active = map[string]any{
					"type":      "lobby",
					"lobby_id":  lobbyID,
					"game_type": gt,
				}
			} else {
				clearUserActiveLobby(ctx, h.Rdb, userID)
			}
		}
	}

	writeActiveJSON(w, active, h.observationPayload(ctx, userID))
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
	if gridSize == 9 {
		n = 81 // ultimate
	}
	if n <= 0 || n > 225 {
		n = 9
	}
	if len(b) == n {
		return b
	}
	// Доверяем только известным размерам вариантов (gomoku/ultimate/multi).
	switch len(b) {
	case 9, 64, 81, 100, 225:
		return b
	default:
		return make([]string, n)
	}
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

// GetStats — GET /api/games/stats — агрегированная статистика текущего игрока
// (победы/ничьи/поражения, всего партий, win-rate, суммарное время в игре)
// и топ соперников (больше всего побед/поражений).
func (h *GamesHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	currentID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	// Опциональный user_id: если задан и не равен текущему — статистика
	// другого игрока (для перехода из попапа профиля). Иначе — своя.
	targetID := currentID
	if raw := strings.TrimSpace(r.URL.Query().Get("user_id")); raw != "" {
		if parsed, err := uuid.Parse(raw); err == nil {
			targetID = parsed
		}
	}
	ctx := r.Context()
	if targetID != currentID {
		target, err := store.GetUserByID(ctx, h.Pool, targetID)
		if err != nil {
			WriteErr(w, r, http.StatusNotFound, "user not found")
			return
		}
		if !target.ShowStatsToOthers {
			WriteErr(w, r, http.StatusForbidden, "stats are private")
			return
		}
	}
	stats, err := store.GetGameStats(ctx, h.Pool, targetID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	byGame, err := store.GetGameStatsByType(ctx, h.Pool, targetID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	topWon, err := store.GetTopOpponents(ctx, h.Pool, targetID, "won", 3, "")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	topDrawn, err := store.GetTopOpponents(ctx, h.Pool, targetID, "drawn", 3, "")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	topLost, err := store.GetTopOpponents(ctx, h.Pool, targetID, "lost", 3, "")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if byGame == nil {
		byGame = []store.GameTypeStats{}
	}
	for i := range byGame {
		gWon, err := store.GetTopOpponents(ctx, h.Pool, targetID, "won", 3, byGame[i].GameType)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		gDrawn, err := store.GetTopOpponents(ctx, h.Pool, targetID, "drawn", 3, byGame[i].GameType)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		gLost, err := store.GetTopOpponents(ctx, h.Pool, targetID, "lost", 3, byGame[i].GameType)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if gWon == nil {
			gWon = []store.OpponentStat{}
		}
		if gDrawn == nil {
			gDrawn = []store.OpponentStat{}
		}
		if gLost == nil {
			gLost = []store.OpponentStat{}
		}
		byGame[i].TopWon = gWon
		byGame[i].TopDrawn = gDrawn
		byGame[i].TopLost = gLost
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"wins":               stats.Wins,
		"draws":              stats.Draws,
		"losses":             stats.Losses,
		"total_played":       stats.TotalPlayed,
		"win_rate":           stats.WinRate(),
		"total_duration_sec": stats.TotalDurationSec,
		"games":              byGame,
		"top_won":            topWon,
		"top_drawn":          topDrawn,
		"top_lost":           topLost,
	})
}

// GetHeadToHead — GET /api/games/head-to-head?user_id=<uuid> — счёт между
// текущим игроком и указанным соперником (только живые PvP, без ботов).
func (h *GamesHandler) GetHeadToHead(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	opponentIDStr := strings.TrimSpace(r.URL.Query().Get("user_id"))
	opponentID, err := uuid.Parse(opponentIDStr)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	if opponentID == userID {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	ctx := r.Context()
	h2h, err := store.GetHeadToHead(ctx, h.Pool, userID, opponentID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	showStats := false
	if opponent, err := store.GetUserByID(ctx, h.Pool, opponentID); err == nil && opponent != nil {
		showStats = opponent.ShowStatsToOthers
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"opponent_id":          h2h.OpponentID,
		"display_name":         h2h.DisplayName,
		"won":                  h2h.Won,
		"drawn":                h2h.Drawn,
		"lost":                 h2h.Lost,
		"games":                h2h.Games,
		"show_stats_to_others": showStats,
	})
}
