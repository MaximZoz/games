package connect4

import "math/rand"

// PickColumn выбирает колонку для бота: сразу выигрыш, иначе блок, иначе центр.
func PickColumn(g *Game, rng *rand.Rand) int {
	legal := g.LegalColumns()
	if len(legal) == 0 {
		return -1
	}
	seat := g.Turn
	for _, c := range legal {
		if wouldWin(g, c, seat) {
			return c
		}
	}
	opp := 1 - seat
	for _, c := range legal {
		if wouldWin(g, c, opp) {
			return c
		}
	}
	center := g.Cols / 2
	best, bestScore := legal[0], -1000
	for _, c := range legal {
		score := 20 - abs(c-center)*3
		if rng != nil {
			score += rng.Intn(3)
		}
		if score > bestScore {
			best, bestScore = c, score
		}
	}
	return best
}

func wouldWin(g *Game, col, seat int) bool {
	clone := cloneGame(g)
	// Временно ходим от имени seat, даже если сейчас не его очередь.
	clone.Turn = seat
	if err := clone.Drop(seat, col); err != nil {
		return false
	}
	return clone.Winner == seat
}

func cloneGame(g *Game) *Game {
	out := *g
	out.Board = append([]int(nil), g.Board...)
	return &out
}

func abs(v int) int {
	if v < 0 {
		return -v
	}
	return v
}
