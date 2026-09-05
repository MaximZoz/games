package checkers

import "math/rand"

// PickMove — бой, если есть; иначе ближе к дамке.
func PickMove(g *Game, rng *rand.Rand) (Move, bool) {
	legal := g.LegalMoves()
	if len(legal) == 0 {
		return Move{}, false
	}
	best := legal[0]
	bestScore := moveScore(g, best)
	for i := 1; i < len(legal); i++ {
		s := moveScore(g, legal[i])
		if rng != nil {
			s += rng.Intn(3)
		}
		if s > bestScore {
			best, bestScore = legal[i], s
		}
	}
	return best, true
}

func moveScore(g *Game, mv Move) int {
	score := len(mv.Jumped) * 20
	seat := g.Turn
	if seat == 0 {
		score += mv.To.R
		if mv.To.R == Size-1 {
			score += 8
		}
	} else {
		score += Size - 1 - mv.To.R
		if mv.To.R == 0 {
			score += 8
		}
	}
	return score
}
