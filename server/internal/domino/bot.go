package domino

// Бот считает семёрки каждой масти по столу и своей руке.
// Чужие руки он читает только когда базар пуст и игроков двое:
// тогда невидимые кости и есть рука соперника.

const (
	botSearchDepth = 8
	botNodeCap     = 6000
)

func BestAction(g *Game, seat int) Action {
	if g == nil || g.Status != StatusPlaying || seat != g.Turn {
		return Action{}
	}
	moves := g.legal(seat)
	if len(moves) == 0 {
		if len(g.Boneyard) > 0 {
			return Action{Type: ActionDraw}
		}
		return Action{Type: ActionPass}
	}
	if action, ok := g.sampledSearch(seat, moves); ok {
		return action
	}
	best := moves[0]
	bestScore := -1 << 30
	for _, mv := range moves {
		score := g.heuristic(seat, mv)
		if score > bestScore || (score == bestScore && betterMove(mv, best)) {
			bestScore = score
			best = mv
		}
	}
	return Action{Type: ActionPlay, Tile: best.Tile, End: best.End}
}

func (g *Game) sampledSearch(seat int, moves []Move) (Action, bool) {
	if g.aliveCount() != 2 || len(moves) == 0 {
		return Action{}, false
	}
	opp := g.otherAlive(seat)
	if opp < 0 {
		return Action{}, false
	}
	unseen := g.unseen(seat)
	boneN := len(g.Boneyard)
	if boneN+len(g.Players[opp].Hand) != len(unseen) || boneN > 2 {
		return Action{}, false
	}
	bones := combinations(unseen, boneN)
	if len(bones) == 0 || len(bones) > 10 {
		return Action{}, false
	}
	best := moves[0]
	bestValue := -1 << 30
	depth := botSearchDepth
	if len(bones) > 1 {
		depth = 5
	}
	for _, mv := range orderMoves(g, moves) {
		total := 0
		okN := 0
		for _, bone := range bones {
			root := g.withHypothesis(seat, opp, unseen, bone)
			next := root.clone()
			if err := next.Apply(Action{Type: ActionPlay, Tile: mv.Tile, End: mv.End}); err != nil {
				continue
			}
			nodes := 0
			total += next.minimax(seat, depth-1, -1<<30, 1<<30, &nodes)
			okN++
		}
		if okN == 0 {
			continue
		}
		value := total / okN
		if value > bestValue || (value == bestValue && betterMove(mv, best)) {
			bestValue = value
			best = mv
		}
	}
	return Action{Type: ActionPlay, Tile: best.Tile, End: best.End}, true
}

func (g *Game) withHypothesis(seat, opp int, unseen, bone []int) *Game {
	next := g.clone()
	inBone := make(map[int]bool, len(bone))
	for _, id := range bone {
		inBone[id] = true
	}
	hand := make([]int, 0, len(unseen))
	for _, id := range unseen {
		if !inBone[id] {
			hand = append(hand, id)
		}
	}
	next.Players[opp].Hand = hand
	next.Boneyard = append([]int(nil), bone...)
	_ = seat
	return next
}

func combinations(items []int, k int) [][]int {
	if k == 0 {
		return [][]int{{}}
	}
	if k < 0 || k > len(items) {
		return nil
	}
	var out [][]int
	var walk func(start int, cur []int)
	walk = func(start int, cur []int) {
		if len(cur) == k {
			out = append(out, append([]int(nil), cur...))
			return
		}
		need := k - len(cur)
		for i := start; i <= len(items)-need; i++ {
			walk(i+1, append(cur, items[i]))
		}
	}
	walk(0, nil)
	return out
}

func betterMove(a, b Move) bool {
	if PipSum([]int{a.Tile}) != PipSum([]int{b.Tile}) {
		return PipSum([]int{a.Tile}) > PipSum([]int{b.Tile})
	}
	if a.Tile != b.Tile {
		return a.Tile < b.Tile
	}
	return a.End == "left" && b.End != "left"
}

func (g *Game) otherAlive(seat int) int {
	found := -1
	for i := range g.Players {
		if i == seat || g.Players[i].Forfeited {
			continue
		}
		if found >= 0 {
			return -1
		}
		found = i
	}
	return found
}

func (g *Game) unseen(seat int) []int {
	known := make([]bool, TileCount)
	if seat >= 0 && seat < len(g.Players) {
		for _, id := range g.Players[seat].Hand {
			if id >= 0 && id < TileCount {
				known[id] = true
			}
		}
	}
	for _, placed := range g.Chain {
		if placed.ID >= 0 && placed.ID < TileCount {
			known[placed.ID] = true
		}
	}
	out := make([]int, 0, TileCount)
	for id := 0; id < TileCount; id++ {
		if !known[id] {
			out = append(out, id)
		}
	}
	return out
}

func (g *Game) knownSuit(seat, suit, extraTile int) int {
	if suit < 0 {
		return 0
	}
	seen := make([]bool, TileCount)
	mark := func(id int) {
		if id < 0 || id >= TileCount || seen[id] {
			return
		}
		lo, hi := Pips(id)
		if lo == suit || hi == suit {
			seen[id] = true
		}
	}
	for _, placed := range g.Chain {
		mark(placed.ID)
	}
	if seat >= 0 && seat < len(g.Players) {
		for _, id := range g.Players[seat].Hand {
			mark(id)
		}
	}
	mark(extraTile)
	n := 0
	for _, ok := range seen {
		if ok {
			n++
		}
	}
	return n
}

func (g *Game) heuristic(seat int, mv Move) int {
	lo, hi := Pips(mv.Tile)
	score := (lo + hi) * 20
	if lo == hi {
		score += 24
	}
	if g.normalizedMode() == ModeSea && mv.Tile == TileID(0, 0) {
		score += 500
	}
	hand := make([]int, 0, len(g.Players[seat].Hand))
	for _, id := range g.Players[seat].Hand {
		if id != mv.Tile {
			hand = append(hand, id)
		}
	}
	if len(hand) == 0 {
		score += 9000
	}
	left, right := g.LeftEnd, g.RightEnd
	if left < 0 {
		left, right = lo, hi
	} else if mv.End == "left" || mv.End == "start" {
		_, out := orient(mv.Tile, left)
		left = out
	} else {
		_, out := orient(mv.Tile, right)
		right = out
	}
	flex := 0
	for _, id := range hand {
		if tileMatches(id, left) || tileMatches(id, right) {
			flex++
		}
	}
	score += flex * 6
	oppLeft := 0
	if other := g.otherAlive(seat); other >= 0 {
		oppLeft = len(g.Players[other].Hand)
	}
	deadBonus := 12
	if len(g.Boneyard) == 0 {
		deadBonus = 84
		if oppLeft <= 2 {
			deadBonus += 24
		}
	}
	leftDead := g.knownSuit(seat, left, mv.Tile) >= SuitCopies
	rightDead := g.knownSuit(seat, right, mv.Tile) >= SuitCopies
	if leftDead {
		score += deadBonus
	}
	if rightDead {
		score += deadBonus
	}
	if len(g.Boneyard) == 0 && leftDead && rightDead && flex == 0 {
		mine := PipSum(hand)
		if mine <= 10 {
			score += 140
		} else {
			score -= mine * 2
		}
	}
	return score
}

func orderMoves(g *Game, moves []Move) []Move {
	out := append([]Move(nil), moves...)
	for i := 1; i < len(out); i++ {
		j := i
		for j > 0 && betterMove(out[j], out[j-1]) {
			out[j], out[j-1] = out[j-1], out[j]
			j--
		}
	}
	_ = g
	return out
}

func (g *Game) minimax(root, depth, alpha, beta int, nodes *int) int {
	*nodes++
	if g.Status != StatusPlaying || depth <= 0 || *nodes > botNodeCap {
		return evalRound(g, root)
	}
	seat := g.Turn
	moves := g.legal(seat)
	actions := make([]Action, 0, len(moves)+1)
	if len(moves) == 0 {
		if len(g.Boneyard) > 0 {
			actions = append(actions, Action{Type: ActionDraw})
		} else {
			actions = append(actions, Action{Type: ActionPass})
		}
	} else {
		for _, mv := range orderMoves(g, moves) {
			actions = append(actions, Action{Type: ActionPlay, Tile: mv.Tile, End: mv.End})
		}
	}
	if seat == root {
		value := -1 << 30
		for _, action := range actions {
			next := g.clone()
			if err := next.Apply(action); err != nil {
				continue
			}
			score := next.minimax(root, depth-1, alpha, beta, nodes)
			if score > value {
				value = score
			}
			if value > alpha {
				alpha = value
			}
			if beta <= alpha {
				break
			}
		}
		if value == -1<<30 {
			return evalRound(g, root)
		}
		return value
	}
	value := 1 << 30
	for _, action := range actions {
		next := g.clone()
		if err := next.Apply(action); err != nil {
			continue
		}
		score := next.minimax(root, depth-1, alpha, beta, nodes)
		if score < value {
			value = score
		}
		if value < beta {
			beta = value
		}
		if beta <= alpha {
			break
		}
	}
	if value == 1<<30 {
		return evalRound(g, root)
	}
	return value
}

func evalRound(g *Game, root int) int {
	if root < 0 || root >= len(g.Players) {
		return 0
	}
	if g.Status == StatusRoundEnd || g.Status == StatusOver {
		opp := 0
		for i := range g.Players {
			if i == root || g.Players[i].Forfeited {
				continue
			}
			opp += g.Players[i].RoundDelta
		}
		value := opp*4 - g.Players[root].RoundDelta*5
		if g.normalizedMode() == ModeClassic {
			value = g.Players[root].RoundDelta*5 - opp*4
		}
		if g.RoundKind == RoundOut && g.OutSeat == root {
			value += 8000
		}
		if g.RoundKind == RoundOut && g.OutSeat >= 0 && g.OutSeat != root {
			value -= 8000
		}
		if g.GoatSeat == root {
			value -= 20000
		}
		for _, id := range g.WinnerUserIDs {
			if id == g.Players[root].UserID {
				value += 20000
			}
		}
		return value
	}
	mine := PipSum(g.Players[root].Hand)
	opp := 0
	for i := range g.Players {
		if i == root || g.Players[i].Forfeited {
			continue
		}
		opp += PipSum(g.Players[i].Hand)
	}
	return opp - mine*2
}
