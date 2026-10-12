package chess

import (
	"math"
	"math/rand"
)

const (
	botWinScore    = 1000000
	botSearchDepth = 4
	botQuiesceCap  = 4
)

// Базовая ценность фигур (пешка..король).
var pieceValue = [7]int{0, 100, 320, 330, 500, 900, 20000}

// Таблицы позиционной оценки для белых (индекс r*8+c, r=0 — первый ряд белых).
var pawnPST = [64]int{
	0, 0, 0, 0, 0, 0, 0, 0,
	5, 10, 10, -20, -20, 10, 10, 5,
	5, -5, -10, 0, 0, -10, -5, 5,
	0, 0, 0, 20, 20, 0, 0, 0,
	5, 5, 10, 25, 25, 10, 5, 5,
	10, 10, 20, 30, 30, 20, 10, 10,
	50, 50, 50, 50, 50, 50, 50, 50,
	0, 0, 0, 0, 0, 0, 0, 0,
}

var knightPST = [64]int{
	-50, -40, -30, -30, -30, -30, -40, -50,
	-40, -20, 0, 5, 5, 0, -20, -40,
	-30, 5, 10, 15, 15, 10, 5, -30,
	-30, 0, 15, 20, 20, 15, 0, -30,
	-30, 5, 15, 20, 20, 15, 5, -30,
	-30, 0, 10, 15, 15, 10, 0, -30,
	-40, -20, 0, 0, 0, 0, -20, -40,
	-50, -40, -30, -30, -30, -30, -40, -50,
}

var bishopPST = [64]int{
	-20, -10, -10, -10, -10, -10, -10, -20,
	-10, 5, 0, 0, 0, 0, 5, -10,
	-10, 10, 10, 10, 10, 10, 10, -10,
	-10, 0, 10, 10, 10, 10, 0, -10,
	-10, 5, 5, 10, 10, 5, 5, -10,
	-10, 0, 5, 10, 10, 5, 0, -10,
	-10, 0, 0, 0, 0, 0, 0, -10,
	-20, -10, -10, -10, -10, -10, -10, -20,
}

var rookPST = [64]int{
	0, 0, 0, 5, 5, 0, 0, 0,
	-5, 0, 0, 0, 0, 0, 0, -5,
	-5, 0, 0, 0, 0, 0, 0, -5,
	-5, 0, 0, 0, 0, 0, 0, -5,
	-5, 0, 0, 0, 0, 0, 0, -5,
	-5, 0, 0, 0, 0, 0, 0, -5,
	5, 10, 10, 10, 10, 10, 10, 5,
	0, 0, 0, 0, 0, 0, 0, 0,
}

var queenPST = [64]int{
	-20, -10, -10, -5, -5, -10, -10, -20,
	-10, 0, 5, 0, 0, 0, 0, -10,
	-10, 5, 5, 5, 5, 5, 0, -10,
	0, 0, 5, 5, 5, 5, 0, -5,
	-5, 0, 5, 5, 5, 5, 0, -5,
	-10, 0, 5, 5, 5, 5, 0, -10,
	-10, 0, 0, 0, 0, 0, 0, -10,
	-20, -10, -10, -5, -5, -10, -10, -20,
}

var kingPST = [64]int{
	20, 30, 10, 0, 0, 10, 30, 20,
	20, 20, 0, 0, 0, 0, 20, 20,
	-10, -20, -20, -20, -20, -20, -20, -10,
	-20, -30, -30, -40, -40, -30, -30, -20,
	-30, -40, -40, -50, -50, -40, -40, -30,
	-30, -40, -40, -50, -50, -40, -40, -30,
	-30, -40, -40, -50, -50, -40, -40, -30,
	-30, -40, -40, -50, -50, -40, -40, -30,
}

func pstFor(k, idx, seat int) int {
	if seat == 1 {
		idx = (Size-1-idx/Size)*Size + idx%Size // отражение по вертикали
	}
	switch k {
	case 1:
		return pawnPST[idx]
	case 2:
		return knightPST[idx]
	case 3:
		return bishopPST[idx]
	case 4:
		return rookPST[idx]
	case 5:
		return queenPST[idx]
	case 6:
		return kingPST[idx]
	}
	return 0
}

// PickMove выбирает ход поиском alpha-beta с оценкой позиции.
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
	if len(legal) > 30 {
		depth = 3
	}
	best := legal[0]
	bestScore := math.MinInt32
	ties := 0
	// В корне ищем полным окном, чтобы оценки были точными и равные ходы
	// корректно определялись как ничейные (без ложных совпадений от отсечений).
	const wide = math.MaxInt32 - 1
	for _, mv := range orderMoves(g, legal) {
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		score := -alphabeta(child, depth-1, -wide, wide, rootSeat)
		switch {
		case score > bestScore:
			bestScore = score
			best = mv
			ties = 1
		case score == bestScore:
			ties++
			if rng.Intn(ties) == 0 {
				best = mv
			}
		}
	}
	return best, true
}

// alphabeta — negamax с отсечениями; возвращает оценку с точки зрения ходящего.
func alphabeta(g *Game, depth, alpha, beta, rootSeat int) int {
	if g.IsOver() {
		switch {
		case g.Winner == WinnerDraw:
			return 0
		case g.Winner == g.Turn:
			// Ходящая сторона — победитель (редко: сдача соперника).
			return botWinScore + depth
		default:
			// Ходящей стороне поставлен мат.
			return -botWinScore - depth
		}
	}
	if depth <= 0 {
		return quiesce(g, alpha, beta, botQuiesceCap)
	}
	legal := g.LegalMoves()
	if len(legal) == 0 {
		return evaluateSide(g, g.Turn)
	}
	best := math.MinInt32 + 1
	for _, mv := range orderMoves(g, legal) {
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		s := -alphabeta(child, depth-1, -beta, -alpha, rootSeat)
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

// quiesce — поиск в «спокойствии»: только взятия, чтобы снять эффект горизонта.
func quiesce(g *Game, alpha, beta, depth int) int {
	if g.IsOver() {
		switch {
		case g.Winner == WinnerDraw:
			return 0
		case g.Winner == g.Turn:
			return botWinScore
		default:
			return -botWinScore
		}
	}
	stand := evaluateSide(g, g.Turn)
	if depth <= 0 {
		return stand
	}
	if stand >= beta {
		return beta
	}
	if stand > alpha {
		alpha = stand
	}
	for _, mv := range orderMoves(g, g.LegalMoves()) {
		if g.at(mv.To.R, mv.To.C) == Empty && mv.Promo == 0 {
			continue // только взятия и превращения
		}
		child := g.Clone()
		if err := child.Apply(g.Turn, mv); err != nil {
			continue
		}
		s := -quiesce(child, -beta, -alpha, depth-1)
		if s >= beta {
			return beta
		}
		if s > alpha {
			alpha = s
		}
	}
	return alpha
}

// orderMoves — взятия и превращения вперёд (MVV-LVA), остальное как есть.
func orderMoves(g *Game, legal []Move) []Move {
	out := append([]Move(nil), legal...)
	score := func(mv Move) int {
		s := 0
		victim := g.at(mv.To.R, mv.To.C)
		if victim != Empty {
			s += pieceValue[kind(victim)]*10 - pieceValue[kind(g.at(mv.From.R, mv.From.C))]
		}
		if mv.Promo != 0 {
			s += pieceValue[mv.Promo]
		}
		return s
	}
	for i := 1; i < len(out); i++ {
		for j := i; j > 0; j-- {
			if score(out[j]) > score(out[j-1]) {
				out[j], out[j-1] = out[j-1], out[j]
				continue
			}
			break
		}
	}
	return out
}

// evaluateSide — оценка позиции с точки зрения seat (материал + таблицы).
func evaluateSide(g *Game, seat int) int {
	score := 0
	for i, p := range g.Board {
		if p == Empty {
			continue
		}
		own := colorOf(p)
		val := pieceValue[kind(p)] + pstFor(kind(p), i, own)
		if own == seat {
			score += val
		} else {
			score -= val
		}
	}
	// Небольшой бонус за подвижность (псевдоходы — дешёвая аппроксимация).
	mine := len(g.pseudoMoves(seat))
	theirs := len(g.pseudoMoves(1 - seat))
	score += (mine - theirs) * 2
	score += pawnStructure(g, seat) - pawnStructure(g, 1-seat)
	return score
}

// pawnStructure — проходные, связанные и сдвоенные пешки [seat].
func pawnStructure(g *Game, seat int) int {
	var files [8]int
	for i, p := range g.Board {
		if p == Empty || kind(p) != 1 || colorOf(p) != seat {
			continue
		}
		files[i%8]++
	}
	score := 0
	for i, p := range g.Board {
		if p == Empty || kind(p) != 1 || colorOf(p) != seat {
			continue
		}
		file, rank := i%8, i/8
		adv := rank
		if seat == 1 {
			adv = 7 - rank
		}
		if pawnIsPassed(g, seat, file, rank) {
			score += 16 + adv*12
		}
		friendly := (file > 0 && files[file-1] > 0) || (file < 7 && files[file+1] > 0)
		if friendly {
			score += 6
		} else {
			score -= 10
		}
		if files[file] > 1 {
			score -= 8
		}
	}
	return score
}

func pawnIsPassed(g *Game, seat, file, rank int) bool {
	enemy := 1 - seat
	for df := -1; df <= 1; df++ {
		f := file + df
		if f < 0 || f >= 8 {
			continue
		}
		for r := 0; r < 8; r++ {
			if seat == 0 && r <= rank {
				continue
			}
			if seat == 1 && r >= rank {
				continue
			}
			p := g.at(r, f)
			if p != Empty && kind(p) == 1 && colorOf(p) == enemy {
				return false
			}
		}
	}
	return true
}
