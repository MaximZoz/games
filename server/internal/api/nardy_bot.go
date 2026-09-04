package api

import (
	"context"
	"strconv"
	"time"

	"multigames/server/internal/nardy"

	"github.com/google/uuid"
)

// scheduleNardyBotAct доигрывает ход бота по шагам: бросок, затем шашки
// по одной. Каждый шаг уходит клиенту отдельным кадром, иначе весь ход
// соперника происходит мгновенно и его не видно.
func (h *GamesHandler) scheduleNardyBotAct(gameID string) {
	if h.Rdb == nil {
		return
	}
	// Один «бегун» на партию. Клиент дёргает GET часто, и раньше каждый
	// запрос поднимал свою горутину: они снимали замок по очереди и весь ход
	// бота проскакивал за один кадр.
	ctx := context.Background()
	runKey := nardyBotRunKey(gameID)
	locked, err := h.Rdb.SetNX(ctx, runKey, "1", nardyBotRunTTL).Result()
	if err != nil || !locked {
		return
	}
	go func() {
		defer h.Rdb.Del(context.Background(), runKey)
		// Шагов за ход не больше пяти (бросок + 4 шашки), лимит — страховка.
		for step := 0; step < 24; step++ {
			time.Sleep(nardyBotStepDelay)
			ctx := context.Background()
			h.Rdb.Expire(ctx, runKey, nardyBotRunTTL)
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["game_type"] != nardyGameType ||
				m["status"] != gameStatusActive {
				return
			}
			state, err := nardy.Decode(m["state"])
			players := parsePlayerIDsCSV(m["player_ids"])
			if err != nil || !nardyCurrentPlayerIsBot(state, players) {
				return
			}
			turnDone := nardy.PlayBotStep(state, nardyRNG())
			h.saveNardyState(ctx, gameID, m, state)
			h.broadcastNardyState(gameID, m)
			if nardyIsOver(state) {
				h.onNardyGameFinished(ctx, gameID, m, state, "normal")
				return
			}
			if !turnDone {
				continue
			}
			if !nardyCurrentPlayerIsBot(state, players) {
				h.notifyNardyTurn(gameID, state, players)
				return
			}
		}
	}()
}

// nardyBotRunKey — замок «бот сейчас доигрывает ход в этой партии».
func nardyBotRunKey(gameID string) string { return "nardy_bot_run:" + gameID }

// applyNardyTurnTimeout — просроченный ход засчитывается как поражение.
func (h *GamesHandler) applyNardyTurnTimeout(
	ctx context.Context,
	gameID string,
	m map[string]string,
) {
	if m["status"] != gameStatusActive {
		return
	}
	deadline, err := strconv.ParseInt(m["turn_deadline"], 10, 64)
	if err != nil || deadline <= 0 || time.Now().UTC().Unix() < deadline {
		return
	}
	fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(fresh) == 0 || fresh["game_type"] != nardyGameType ||
		fresh["status"] != gameStatusActive {
		return
	}
	freshDeadline, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDeadline != deadline || time.Now().UTC().Unix() < freshDeadline {
		return
	}
	state, err := nardy.Decode(fresh["state"])
	if err != nil || nardyIsOver(state) {
		return
	}
	players := parsePlayerIDsCSV(fresh["player_ids"])
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	timedOutID := players[state.Turn]
	if state.TurnComplete() && state.CanUndo() {
		// Кубики отыграны, не хватило только подтверждения — не засчитываем
		// поражение, просто закрываем ход.
		state.EndTurn()
	} else {
		state.Forfeit(state.Turn)
	}
	h.saveNardyState(ctx, gameID, fresh, state)
	fresh["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "timeout", "1")
	if !isBot(timedOutID) && !nardyIsOver(state) {
		if userID, err := uuid.Parse(timedOutID); err == nil {
			moveActiveToObserving(ctx, h.Rdb, userID, gameID)
		}
	}
	h.broadcastNardyState(gameID, fresh)
	if nardyIsOver(state) {
		h.onNardyGameFinished(ctx, gameID, fresh, state, "timeout")
	} else {
		h.notifyNardyTurn(gameID, state, players)
	}
	for key, value := range fresh {
		m[key] = value
	}
}
