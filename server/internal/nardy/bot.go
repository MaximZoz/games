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
// Каждый кандидат доигрывается до конца броска со своим лимитом узлов.
// Общий счётчик на все ходы раньше отдавал весь бюджет первым шашкам
// (они в списке с головы), и бот систематически двигал задние.
//
// Возвращает `false`, если ходов нет.
func BotBestMove(g *Game, rng *rand.Rand) (Move, bool) {
	moves := orderBotMoves(g, g.LegalMoves())
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
	budget := nodeBudget(len(g.Dice))
	probe := g.Clone()
	for _, mv := range moves {
		undo, ok := probe.applySearch(mv)
		if !ok {
			continue
		}
		nodes := 0
		score := searchTurn(probe, seat, &nodes, budget)
		probe.undoSearch(undo)
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

// nodeBudget — сколько узлов можно потратить на ОДИН корневой ход.
// Два кубика доигрываются целиком; дубль ограничен, но у каждого хода
// тот же потолок, поэтому оценки сравнимы.
func nodeBudget(diceLeft int) int {
	switch {
	case diceLeft >= 4:
		return 1600
	case diceLeft == 3:
		return 4000
	default:
		return 8000
	}
}

func searchTurn(g *Game, seat int, nodes *int, budget int) int {
	if g.Off[seat] >= Checkers {
		return 200000
	}
	if g.Off[Opponent(seat)] >= Checkers {
		return -200000
	}
	*nodes++
	if *nodes > budget {
		return evaluate(g, seat)
	}
	moves := orderBotMoves(g, g.LegalMoves())
	if len(moves) == 0 {
		return evaluate(g, seat)
	}
	best := -1 << 30
	for _, mv := range moves {
		undo, ok := g.applySearch(mv)
		if !ok {
			continue
		}
		s := searchTurn(g, seat, nodes, budget)
		g.undoSearch(undo)
		if s > best {
			best = s
		}
	}
	return best
}

type searchUndo struct {
	hit, boreOff bool
	headBefore   int
	from, die    int
}

func (g *Game) applySearch(mv Move) (searchUndo, bool) {
	undo := searchUndo{headBefore: g.HeadMoved, from: mv.From, die: mv.Die}
	hit, bore, err := g.applyMoveTracked(mv)
	if err != nil {
		return searchUndo{}, false
	}
	undo.hit = hit
	undo.boreOff = bore
	return undo, true
}

func (g *Game) undoSearch(u searchUndo) {
	seat := g.Turn
	to := u.from + u.die
	if u.from == BarTrack {
		to = u.die - 1
	}
	if u.boreOff {
		g.Off[seat]--
	} else {
		g.addAt(seat, to, -1)
		if u.hit {
			opp := Opponent(seat)
			oppTrack := BoardToTrack(g.Mode, opp, TrackToBoard(g.Mode, seat, to))
			g.addAt(opp, oppTrack, 1)
			g.Bar[opp]--
		}
	}
	if u.from == BarTrack {
		g.Bar[seat]++
	} else {
		g.addAt(seat, u.from, 1)
	}
	g.Dice = append(g.Dice, u.die)
	g.HeadMoved = u.headBefore
}

// orderBotMoves ставит снятие и бой вперёд, чтобы при обрезке дубля
// сильные линии успели посчитаться.
func orderBotMoves(g *Game, moves []Move) []Move {
	if len(moves) < 2 {
		return moves
	}
	out := append([]Move(nil), moves...)
	key := func(mv Move) int {
		k := mv.Die
		to := mv.From + mv.Die
		if mv.From == BarTrack {
			to = mv.Die - 1
			k += 40
		}
		if to >= Points {
			k += 80
		} else if g != nil && !g.IsLong() && g.OpponentAt(g.Turn, to) == 1 {
			k += 60
		}
		return k + to
	}
	for i := 1; i < len(out); i++ {
		for j := i; j > 0; j-- {
			if key(out[j]) > key(out[j-1]) {
				out[j], out[j-1] = out[j-1], out[j]
				continue
			}
			break
		}
	}
	return out
}

// evaluate — оценка позиции глазами [seat]; больше — лучше.
func evaluate(g *Game, seat int) int {
	opp := Opponent(seat)
	myPips := g.Pips(seat)
	oppPips := g.Pips(opp)
	race := oppPips - myPips
	score := race * 12
	if g.IsLong() || !inContact(g) {
		// Чистые гонки решают очки, а не «красота» строя.
		score += race * 8
	}
	score += g.Off[seat] * 140
	score -= g.Off[opp] * 140
	// Первая снятая шашка спасает от марса, когда соперник уже выбрасывает.
	if g.Off[seat] == 0 {
		score -= g.Off[opp] * 40
	} else {
		score += 80
	}
	if g.Off[opp] == 0 && myPips+8 < oppPips {
		score += g.Off[seat] * 25
	}
	if g.IsLong() {
		return score + evalLong(g, seat, opp)
	}
	return score + evalShort(g, seat, opp)
}

func evalShort(g *Game, seat, opp int) int {
	score := g.Bar[opp]*130 - g.Bar[seat]*170
	if g.Bar[opp] > 0 {
		score += homeMade(g, seat) * 45
	}
	if g.Bar[seat] > 0 {
		score -= homeMade(g, opp) * 50
	}
	score += primeLen(g, seat)*22 - primeLen(g, opp)*20
	contact := inContact(g)
	for t := 0; t < Points; t++ {
		mine := g.CountAt(seat, t)
		switch {
		case mine == 1:
			if contact {
				shots := directShotDice(g, seat, t)
				if shots > 4 {
					shots = 4
				}
				pen := 16 + 18*shots
				if t < 6 {
					pen -= 8
				}
				score -= pen
			} else {
				score -= 4
			}
		case mine >= 2:
			score += 10
			if t >= HomeStart {
				score += 22
			}
			if t < 6 {
				score += 18
			}
			if mine > 4 && t < HomeStart {
				score -= (mine - 4) * 8
			}
		}
		if contact && g.CountAt(opp, t) == 1 {
			shots := directShotDice(g, opp, t)
			if shots > 3 {
				shots = 3
			}
			if shots > 0 {
				score += 12 + 10*shots
			} else {
				score += 6
			}
		}
	}
	if g.AllHome(seat) {
		score += bearOffShape(g, seat)
	}
	if g.AllHome(opp) {
		score -= bearOffShape(g, opp) / 2
	}
	return score
}

func evalLong(g *Game, seat, opp int) int {
	score := 0
	score -= g.CountAt(seat, 0) * 36
	score += g.CountAt(opp, 0) * 20
	laggard := -1
	for t := 0; t < Points; t++ {
		n := g.CountAt(seat, t)
		if n == 0 {
			continue
		}
		if laggard < 0 {
			laggard = t
		}
		if t >= HomeStart {
			score += n * 6
		}
	}
	if laggard >= 0 {
		score += laggard * 8
	}
	oppLaggard := -1
	for t := 0; t < Points; t++ {
		if g.CountAt(opp, t) > 0 {
			oppLaggard = t
			break
		}
	}
	if oppLaggard >= 0 {
		block := 0
		for t := oppLaggard; t < Points; t++ {
			point := TrackToBoard(g.Mode, opp, t)
			myTrack := BoardToTrack(g.Mode, seat, point)
			if myTrack >= 0 && g.CountAt(seat, myTrack) > 0 {
				block++
			}
		}
		score += block * 14
	}
	score += primeLen(g, seat) * 8
	if g.AllHome(seat) {
		score += bearOffShape(g, seat)
	}
	return score
}

func homeMade(g *Game, seat int) int {
	n := 0
	for t := HomeStart; t < Points; t++ {
		if g.CountAt(seat, t) >= 2 {
			n++
		}
	}
	return n
}

func bearOffShape(g *Game, seat int) int {
	score := 0
	furthest := -1
	for t := HomeStart; t < Points; t++ {
		n := g.CountAt(seat, t)
		if n == 0 {
			continue
		}
		if furthest < 0 {
			furthest = t
		}
		score += n * (t - HomeStart) * 3
	}
	if furthest >= 0 {
		deep := g.CountAt(seat, furthest)
		if deep > 2 {
			score -= (deep - 2) * 6
		}
	}
	return score
}

// inContact — шашки ещё могут бить друг друга.
func inContact(g *Game) bool {
	if g.IsLong() {
		return false
	}
	if g.Bar[0] > 0 || g.Bar[1] > 0 {
		return true
	}
	for seat := 0; seat < 2; seat++ {
		opp := Opponent(seat)
		for t := 0; t < Points; t++ {
			if g.CountAt(seat, t) == 0 {
				continue
			}
			oppTrack := BoardToTrack(g.Mode, opp, TrackToBoard(g.Mode, seat, t))
			if oppTrack <= 0 {
				continue
			}
			for s := 0; s < oppTrack; s++ {
				if g.CountAt(opp, s) > 0 {
					return true
				}
			}
		}
	}
	return false
}

// directShotDice — сколькими разными кубиками соперник бьёт blot на [track].
func directShotDice(g *Game, seat, track int) int {
	opp := Opponent(seat)
	oppTrack := BoardToTrack(g.Mode, opp, TrackToBoard(g.Mode, seat, track))
	if oppTrack < 0 {
		return 0
	}
	dice := 0
	for d := 1; d <= 6; d++ {
		src := oppTrack - d
		if src >= 0 && g.CountAt(opp, src) > 0 {
			dice++
			continue
		}
		if src < 0 && g.Bar[opp] > 0 && oppTrack == d-1 {
			dice++
		}
	}
	return dice
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
