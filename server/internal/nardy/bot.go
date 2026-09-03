package nardy

import "math/rand"

// BotID — идентификатор бота нард.
const BotID = "bot:nardy"

// BotBestMove выбирает ход жадно: оценивает позицию после каждого варианта.
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
	for _, mv := range moves {
		clone := g.Clone()
		if err := clone.applyMoveRaw(mv); err != nil {
			continue
		}
		score := evaluate(clone, seat)
		switch {
		case score > bestScore:
			bestScore = score
			best = mv
			ties = 1
		case score == bestScore:
			// Равные варианты выбираем случайно — бот не выглядит шаблонным.
			ties++
			if rng.Intn(ties) == 0 {
				best = mv
			}
		}
	}
	return best, true
}

// evaluate — оценка позиции глазами [seat]; больше — лучше.
func evaluate(g *Game, seat int) int {
	opp := Opponent(seat)
	score := 0
	// Главное — продвижение: своя пипс-разница.
	score += (g.Pips(opp) - g.Pips(seat)) * 4
	// Снятые шашки весомее любого позиционного бонуса.
	score += g.Off[seat] * 60
	score -= g.Off[opp] * 60
	if !g.IsLong() {
		// Бар соперника — хорошо, свой — плохо.
		score += g.Bar[opp] * 45
		score -= g.Bar[seat] * 55
		for t := 0; t < Points; t++ {
			mine := g.CountAt(seat, t)
			switch {
			case mine == 1:
				// Одиночка под боем — риск тем выше, чем ближе к дому соперника.
				score -= 12 + (Points-t)/3
			case mine >= 2:
				// Занятый пункт блокирует соперника, дом ценнее.
				score += 8
				if t >= HomeStart {
					score += 6
				}
			}
		}
		return score
	}
	for t := 0; t < Points; t++ {
		if g.CountAt(seat, t) == 0 {
			continue
		}
		if t >= HomeStart {
			score += 6
		}
	}
	// Голова не должна простаивать до конца партии.
	score -= g.CountAt(seat, 0) * 2
	return score
}
