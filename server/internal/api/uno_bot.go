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
			lockKey := "uno_bot_lock:" + gameID
			locked, _ := h.Rdb.SetNX(context.Background(), lockKey, "1", 5*time.Second).Result()
			if !locked {
				return
			}
			var stop bool
			err := h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
				m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
				if err != nil || len(m) == 0 || m["game_type"] != unoGameType ||
					m["status"] != gameStatusActive {
					stop = true
					return nil
				}
				state, err := uno.Decode(m["state"])
				if err != nil || !unoCurrentPlayerIsBot(state) {
					stop = true
					return nil
				}
				if err := unoApplyBotAction(state); err != nil {
					if recoverErr := unoRecoverBotAction(state); recoverErr != nil {
						botID := state.Players[state.CurrentIndex].UserID
						_ = state.Apply(uno.Action{Type: uno.ActionForfeit, ActorUserID: botID})
					}
				}
				h.saveUnoState(ctx, gameID, m, state)
				h.broadcastUnoState(gameID, m)
				over := state.IsOver()
				if over {
					h.onUnoGameFinished(ctx, gameID, m, state, "normal")
					stop = true
					return nil
				}
				if state.Status == uno.StatusBetweenRounds {
					h.scheduleUnoNextRound(gameID)
					stop = true
					return nil
				}
				if !unoCurrentPlayerIsBot(state) {
					h.notifyUnoTurn(gameID, state)
					stop = true
				}
				return nil
			})
			h.Rdb.Del(context.Background(), lockKey)
			if err != nil || stop {
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
	case uno.StatusBetweenRounds:
		return state.Apply(uno.Action{Type: uno.ActionNextRound})
	case uno.StatusAwaitingColor:
		chooser := state.ColorChooserIndex
		if chooser < 0 {
			chooser = index
		}
		return state.Apply(uno.Action{Type: uno.ActionChooseColor, Color: unoBotColor(state, chooser)})
	case uno.StatusAwaitingWD4Challenge:
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
			if err := state.Apply(uno.Action{
				Type:         uno.ActionChallengeUno,
				ActorUserID:  player.UserID,
				TargetUserID: target,
			}); err == nil {
				return nil
			}
		}
		bestIdx := -1
		bestScore := -1 << 30
		for i, card := range player.Hand {
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
			score := unoCardScore(state, index, card)
			if score > bestScore {
				bestScore = score
				bestIdx = i
			}
		}
		if bestIdx >= 0 {
			candidate, err := cloneUnoGame(state)
			if err != nil {
				return err
			}
			action := uno.Action{
				Type:   uno.ActionPlay,
				CardID: player.Hand[bestIdx].ID,
				Color:  unoBotColor(candidate, index),
			}
			if err := candidate.Apply(action); err != nil {
				return err
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

func unoNextHandSize(state *uno.Game, playerIndex int) int {
	if state == nil || len(state.Players) == 0 {
		return 7
	}
	n := len(state.Players)
	dir := state.Direction
	if dir == 0 {
		dir = 1
	}
	for step := 1; step <= n; step++ {
		next := (playerIndex + dir*step) % n
		if next < 0 {
			next += n
		}
		if !state.Players[next].Forfeited {
			return len(state.Players[next].Hand)
		}
	}
	return 7
}

func unoCardScore(state *uno.Game, playerIndex int, card uno.Card) int {
	next := unoNextHandSize(state, playerIndex)
	colorCounts := map[uno.Color]int{}
	if state != nil && playerIndex >= 0 && playerIndex < len(state.Players) {
		for _, c := range state.Players[playerIndex].Hand {
			if c.Color == uno.ColorRed || c.Color == uno.ColorYellow ||
				c.Color == uno.ColorGreen || c.Color == uno.ColorBlue {
				colorCounts[c.Color]++
			}
		}
	}
	score := card.Points()
	switch card.Kind {
	case uno.KindSkip, uno.KindReverse, uno.KindDrawTwo:
		if next <= 2 {
			score += 70
		} else if next <= 4 {
			score += 25
		} else {
			score += 8
		}
	case uno.KindWild:
		if next <= 2 {
			score += 40
		} else {
			score -= 25
		}
	case uno.KindWildDrawFour:
		if next <= 2 {
			score += 90
		} else {
			score -= 45
		}
	default:
		score += colorCounts[card.Color] * 10
	}
	return score
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
	if state.Status == uno.StatusBetweenRounds {
		return
	}
	timedOutIndex := state.CurrentIndex
	timedOutID := state.Players[timedOutIndex].UserID
	action := unoTimeoutAction(state)
	if err := state.Apply(action); err != nil {
		return
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

func unoRecoverBotAction(state *uno.Game) error {
	if state == nil {
		return fmt.Errorf("uno: nil game")
	}
	switch state.Status {
	case uno.StatusBetweenRounds:
		return state.Apply(uno.Action{Type: uno.ActionNextRound})
	case uno.StatusAwaitingColor:
		chooser := state.ColorChooserIndex
		if chooser < 0 {
			chooser = state.CurrentIndex
		}
		return state.Apply(uno.Action{Type: uno.ActionChooseColor, Color: unoBotColor(state, chooser)})
	case uno.StatusAwaitingDrawnPlay:
		return state.Apply(uno.Action{Type: uno.ActionKeep})
	default:
		return state.Apply(uno.Action{Type: uno.ActionDraw})
	}
}

func (h *GamesHandler) scheduleUnoNextRound(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		time.Sleep(unoRoundPause)
		lockKey := "uno_next_round_lock:" + gameID
		locked, _ := h.Rdb.SetNX(context.Background(), lockKey, "1", 5*time.Second).Result()
		if !locked {
			return
		}
		defer h.Rdb.Del(context.Background(), lockKey)
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["game_type"] != unoGameType ||
				m["status"] != gameStatusActive {
				return nil
			}
			state, err := uno.Decode(m["state"])
			if err != nil || state.Status != uno.StatusBetweenRounds {
				return nil
			}
			if err := state.Apply(uno.Action{Type: uno.ActionNextRound}); err != nil {
				return nil
			}
			h.saveUnoState(ctx, gameID, m, state)
			h.broadcastUnoState(gameID, m)
			h.notifyUnoTurn(gameID, state)
			return nil
		})
	}()
}

func unoTimeoutAction(state *uno.Game) uno.Action {
	if state != nil && state.Status == uno.StatusBetweenRounds {
		return uno.Action{Type: uno.ActionNextRound}
	}
	actor := ""
	if state != nil && state.CurrentIndex >= 0 && state.CurrentIndex < len(state.Players) {
		actor = state.Players[state.CurrentIndex].UserID
	}
	return uno.Action{Type: uno.ActionForfeit, ActorUserID: actor}
}
