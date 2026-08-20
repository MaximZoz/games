package api

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"multigames/server/internal/uno"

	"github.com/google/uuid"
)

func (h *GamesHandler) scheduleUnoBotAct(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		for {
			time.Sleep(unoBotDelay)
			ctx := context.Background()
			lockKey := "uno_bot_lock:" + gameID
			locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result()
			if !locked {
				return
			}
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["game_type"] != unoGameType ||
				m["status"] != gameStatusActive {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			state, err := uno.Decode(m["state"])
			if err != nil || !unoCurrentPlayerIsBot(state) {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			if err := unoApplyBotAction(state); err != nil {
				botID := state.Players[state.CurrentIndex].UserID
				_ = state.Apply(uno.Action{Type: uno.ActionForfeit, ActorUserID: botID})
			}
			h.saveUnoState(ctx, gameID, m, state)
			h.broadcastUnoState(gameID, m)
			over := state.IsOver()
			if over {
				h.onUnoGameFinished(ctx, gameID, m, state, "normal")
			}
			h.Rdb.Del(ctx, lockKey)
			if over {
				return
			}
			if !unoCurrentPlayerIsBot(state) {
				h.notifyUnoTurn(gameID, state)
				return
			}
		}
	}()
}

func unoApplyBotAction(state *uno.Game) error {
	if state == nil || state.CurrentIndex < 0 || state.CurrentIndex >= len(state.Players) {
		return fmt.Errorf("uno: no current bot")
	}
	index := state.CurrentIndex
	player := state.Players[index]
	if !isBot(player.UserID) {
		return fmt.Errorf("uno: current player is not a bot")
	}
	switch state.Status {
	case uno.StatusAwaitingColor:
		return state.Apply(uno.Action{Type: uno.ActionChooseColor, Color: unoBotColor(state, index)})
	case uno.StatusAwaitingWD4Challenge:
		return state.Apply(uno.Action{Type: uno.ActionDraw})
	case uno.StatusAwaitingDrawnPlay:
		action := uno.Action{
			Type:   uno.ActionPlay,
			CardID: state.DrawnCardID,
			Color:  unoBotColor(state, index),
		}
		if err := state.Apply(action); err == nil {
			unoBotCallIfNeeded(state, index)
			return nil
		}
		return state.Apply(uno.Action{Type: uno.ActionKeep})
	case uno.StatusActive:
		if state.UnoVulnerableIndex == index && len(state.Players[index].Hand) == 1 {
			return state.Apply(uno.Action{Type: uno.ActionCallUno, ActorUserID: player.UserID})
		}
		if state.UnoVulnerableIndex >= 0 && state.UnoVulnerableIndex != index {
			target := state.Players[state.UnoVulnerableIndex].UserID
			return state.Apply(uno.Action{
				Type:         uno.ActionChallengeUno,
				ActorUserID:  player.UserID,
				TargetUserID: target,
			})
		}
		for _, card := range player.Hand {
			candidate, err := cloneUnoGame(state)
			if err != nil {
				return err
			}
			action := uno.Action{
				Type:   uno.ActionPlay,
				CardID: card.ID,
				Color:  unoBotColor(candidate, index),
			}
			if err := candidate.Apply(action); err != nil {
				continue
			}
			unoBotCallIfNeeded(candidate, index)
			*state = *candidate
			return nil
		}
		return state.Apply(uno.Action{Type: uno.ActionDraw})
	default:
		return fmt.Errorf("uno: unsupported bot status %q", state.Status)
	}
}

func unoBotCallIfNeeded(state *uno.Game, playerIndex int) {
	if state == nil || playerIndex < 0 || playerIndex >= len(state.Players) {
		return
	}
	if len(state.Players[playerIndex].Hand) == 1 && !state.Players[playerIndex].SaidUno {
		_ = state.Apply(uno.Action{
			Type:        uno.ActionCallUno,
			ActorUserID: state.Players[playerIndex].UserID,
		})
	}
}

func unoBotColor(state *uno.Game, playerIndex int) string {
	counts := map[uno.Color]int{
		uno.ColorRed:    0,
		uno.ColorYellow: 0,
		uno.ColorGreen:  0,
		uno.ColorBlue:   0,
	}
	if state != nil && playerIndex >= 0 && playerIndex < len(state.Players) {
		for _, card := range state.Players[playerIndex].Hand {
			if _, ok := counts[card.Color]; ok {
				counts[card.Color]++
			}
		}
	}
	best := uno.ColorRed
	for _, color := range []uno.Color{uno.ColorYellow, uno.ColorGreen, uno.ColorBlue} {
		if counts[color] > counts[best] {
			best = color
		}
	}
	return string(best)
}

func cloneUnoGame(state *uno.Game) (*uno.Game, error) {
	encoded, err := uno.Encode(state)
	if err != nil {
		return nil, err
	}
	return uno.Decode(encoded)
}

func (h *GamesHandler) applyUnoTurnTimeout(
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
	if err != nil || len(fresh) == 0 || fresh["game_type"] != unoGameType ||
		fresh["status"] != gameStatusActive {
		return
	}
	freshDeadline, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDeadline != deadline || time.Now().UTC().Unix() < freshDeadline {
		return
	}
	state, err := uno.Decode(fresh["state"])
	if err != nil || state.CurrentIndex < 0 || state.CurrentIndex >= len(state.Players) {
		return
	}
	timedOutIndex := state.CurrentIndex
	timedOutID := state.Players[timedOutIndex].UserID
	action := unoTimeoutAction(state)
	if err := state.Apply(action); err != nil {
		action = uno.Action{Type: uno.ActionForfeit, ActorUserID: timedOutID}
		if err := state.Apply(action); err != nil {
			return
		}
	}
	h.saveUnoState(ctx, gameID, fresh, state)
	fresh["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "timeout", "1")
	if action.Type == uno.ActionForfeit && !isBot(timedOutID) && !state.IsOver() {
		if userID, err := uuid.Parse(timedOutID); err == nil {
			moveActiveToObserving(ctx, h.Rdb, userID, gameID)
		}
	}
	h.broadcastUnoState(gameID, fresh)
	if state.IsOver() {
		h.onUnoGameFinished(ctx, gameID, fresh, state, "timeout")
	} else {
		h.notifyUnoTurn(gameID, state)
	}
	for key, value := range fresh {
		m[key] = value
	}
}

func unoTimeoutAction(state *uno.Game) uno.Action {
	switch state.Status {
	case uno.StatusAwaitingColor:
		return uno.Action{
			Type:  uno.ActionChooseColor,
			Color: unoBotColor(state, state.CurrentIndex),
		}
	case uno.StatusAwaitingWD4Challenge:
		return uno.Action{Type: uno.ActionDraw}
	case uno.StatusAwaitingDrawnPlay:
		return uno.Action{Type: uno.ActionKeep}
	default:
		return uno.Action{Type: uno.ActionDraw}
	}
}
