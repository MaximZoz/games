package nardy

import "math/rand"

// BotID — идентификатор бота нард.
const BotID = "bot:nardy"

// PlayBotStep делает ровно одно действие бота: бросок, одну шашку или
// закрытие хода. `true` — ход бота на этом закончился.
//
// По шагам, а не целиком: клиент должен увидеть бросок и каждую шашку
// отдельно, иначе весь ход соперника схлопывается в один кадр.
func PlayBotStep(g *Game, rng *rand.Rand) bool {
	if g == nil || g.Winner >= 0 {
		return true
	}
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	seat := g.Turn
	if len(g.Dice) == 0 {
		// Кубики отыграны — остаётся закрыть ход отдельным шагом, чтобы
		// последняя шашка успела доехать на экране.
		if len(g.History) > 0 {
			g.EndTurn()
			return true
		}
		if err := g.Roll(rng); err != nil {
			g.EndTurn()
			return true
		}
		// Ходов может не быть — тогда Roll уже передал очередь.
		return g.Winner >= 0 || g.Turn != seat
	}
	mv, ok := BotBestMove(g, rng)
	if !ok {
		g.EndTurn()
		return true
	}
	if err := g.ApplyMove(seat, mv); err != nil {
		g.EndTurn()
		return true
	}
	return g.Winner >= 0
}

// PlayBotTurn доигрывает ход бота целиком (тесты и офлайн-догон).
func PlayBotTurn(g *Game, rng *rand.Rand) {
	if g == nil || g.Winner >= 0 {
		return
	}
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	// Каждый шаг снимает кубик или закрывает ход; лимит — страховка.
	for step := 0; step < 10; step++ {
		if PlayBotStep(g, rng) {
			return
		}
	}
}

// BotBestMove выбирает ход поиском по оставшимся кубикам текущего хода.
//
// Возвращает `false`, если ходов нет.
func BotBestMove(g *Game, rng *rand.Rand) (Move, bool) {
	moves := g.LegalMoves()
	if len(moves) == 0 {
		return Move{}, false
	}
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	seat := g.Turn
	best := moves[0]
	bestScore := -1 << 30
	ties := 0
	nodes := 0
	for _, mv := range moves {
		clone := g.Clone()
		if err := clone.applyMoveRaw(mv); err != nil {
			continue
		}
		score := searchTurn(clone, seat, &nodes)
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

const nardyBotNodeLimit = 12000

func searchTurn(g *Game, seat int, nodes *int) int {
	if g.Off[seat] >= Checkers {
		return 200000
	}
	if g.Off[Opponent(seat)] >= Checkers {
		return -200000
	}
	*nodes++
	if *nodes > nardyBotNodeLimit {
		return evaluate(g, seat)
	}
	moves := g.LegalMoves()
	if len(moves) == 0 {
		return evaluate(g, seat)
	}
	best := -1 << 30
	for _, mv := range moves {
		clone := g.Clone()
		if err := clone.applyMoveRaw(mv); err != nil {
			continue
		}
		s := searchTurn(clone, seat, nodes)
		if s > best {
			best = s
		}
	}
	return best
}

// evaluate — оценка позиции глазами [seat]; больше — лучше.
func evaluate(g *Game, seat int) int {
	opp := Opponent(seat)
	score := 0
	score += (g.Pips(opp) - g.Pips(seat)) * 6
	score += g.Off[seat] * 80
	score -= g.Off[opp] * 80
	if !g.IsLong() {
		score += g.Bar[opp] * 70
		score -= g.Bar[seat] * 90
		score += primeLen(g, seat)*18 - primeLen(g, opp)*16
		for t := 0; t < Points; t++ {
			mine := g.CountAt(seat, t)
			switch {
			case mine == 1:
				score -= 22 + (Points-t)/2
			case mine >= 2:
				score += 14
				if t >= HomeStart {
					score += 16
				}
				if mine >= 3 {
					score += 4
				}
			}
			if g.CountAt(opp, t) == 1 && mine == 0 {
				score += 8
			}
		}
		return score
	}
	leftOnHead := g.CountAt(seat, 0)
	score -= leftOnHead * 28
	laggard := -1
	spread := 0
	for t := 0; t < Points; t++ {
		n := g.CountAt(seat, t)
		if n == 0 {
			continue
		}
		if laggard < 0 {
			laggard = t
		}
		spread++
		if t >= HomeStart {
			score += 8
		}
	}
	if laggard >= 0 {
		score += laggard * 5
	}
	score += spread * 4
	score += primeLen(g, seat) * 10
	return score
}

func primeLen(g *Game, seat int) int {
	best, run := 0, 0
	for t := 0; t < Points; t++ {
		if g.CountAt(seat, t) >= 2 {
			run++
			if run > best {
				best = run
			}
			continue
		}
		run = 0
	}
	return best
}
