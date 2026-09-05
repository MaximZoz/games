package api

import (
	"context"
	"encoding/json"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/connect4"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func connect4Spec() simple1v1 {
	return simple1v1{
		gameType:      store.GameTypeConnect4,
		botID:         connect4.BotID,
		normalizeMode: connect4.NormalizeMode,
		newState: func(mode string) (string, int, error) {
			g := connect4.NewGame(mode)
			raw, err := connect4.Encode(g)
			return raw, g.Turn, err
		},
		isOver: func(encoded string) bool {
			g, err := connect4.Decode(encoded)
			return err == nil && g.IsOver()
		},
		winner: func(encoded string) int {
			g, err := connect4.Decode(encoded)
			if err != nil {
				return connect4.WinnerNone
			}
			return g.Winner
		},
		isBotTurn: func(encoded string, players []string) bool {
			g, err := connect4.Decode(encoded)
			if err != nil || g.IsOver() || g.Turn < 0 || g.Turn >= len(players) {
				return false
			}
			return isBot(players[g.Turn])
		},
	}
}

func (h *GamesHandler) serveConnect4(w http.ResponseWriter, r *http.Request) {
	s := connect4Spec()
	path := strings.TrimPrefix(r.URL.Path, "/api/games/connect4/")
	parts := strings.Split(path, "/")
	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.createSimple1v1Lobby(s, w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.rematchSimple1v1(s, w, r)
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
			h.joinSimple1v1Lobby(s, w, r, lobbyID)
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
			h.getConnect4Game(w, r, gameID)
		case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
			h.connect4Move(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.connect4Forfeit(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw" && r.Method == http.MethodPost:
			h.OfferDraw(w, r, gameID)
		case len(parts) == 3 && parts[2] == "accept-draw" && r.Method == http.MethodPost:
			h.acceptSimple1v1Draw(s, func(enc string) (string, error) {
				g, err := connect4.Decode(enc)
				if err != nil {
					return "", err
				}
				g.AgreeDraw()
				return connect4.Encode(g)
			}, w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

func (h *GamesHandler) applyConnect4Timeout(ctx context.Context, gameID string, m map[string]string) bool {
	return h.applySimple1v1Timeout(ctx, connect4Spec(), gameID, m, func(enc string, seat int) (string, error) {
		g, err := connect4.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return connect4.Encode(g)
	})
}

func (h *GamesHandler) getConnect4Game(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != store.GameTypeConnect4 {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	s := connect4Spec()
	h.applySimple1v1Timeout(ctx, s, gameID, m, func(enc string, seat int) (string, error) {
		g, err := connect4.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return connect4.Encode(g)
	})
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	state, err := connect4.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if m["status"] == gameStatusActive && s.isBotTurn(m["state"], parsePlayerIDsCSV(m["player_ids"])) {
		h.scheduleConnect4Bot(gameID)
	}
	writeJSON(w, http.StatusOK, h.connect4View(ctx, state, userID.String(), m, gameID))
}

func (h *GamesHandler) connect4Move(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body struct {
		Col int `json:"col"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if err := h.applyConnect4Action(r.Context(), gameID, userID, "move", body.Col); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (h *GamesHandler) connect4Forfeit(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := h.applyConnect4Action(r.Context(), gameID, userID, "forfeit", 0); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "forfeit": true})
}

func (h *GamesHandler) applyConnect4Action(ctx context.Context, gameID string, userID uuid.UUID, action string, col int) error {
	s := connect4Spec()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return &simple1v1HTTPError{status: http.StatusNotFound, msg: "game not found"}
	}
	if m["game_type"] != store.GameTypeConnect4 {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "wrong game type"}
	}
	h.applySimple1v1Timeout(ctx, s, gameID, m, func(enc string, seat int) (string, error) {
		g, err := connect4.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return connect4.Encode(g)
	})
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "game is over"}
	}
	state, err := connect4.Decode(m["state"])
	if err != nil {
		return &simple1v1HTTPError{status: http.StatusInternalServerError, msg: "bad state"}
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := simple1v1SeatOf(players, userID.String())
	if seat < 0 {
		return &simple1v1HTTPError{status: http.StatusForbidden, msg: "not a player"}
	}
	switch action {
	case "forfeit":
		state.Forfeit(seat)
	case "move":
		if err := state.Drop(seat, col); err != nil {
			return &simple1v1HTTPError{status: http.StatusBadRequest, msg: err.Error()}
		}
		h.Rdb.HSet(ctx, key, "draw_offer_by", "")
	default:
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "unknown action"}
	}
	encoded, err := connect4.Encode(state)
	if err != nil {
		return err
	}
	h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
	if action == "forfeit" {
		h.Rdb.HSet(ctx, key, "forfeit", "1")
	}
	h.broadcastConnect4(gameID, m)
	if state.IsOver() {
		reason := "normal"
		if action == "forfeit" {
			reason = "forfeit"
		}
		h.onSimple1v1Finished(ctx, s, gameID, m, reason)
	} else {
		h.notifyConnect4Turn(gameID, state, players)
	}
	return nil
}

func (h *GamesHandler) notifyConnect4Turn(gameID string, state *connect4.Game, players []string) {
	if state == nil || state.IsOver() {
		return
	}
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	if isBot(players[state.Turn]) {
		h.scheduleConnect4Bot(gameID)
		return
	}
	h.notifyYourTurnUser(gameID, players[state.Turn], store.GameTypeConnect4)
}

func (h *GamesHandler) scheduleConnect4Bot(gameID string) {
	go func() {
		time.Sleep(550 * time.Millisecond)
		ctx := context.Background()
		m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
		if err != nil || m["status"] != gameStatusActive {
			return
		}
		state, err := connect4.Decode(m["state"])
		if err != nil || state.IsOver() {
			return
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if !isBot(players[state.Turn]) {
			return
		}
		col := connect4.PickColumn(state, rand.New(rand.NewSource(time.Now().UnixNano())))
		if col < 0 {
			return
		}
		if err := state.Drop(state.Turn, col); err != nil {
			return
		}
		encoded, err := connect4.Encode(state)
		if err != nil {
			return
		}
		s := connect4Spec()
		h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
		h.broadcastConnect4(gameID, m)
		if state.IsOver() {
			h.onSimple1v1Finished(ctx, s, gameID, m, "normal")
			return
		}
		h.notifyConnect4Turn(gameID, state, players)
	}()
}

func (h *GamesHandler) broadcastConnect4(gameID string, m map[string]string) {
	ctx := context.Background()
	if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
		m = fresh
	}
	state, err := connect4.Decode(m["state"])
	if err != nil {
		return
	}
	for _, u := range simple1v1Humans(parsePlayerIDsCSV(m["player_ids"])) {
		view := h.connect4View(ctx, state, u.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{u}, view)
	}
}

func (h *GamesHandler) connect4View(ctx context.Context, state *connect4.Game, viewer string, m map[string]string, gameID string) map[string]any {
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := simple1v1SeatOf(players, viewer)
	turnDeadline, _ := strconv.ParseInt(m["turn_deadline"], 10, 64)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	over := state.IsOver()
	status := gameStatusActive
	if over {
		status = "over"
	}
	winnerID := ""
	if state.Winner >= 0 && state.Winner < len(players) {
		winnerID = players[state.Winner]
	}
	legal := []int{}
	if seat == state.Turn && !over {
		legal = state.LegalColumns()
	}
	return map[string]any{
		"id":             gameID,
		"game_id":        gameID,
		"game_type":      store.GameTypeConnect4,
		"lobby_id":       m["lobby_id"],
		"game_mode":      connect4.NormalizeMode(state.Mode),
		"cols":           state.Cols,
		"rows":           state.Rows,
		"board":          state.Board,
		"turn":           state.Turn,
		"seq":            state.Seq,
		"last_col":       state.LastCol,
		"last_row":       state.LastRow,
		"players":        simple1v1PlayerViews(ctx, h, players),
		"player_ids":     players,
		"legal_columns":  legal,
		"my_index":       seat,
		"is_my_turn":     seat >= 0 && seat == state.Turn && !over,
		"turn_time_sec":  turnTimeSec,
		"turn_deadline":  turnDeadline,
		"stake_bronze":   stakeBronze,
		"status":         status,
		"is_over":        over,
		"winner_index":   state.Winner,
		"winner_user_id": winnerID,
		"is_draw":        state.Winner == connect4.WinnerDraw,
		"is_forfeit":     m["forfeit"] == "1" && over,
		"is_timeout":     m["timeout"] == "1",
		"draw_offer_by":  m["draw_offer_by"],
	}
}
