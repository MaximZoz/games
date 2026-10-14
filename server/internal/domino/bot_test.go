package domino

import (
	"fmt"
	"testing"
)

func TestBotPlaysHeavierDouble(t *testing.T) {
	g := freshGame([][]int{{TileID(6, 6), TileID(1, 1)}, {TileID(2, 2)}}, []int{TileID(3, 3)}, 6, 1)
	action := BestAction(g, 0)
	if action.Type != ActionPlay || action.Tile != TileID(6, 6) {
		t.Fatalf("bot %+v", action)
	}
}

func TestBotGoesOut(t *testing.T) {
	g := freshGame([][]int{{TileID(4, 4)}, {TileID(0, 1), TileID(2, 3)}}, nil, 4, 2)
	action := BestAction(g, 0)
	if action.Type != ActionPlay || action.Tile != TileID(4, 4) {
		t.Fatalf("bot %+v", action)
	}
}

func TestBotDoesNotPeek(t *testing.T) {
	mine := []int{TileID(0, 6), TileID(1, 2)}
	a := freshGame([][]int{mine, {TileID(5, 5), TileID(4, 4)}}, []int{TileID(3, 3), TileID(2, 2)}, 0, 1)
	b := freshGame([][]int{mine, {TileID(3, 3), TileID(2, 2)}}, []int{TileID(5, 5), TileID(4, 4)}, 0, 1)
	left := BestAction(a, 0)
	right := BestAction(b, 0)
	if left != right {
		t.Fatalf("peek changed move %+v vs %+v", left, right)
	}
	if left.Tile != TileID(0, 6) {
		t.Fatalf("expected the heavy tile, got %+v", left)
	}
}

func TestBotBlocksDeadSuit(t *testing.T) {
	// Все кости с 1, кроме 1-1 в руке, уже на столе. Конец 1 мёртв после дубля.
	chain := []int{TileID(0, 1), TileID(1, 2), TileID(1, 3), TileID(1, 4), TileID(1, 5), TileID(1, 6)}
	g := freshGame([][]int{{TileID(1, 1), TileID(0, 3)}, {TileID(2, 4)}}, []int{TileID(0, 2)}, 1, 3)
	g.Chain = nil
	for _, id := range chain {
		lo, hi := Pips(id)
		g.Chain = append(g.Chain, Placed{ID: id, Lo: lo, Hi: hi, End: "right"})
	}
	if got := g.knownSuit(0, 1, TileID(1, 1)); got != SuitCopies {
		t.Fatalf("known 1s = %d", got)
	}
	action := BestAction(g, 0)
	if action.Tile != TileID(1, 1) {
		t.Fatalf("bot should close the dead 1, got %+v", action)
	}
}

type botPlayer func(*Game, int) Action

func playMatch(seed int64, seatBot int, smart, other botPlayer) (goat int, err error) {
	ids := []string{"p0", "p1"}
	g, err := NewGame(ids, seed)
	if err != nil {
		return -1, err
	}
	for step := 0; step < 4000 && !g.IsOver(); step++ {
		if g.Status == StatusRoundEnd {
			if err := g.Apply(Action{Type: ActionNextRound}); err != nil {
				return -1, err
			}
			continue
		}
		var action Action
		if g.Turn == seatBot {
			action = smart(g, g.Turn)
		} else {
			action = other(g, g.Turn)
		}
		if action.Type == "" {
			return -1, fmt.Errorf("empty action at step %d", step)
		}
		if err := g.Apply(action); err != nil {
			return -1, fmt.Errorf("step %d %+v: %w", step, action, err)
		}
	}
	if !g.IsOver() {
		return -1, fmt.Errorf("match did not finish")
	}
	return g.GoatSeat, nil
}

func greedyAction(g *Game, seat int) Action {
	moves := g.LegalMoves(seat)
	if len(moves) == 0 {
		if len(g.Boneyard) > 0 {
			return Action{Type: ActionDraw}
		}
		return Action{Type: ActionPass}
	}
	best := moves[0]
	bestPips := -1
	for _, mv := range moves {
		pips := PipSum([]int{mv.Tile})
		if IsDouble(mv.Tile) {
			pips += 3
		}
		if pips > bestPips {
			bestPips = pips
			best = mv
		}
	}
	return Action{Type: ActionPlay, Tile: best.Tile, End: best.End}
}

func TestBotBeatsGreedy(t *testing.T) {
	losses := 0
	games := 0
	for seed := int64(1); seed <= 8; seed++ {
		for _, seat := range []int{0, 1} {
			goat, err := playMatch(seed*10+int64(seat), seat, BestAction, greedyAction)
			if err != nil {
				t.Fatalf("seed %d seat %d: %v", seed, seat, err)
			}
			games++
			if goat == seat {
				losses++
			}
		}
	}
	if losses > games/3 {
		t.Fatalf("smart bot was the goat in %d/%d games", losses, games)
	}
}
