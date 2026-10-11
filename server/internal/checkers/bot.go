package checkers

import (
	"math"
	"math/rand"
)

const (
	botWinScore     = 100000
	botSearchDepth  = 6
	botCornersDepth = 5
)

// PickMove выбирает ход поиском с оценкой всей позиции.
func PickMove(g *Game, rng *rand.Rand) (Move, bool) {
	if g == nil {
		return Move{}, false
	}
	legal := g.LegalMoves()
	if len(legal) == 0 {
		return Move{}, false
	}
	if len(legal) == 1 {
		return legal[0], true
	}
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	rootSeat := g.Turn
	depth := botSearchDepth
	if g.Mode == ModeCorners {
		depth = botCornersDepth
	} else if len(legal) <= 6 {
		// Эндшпиль: мало ходов, имеет смысл видеть дамку на ход дальше.
		depth = 8
	}
	if len(legal) > 28 {
		depth = 4
	}
	if len(legal) > 40 {
		depth = 3
	}
	best := legal[0]
	bestScore := math.MinInt32 / 4
	ties := 0
	alpha := math.MinInt32 / 4
	beta := math.MaxInt32 / 4
	for _, mv := range orderMoves(g, legal) {
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		score := alphabeta(child, depth-1, alpha, beta, rootSeat)
		switch {
		case score > bestScore:
			bestScore = score
			best = mv
			ties = 1
			if score > alpha {
				alpha = score
			}
		case score == bestScore:
			ties++
			if rng.Intn(ties) == 0 {
				best = mv
			}
		}
	}
	return best, true
}

func alphabeta(g *Game, depth, alpha, beta, rootSeat int) int {
	if g == nil {
		return 0
	}
	if g.IsOver() {
		switch g.Winner {
		case rootSeat:
			return botWinScore + depth
		case WinnerDraw:
			return 0
		case WinnerNone:
			return evaluate(g, rootSeat)
		default:
			return -botWinScore - depth
		}
	}
	if depth <= 0 {
		if depth > -2 {
			if captures := captureMoves(g); len(captures) > 0 {
				return alphabetaCaptures(g, depth-1, alpha, beta, rootSeat, captures)
			}
		}
		return evaluate(g, rootSeat)
	}
	legal := g.LegalMoves()
	if len(legal) == 0 {
		return evaluate(g, rootSeat)
	}
	maximizing := g.Turn == rootSeat
	legal = orderMoves(g, legal)
	if maximizing {
		best := math.MinInt32 / 4
		for _, mv := range legal {
			child := g.Clone()
			if err := child.Apply(g.Turn, mv); err != nil {
				continue
			}
			s := alphabeta(child, depth-1, alpha, beta, rootSeat)
			if s > best {
				best = s
			}
			if best > alpha {
				alpha = best
			}
			if alpha >= beta {
				break
			}
		}
		return best
	}
	best := math.MaxInt32 / 4
	for _, mv := range legal {
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		s := alphabeta(child, depth-1, alpha, beta, rootSeat)
		if s < best {
			best = s
		}
		if best < beta {
			beta = best
		}
		if alpha >= beta {
			break
		}
	}
	return best
}

func captureMoves(g *Game) []Move {
	if g == nil {
		return nil
	}
	var out []Move
	for _, mv := range g.LegalMoves() {
		if len(mv.Jumped) > 0 {
			out = append(out, mv)
		}
	}
	return out
}

func alphabetaCaptures(g *Game, depth, alpha, beta, rootSeat int, captures []Move) int {
	maximizing := g.Turn == rootSeat
	if maximizing {
		best := math.MinInt32 / 4
		for _, mv := range orderMoves(g, captures) {
			child := g.Clone()
			if err := child.Apply(g.Turn, mv); err != nil {
				continue
			}
			s := alphabeta(child, depth, alpha, beta, rootSeat)
			if s > best {
				best = s
			}
			if best > alpha {
				alpha = best
			}
			if alpha >= beta {
				break
			}
		}
		return best
	}
	best := math.MaxInt32 / 4
	for _, mv := range orderMoves(g, captures) {
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		s := alphabeta(child, depth, alpha, beta, rootSeat)
		if s < best {
			best = s
		}
		if best < beta {
			beta = best
		}
		if alpha >= beta {
			break
		}
	}
	return best
}

func orderMoves(g *Game, legal []Move) []Move {
	out := append([]Move(nil), legal...)
	if g != nil && g.Mode == ModeCorners {
		tr, tc := targetOrigin(g.Turn)
		for i := 1; i < len(out); i++ {
			for j := i; j > 0; j-- {
				if moveProgress(out[j], tr, tc) > moveProgress(out[j-1], tr, tc) {
					out[j], out[j-1] = out[j-1], out[j]
					continue
				}
				break
			}
		}
		return out
	}
	for i := 1; i < len(out); i++ {
		for j := i; j > 0; j-- {
			if len(out[j].Jumped) > len(out[j-1].Jumped) {
				out[j], out[j-1] = out[j-1], out[j]
				continue
			}
			break
		}
	}
	return out
}

func moveProgress(mv Move, tr, tc int) int {
	from := minDistToBox(mv.From.R, mv.From.C, tr, tc)
	to := minDistToBox(mv.To.R, mv.To.C, tr, tc)
	return (from - to) + from
}

func evaluate(g *Game, seat int) int {
	if g == nil {
		return 0
	}
	if g.Mode == ModeCorners {
		return evalCorners(g, seat)
	}
	score := evalDraughts(g, seat)
	if g.Mode == ModeGiveaway {
		return -score
	}
	return score
}

func evalDraughts(g *Game, seat int) int {
	score := 0
	oppKing := [2]bool{sideHasKing(g, 0), sideHasKing(g, 1)}
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			p := g.at(r, c)
			own := owner(p)
			if own < 0 {
				continue
			}
			val := 100
			if isKing(p) {
				val = 280
				val += 6 - absInt(r-3) - absInt(c-3)
			} else if own == 0 {
				val += r * 8
				if r >= 5 {
					val += 12
				}
			} else {
				val += (Size - 1 - r) * 8
				if r <= 2 {
					val += 12
				}
			}
			if dark(r, c) && r >= 2 && r <= 5 && c >= 2 && c <= 5 {
				val += 8
			}
			if !isKing(p) {
				if own == 0 && r == 0 {
					val += 18
				}
				if own == 1 && r == Size-1 {
					val += 18
				}
				if !oppKing[1-own] {
					val += runnerClear(g, r, own)
				}
			}
			if own == seat {
				score += val
			} else {
				score -= val
			}
		}
	}
	score += maxCapture(g, seat)*28 - maxCapture(g, 1-seat)*55
	return score
}

func sideHasKing(g *Game, seat int) bool {
	if g == nil {
		return false
	}
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			p := g.at(r, c)
			if owner(p) == seat && isKing(p) {
				return true
			}
		}
	}
	return false
}

// runnerClear — простая шашка, перед которой нет чужих на две-три горизонтали.
func runnerClear(g *Game, rank, own int) int {
	dir := 1
	if own == 1 {
		dir = -1
	}
	enemy := 1 - own
	clear := 0
	for step := 1; step <= 3; step++ {
		rr := rank + dir*step
		if rr < 0 || rr >= Size {
			clear += 2
			break
		}
		blocked := false
		for c := 0; c < Size; c++ {
			if owner(g.at(rr, c)) == enemy {
				blocked = true
				break
			}
		}
		if blocked {
			break
		}
		clear++
	}
	if clear >= 2 {
		return 10 + clear*6
	}
	return 0
}

func maxCapture(g *Game, attacker int) int {
	if g == nil || g.IsOver() {
		return 0
	}
	child := g.Clone()
	child.Turn = attacker
	best := 0
	for _, mv := range child.LegalMoves() {
		if n := len(mv.Jumped); n > best {
			best = n
		}
	}
	return best
}

func evalCorners(g *Game, seat int) int {
	if g.cornersFilled(seat) {
		return botWinScore
	}
	if g.cornersFilled(1 - seat) {
		return -botWinScore
	}
	score := 0
	for s := 0; s < 2; s++ {
		sign := 1
		if s != seat {
			sign = -1
		}
		tr, tc := targetOrigin(s)
		sr, sc := startOrigin(s)
		sum, sumSq, maxd, inTarget, inStart, far := 0, 0, 0, 0, 0, 0
		for r := 0; r < Size; r++ {
			for c := 0; c < Size; c++ {
				if owner(g.at(r, c)) != s {
					continue
				}
				d := minDistToBox(r, c, tr, tc)
				sum += d
				sumSq += d * d
				if d > maxd {
					maxd = d
				}
				if d >= 4 {
					far++
				}
				if inBox(r, c, tr, tc) {
					inTarget++
				}
				if inBox(r, c, sr, sc) {
					inStart++
				}
			}
		}
		score += sign * (inTarget*140 - inStart*18 - sum*4 - sumSq*5 - maxd*22 - far*14)
	}
	return score
}

func targetOrigin(seat int) (int, int) {
	if seat == 0 {
		return 5, 5
	}
	return 0, 0
}

func startOrigin(seat int) (int, int) {
	if seat == 0 {
		return 0, 0
	}
	return 5, 5
}

func inBox(r, c, tr, tc int) bool {
	return r >= tr && r < tr+3 && c >= tc && c < tc+3
}

func absInt(v int) int {
	if v < 0 {
		return -v
	}
	return v
}

func minDistToBox(r, c, tr, tc int) int {
	dr := 0
	if r < tr {
		dr = tr - r
	} else if r > tr+2 {
		dr = r - (tr + 2)
	}
	dc := 0
	if c < tc {
		dc = tc - c
	} else if c > tc+2 {
		dc = c - (tc + 2)
	}
	return dr + dc
}
