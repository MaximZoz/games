// Package nardy реализует правила коротких и длинных нард.
//
// Доска — 24 пункта. Каждый игрок ходит по своей «дорожке»: индекс дорожки
// 0 — голова, 23 — последний пункт дома. Такая нормализация позволяет писать
// правила один раз для обоих режимов: отличаются только отображение дорожки
// на физические пункты, бой и правило головы.
package nardy

import (
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
)

const (
	// ModeShort — короткие нарды (встречное движение, бой шашек).
	ModeShort = "short"
	// ModeLong — длинные нарды (с одной головы, без боя).
	ModeLong = "long"

	// Points — количество пунктов на доске.
	Points = 24
	// Checkers — шашек у каждого игрока.
	Checkers = 15
	// HomeStart — первый индекс дорожки, входящий в дом.
	HomeStart = 18
	// BarTrack — псевдо-индекс дорожки для шашки на баре (короткие нарды).
	BarTrack = -1
	// OffTrack — индекс «снята с доски».
	OffTrack = Points
	// PrimeLimit — длина заблокированного ряда в длинных нардах.
	//
	// Шесть своих пунктов подряд запирают соперника наглухо, поэтому такой
	// ряд разрешён, только если хотя бы одна его шашка уже прошла блок.
	PrimeLimit = 6
)

var (
	ErrNotYourTurn   = errors.New("not your turn")
	ErrDiceRolled    = errors.New("dice already rolled")
	ErrNoDice        = errors.New("no dice to move")
	ErrIllegalMove   = errors.New("illegal move")
	ErrGameOver      = errors.New("game is over")
	ErrInvalidState  = errors.New("invalid state")
	ErrNothingToUndo = errors.New("nothing to undo")
	ErrMovesLeft     = errors.New("moves are still available")
)

// NormalizeMode приводит режим к одному из поддерживаемых.
func NormalizeMode(mode string) string {
	if mode == ModeLong {
		return ModeLong
	}
	return ModeShort
}

// Move — один переход шашки: с какого пункта дорожки и каким кубиком.
type Move struct {
	From int `json:"from"`
	Die  int `json:"die"`
}

// MoveRecord — сыгранный ход и всё нужное, чтобы его откатить.
type MoveRecord struct {
	From int `json:"from"`
	Die  int `json:"die"`
	// Hit — сбили одиночную шашку соперника (короткие нарды).
	Hit bool `json:"hit"`
	// BoreOff — шашка ушла за доску.
	BoreOff bool `json:"bore_off"`
	// DiceBefore — набор кубиков до хода: правило максимума могло срезать
	// оставшиеся, поэтому восстанавливаем снимком, а не возвратом одного.
	DiceBefore []int `json:"dice_before"`
	HeadBefore int   `json:"head_before"`
}

// TurnMove — сыгранный ход в физических пунктах доски (для подсветки).
type TurnMove struct {
	FromPoint int  `json:"from_point"`
	ToPoint   int  `json:"to_point"`
	FromBar   bool `json:"from_bar"`
	BoreOff   bool `json:"bore_off"`
	Hit       bool `json:"hit"`
}

// Game — состояние партии.
type Game struct {
	Mode string `json:"mode"`
	// Points — физические пункты: >0 шашки игрока 0, <0 шашки игрока 1.
	Board [Points]int `json:"board"`
	// Bar — шашки на баре (только короткие нарды).
	Bar [2]int `json:"bar"`
	// Off — снятые с доски шашки.
	Off [2]int `json:"off"`
	// Turn — чей ход (0 или 1).
	Turn int `json:"turn"`
	// Dice — оставшиеся неиспользованные кубики.
	Dice []int `json:"dice"`
	// Rolled — последний бросок (для показа кубиков).
	Rolled []int `json:"rolled"`
	// HeadMoved — сколько шашек ушло с головы в этом ходу (длинные нарды).
	HeadMoved int `json:"head_moved"`
	// TurnNo — номер хода с начала партии, начиная с 0.
	TurnNo int `json:"turn_no"`
	// Winner — победитель или -1.
	Winner int `json:"winner"`
	// WinKind — "single" или "mars" (соперник не снял ни одной шашки).
	WinKind string `json:"win_kind"`
	// History — ходы текущего хода; позволяет отменить последний.
	History []MoveRecord `json:"history"`
	// LastTurn — ходы предыдущего завершённого хода (подсветка у соперника).
	LastTurn []TurnMove `json:"last_turn"`
	// LastTurnSeat — чей это был ход, или -1.
	LastTurnSeat int `json:"last_turn_seat"`
	// Seq — монотонный счётчик изменений: отмена хода откатывает позицию,
	// поэтому «свежесть» снимка нельзя мерить прогрессом партии.
	Seq int `json:"seq"`
}

// NewGame создаёт стартовую расстановку выбранного режима.
func NewGame(mode string) *Game {
	g := &Game{
		Mode:         NormalizeMode(mode),
		Turn:         0,
		Winner:       -1,
		Dice:         []int{},
		Rolled:       []int{},
		History:      []MoveRecord{},
		LastTurn:     []TurnMove{},
		LastTurnSeat: -1,
	}
	if g.Mode == ModeLong {
		// Обе головы полные: 15 шашек на своей голове.
		g.setTrack(0, 0, Checkers)
		g.setTrack(1, 0, Checkers)
		return g
	}
	// Короткие нарды: классическая расстановка в координатах дорожки.
	for _, seat := range []int{0, 1} {
		g.setTrack(seat, 0, 2)
		g.setTrack(seat, 11, 5)
		g.setTrack(seat, 16, 3)
		g.setTrack(seat, 18, 5)
	}
	return g
}

// TrackToBoard переводит индекс дорожки игрока в физический пункт.
func TrackToBoard(mode string, seat, track int) int {
	if track < 0 || track >= Points {
		return -1
	}
	if seat == 0 {
		return Points - 1 - track
	}
	if NormalizeMode(mode) == ModeLong {
		// Голова второго игрока — физический пункт 11, движение по кругу.
		return ((11 - track) + Points) % Points
	}
	return track
}

// BoardToTrack — обратное преобразование.
func BoardToTrack(mode string, seat, point int) int {
	if point < 0 || point >= Points {
		return -1
	}
	if seat == 0 {
		return Points - 1 - point
	}
	if NormalizeMode(mode) == ModeLong {
		return ((11 - point) + Points) % Points
	}
	return point
}

func (g *Game) setTrack(seat, track, count int) {
	p := TrackToBoard(g.Mode, seat, track)
	if p < 0 {
		return
	}
	if seat == 0 {
		g.Board[p] = count
		return
	}
	g.Board[p] = -count
}

// CountAt — сколько шашек игрока стоит на пункте дорожки.
func (g *Game) CountAt(seat, track int) int {
	p := TrackToBoard(g.Mode, seat, track)
	if p < 0 {
		return 0
	}
	v := g.Board[p]
	if seat == 0 {
		if v > 0 {
			return v
		}
		return 0
	}
	if v < 0 {
		return -v
	}
	return 0
}

// OpponentAt — сколько шашек соперника стоит на пункте дорожки игрока.
func (g *Game) OpponentAt(seat, track int) int {
	p := TrackToBoard(g.Mode, seat, track)
	if p < 0 {
		return 0
	}
	v := g.Board[p]
	if seat == 0 {
		if v < 0 {
			return -v
		}
		return 0
	}
	if v > 0 {
		return v
	}
	return 0
}

func (g *Game) addAt(seat, track, delta int) {
	p := TrackToBoard(g.Mode, seat, track)
	if p < 0 {
		return
	}
	if seat == 0 {
		g.Board[p] += delta
		return
	}
	g.Board[p] -= delta
}

// IsLong — режим длинных нард.
func (g *Game) IsLong() bool { return NormalizeMode(g.Mode) == ModeLong }

// Opponent — соперник указанного места.
func Opponent(seat int) int {
	if seat == 0 {
		return 1
	}
	return 0
}

// AllHome — все шашки игрока в доме (можно выбрасывать).
func (g *Game) AllHome(seat int) bool {
	if g.Bar[seat] > 0 {
		return false
	}
	for t := 0; t < HomeStart; t++ {
		if g.CountAt(seat, t) > 0 {
			return false
		}
	}
	return true
}

// CanLand — можно ли поставить шашку на пункт дорожки.
func (g *Game) CanLand(seat, track int) bool {
	if track < 0 || track >= Points {
		return false
	}
	opp := g.OpponentAt(seat, track)
	if opp == 0 {
		return true
	}
	if g.IsLong() {
		// В длинных нардах бой запрещён — любой чужой пункт закрыт.
		return false
	}
	// В коротких можно бить одиночную шашку.
	return opp == 1
}

// headLimitReached — из головы уже ушло максимально разрешённое число шашек.
func (g *Game) headLimitReached() bool {
	if !g.IsLong() {
		return false
	}
	return g.HeadMoved >= g.headAllowance()
}

// headAllowance — сколько шашек можно снять с головы за ход.
//
// Первый ход при 3-3, 4-4 и 6-6 разрешает две шашки с головы.
func (g *Game) headAllowance() int {
	if !g.IsLong() {
		return Checkers
	}
	if g.TurnNo < 2 && len(g.Rolled) == 4 {
		switch g.Rolled[0] {
		case 3, 4, 6:
			return 2
		}
	}
	return 1
}

// LegalMoves — все допустимые ходы текущими кубиками.
func (g *Game) LegalMoves() []Move {
	if g.Winner >= 0 || len(g.Dice) == 0 {
		return nil
	}
	seat := g.Turn
	dice := uniqueInts(g.Dice)
	var out []Move
	// Короткие нарды: пока есть шашки на баре — только ввод в игру.
	if !g.IsLong() && g.Bar[seat] > 0 {
		for _, die := range dice {
			if g.CanLand(seat, die-1) {
				out = append(out, Move{From: BarTrack, Die: die})
			}
		}
		return out
	}
	allHome := g.AllHome(seat)
	for t := 0; t < Points; t++ {
		if g.CountAt(seat, t) == 0 {
			continue
		}
		if t == 0 && g.headLimitReached() && g.CountAt(seat, 0) > 0 {
			continue
		}
		for _, die := range dice {
			if g.moveAllowed(seat, t, die, allHome) {
				out = append(out, Move{From: t, Die: die})
			}
		}
	}
	return out
}

func (g *Game) moveAllowed(seat, from, die int, allHome bool) bool {
	if from < 0 || from >= Points || die < 1 || die > 6 {
		return false
	}
	if g.CountAt(seat, from) == 0 {
		return false
	}
	if from == 0 && g.headLimitReached() {
		return false
	}
	to := from + die
	if to < Points {
		return g.CanLand(seat, to) && !g.buildsSealedPrime(seat, from, to)
	}
	if !allHome {
		return false
	}
	if to == Points {
		return true
	}
	// Перебор: снимать можно только с самого дальнего занятого пункта.
	for t := HomeStart; t < from; t++ {
		if g.CountAt(seat, t) > 0 {
			return false
		}
	}
	return true
}

// buildsSealedPrime — ход достраивает запертый ряд из [PrimeLimit] пунктов.
//
// Только длинные нарды: в коротких «прайм» — обычный приём игры.
func (g *Game) buildsSealedPrime(seat, from, to int) bool {
	if !g.IsLong() {
		return false
	}
	fromPoint := TrackToBoard(g.Mode, seat, from)
	toPoint := TrackToBoard(g.Mode, seat, to)
	if fromPoint < 0 || toPoint < 0 {
		return false
	}
	board := g.Board
	if seat == 0 {
		board[fromPoint]--
		board[toPoint]++
	} else {
		board[fromPoint]++
		board[toPoint]--
	}
	return HasSealedPrime(g.Mode, seat, board, g.Off[Opponent(seat)])
}

// HasSealedPrime — у [seat] есть ряд из [PrimeLimit] занятых пунктов подряд,
// который не обошла ни одна шашка соперника.
//
// Считаем в координатах дорожки соперника: он идёт 0 → 23, поэтому «прошла»
// значит стоит дальше конца ряда либо уже снята с доски.
func HasSealedPrime(mode string, seat int, board [Points]int, oppOff int) bool {
	if NormalizeMode(mode) != ModeLong {
		return false
	}
	if oppOff > 0 {
		return false
	}
	opp := Opponent(seat)
	var mine, theirs [Points]bool
	for t := 0; t < Points; t++ {
		p := TrackToBoard(mode, opp, t)
		if p < 0 {
			continue
		}
		v := board[p]
		if seat == 0 {
			mine[t] = v > 0
			theirs[t] = v < 0
		} else {
			mine[t] = v < 0
			theirs[t] = v > 0
		}
	}
	run := 0
	for t := 0; t < Points; t++ {
		if !mine[t] {
			run = 0
			continue
		}
		run++
		if run < PrimeLimit {
			continue
		}
		ahead := false
		for k := t + 1; k < Points; k++ {
			if theirs[k] {
				ahead = true
				break
			}
		}
		if !ahead {
			return true
		}
	}
	return false
}

// HasLegalMove — есть ли хоть один ход.
func (g *Game) HasLegalMove() bool { return len(g.LegalMoves()) > 0 }

// Roll бросает кубики за текущего игрока.
func (g *Game) Roll(rng *rand.Rand) error {
	if g.Winner >= 0 {
		return ErrGameOver
	}
	if len(g.Dice) > 0 {
		return ErrDiceRolled
	}
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	a := rng.Intn(6) + 1
	b := rng.Intn(6) + 1
	g.applyRoll(a, b)
	return nil
}

// RollWith задаёт конкретный бросок (тесты и восстановление состояния).
func (g *Game) RollWith(a, b int) error {
	if g.Winner >= 0 {
		return ErrGameOver
	}
	if len(g.Dice) > 0 {
		return ErrDiceRolled
	}
	if a < 1 || a > 6 || b < 1 || b > 6 {
		return ErrInvalidState
	}
	g.applyRoll(a, b)
	return nil
}

func (g *Game) applyRoll(a, b int) {
	g.Seq++
	g.HeadMoved = 0
	g.History = g.History[:0]
	if a == b {
		g.Rolled = []int{a, a, a, a}
		g.Dice = []int{a, a, a, a}
	} else {
		g.Rolled = []int{a, b}
		g.Dice = []int{a, b}
	}
	g.dropUnusableDice()
	if len(g.Dice) == 0 {
		g.EndTurn()
	}
}

// dropUnusableDice убирает кубики, которыми точно нельзя сходить.
//
// Правило «использовать максимум кубиков»: если играется только один из двух,
// обязателен больший.
func (g *Game) dropUnusableDice() {
	if len(g.Dice) == 0 {
		return
	}
	if g.HasLegalMove() {
		g.enforceMaxDice()
		return
	}
	g.Dice = g.Dice[:0]
}

// enforceMaxDice для пары разных кубиков оставляет только те варианты,
// которые дают максимальное число ходов (и больший кубик при равенстве).
func (g *Game) enforceMaxDice() {
	if len(g.Dice) != 2 || g.Dice[0] == g.Dice[1] {
		return
	}
	a, b := g.Dice[0], g.Dice[1]
	if g.bestSequence(2) == 2 {
		return
	}
	canA := g.playableSingle(a)
	canB := g.playableSingle(b)
	if canA && canB {
		// Играется только один кубик — обязателен больший.
		if a > b {
			g.Dice = []int{a}
		} else {
			g.Dice = []int{b}
		}
		return
	}
	if canA {
		g.Dice = []int{a}
		return
	}
	if canB {
		g.Dice = []int{b}
		return
	}
	g.Dice = g.Dice[:0]
}

func (g *Game) playableSingle(die int) bool {
	clone := g.Clone()
	clone.Dice = []int{die}
	return clone.HasLegalMove()
}

// bestSequence — максимальная длина последовательности ходов из текущей позиции.
func (g *Game) bestSequence(limit int) int {
	if limit <= 0 || len(g.Dice) == 0 {
		return 0
	}
	best := 0
	for _, mv := range g.LegalMoves() {
		clone := g.Clone()
		if err := clone.applyMoveRaw(mv); err != nil {
			continue
		}
		got := 1 + clone.bestSequence(limit-1)
		if got > best {
			best = got
		}
		if best >= limit {
			return best
		}
	}
	return best
}

// ApplyMove выполняет ход текущего игрока.
func (g *Game) ApplyMove(seat int, mv Move) error {
	if g.Winner >= 0 {
		return ErrGameOver
	}
	if seat != g.Turn {
		return ErrNotYourTurn
	}
	if len(g.Dice) == 0 {
		return ErrNoDice
	}
	if !g.isLegal(mv) {
		return fmt.Errorf("%w: from %d die %d", ErrIllegalMove, mv.From, mv.Die)
	}
	diceBefore := append([]int(nil), g.Dice...)
	headBefore := g.HeadMoved
	hit, boreOff, err := g.applyMoveTracked(mv)
	if err != nil {
		return err
	}
	g.History = append(g.History, MoveRecord{
		From:       mv.From,
		Die:        mv.Die,
		Hit:        hit,
		BoreOff:    boreOff,
		DiceBefore: diceBefore,
		HeadBefore: headBefore,
	})
	g.Seq++
	g.checkWinner()
	if g.Winner >= 0 {
		g.Dice = g.Dice[:0]
		g.History = g.History[:0]
		return nil
	}
	// Ход не закрываем сами: игрок ещё может отменить последнюю шашку.
	g.dropUnusableDice()
	return nil
}

// TurnComplete — кубиков не осталось, ход ждёт подтверждения.
func (g *Game) TurnComplete() bool {
	return g.Winner < 0 && len(g.Dice) == 0
}

// CanUndo — есть что откатить в текущем ходу.
func (g *Game) CanUndo() bool { return g.Winner < 0 && len(g.History) > 0 }

// Undo откатывает последний ход текущего игрока.
func (g *Game) Undo(seat int) error {
	if g.Winner >= 0 {
		return ErrGameOver
	}
	if seat != g.Turn {
		return ErrNotYourTurn
	}
	if len(g.History) == 0 {
		return ErrNothingToUndo
	}
	rec := g.History[len(g.History)-1]
	g.History = g.History[:len(g.History)-1]

	to := rec.From + rec.Die
	if rec.From == BarTrack {
		to = rec.Die - 1
	}
	if rec.BoreOff {
		g.Off[seat]--
	} else {
		g.addAt(seat, to, -1)
		if rec.Hit {
			opp := Opponent(seat)
			oppTrack := BoardToTrack(g.Mode, opp, TrackToBoard(g.Mode, seat, to))
			g.addAt(opp, oppTrack, 1)
			g.Bar[opp]--
		}
	}
	if rec.From == BarTrack {
		g.Bar[seat]++
	} else {
		g.addAt(seat, rec.From, 1)
	}
	g.Dice = append([]int(nil), rec.DiceBefore...)
	g.HeadMoved = rec.HeadBefore
	g.Seq++
	return nil
}

func (g *Game) isLegal(mv Move) bool {
	for _, cand := range g.LegalMoves() {
		if cand == mv {
			return true
		}
	}
	return false
}

func (g *Game) applyMoveRaw(mv Move) error {
	_, _, err := g.applyMoveTracked(mv)
	return err
}

// applyMoveTracked двигает шашку и сообщает, был ли бой и снятие с доски.
func (g *Game) applyMoveTracked(mv Move) (hit bool, boreOff bool, err error) {
	seat := g.Turn
	idx := indexOf(g.Dice, mv.Die)
	if idx < 0 {
		return false, false, ErrIllegalMove
	}
	if mv.From == BarTrack {
		if g.Bar[seat] == 0 {
			return false, false, ErrIllegalMove
		}
		to := mv.Die - 1
		g.Bar[seat]--
		hit = g.hitIfNeeded(seat, to)
		g.addAt(seat, to, 1)
		g.Dice = removeAt(g.Dice, idx)
		return hit, false, nil
	}
	if g.CountAt(seat, mv.From) == 0 {
		return false, false, ErrIllegalMove
	}
	g.addAt(seat, mv.From, -1)
	if mv.From == 0 && g.IsLong() {
		g.HeadMoved++
	}
	to := mv.From + mv.Die
	if to >= Points {
		g.Off[seat]++
		boreOff = true
	} else {
		hit = g.hitIfNeeded(seat, to)
		g.addAt(seat, to, 1)
	}
	g.Dice = removeAt(g.Dice, idx)
	return hit, boreOff, nil
}

func (g *Game) hitIfNeeded(seat, track int) bool {
	if g.IsLong() {
		return false
	}
	if g.OpponentAt(seat, track) != 1 {
		return false
	}
	opp := Opponent(seat)
	oppTrack := BoardToTrack(g.Mode, opp, TrackToBoard(g.Mode, seat, track))
	g.addAt(opp, oppTrack, -1)
	g.Bar[opp]++
	return true
}

func (g *Game) checkWinner() {
	for seat := 0; seat < 2; seat++ {
		if g.Off[seat] < Checkers {
			continue
		}
		g.Winner = seat
		if g.Off[Opponent(seat)] == 0 {
			g.WinKind = "mars"
		} else {
			g.WinKind = "single"
		}
		return
	}
}

// EndTurn передаёт ход сопернику (пропуск при отсутствии ходов).
//
// Последний бросок не стираем: клиент показывает кубики, из-за которых ход
// пропущен, до броска соперника.
func (g *Game) EndTurn() {
	if g.Winner >= 0 {
		return
	}
	g.LastTurn = g.turnMovesForHighlight()
	g.LastTurnSeat = g.Turn
	g.History = g.History[:0]
	g.Dice = g.Dice[:0]
	g.HeadMoved = 0
	g.Turn = Opponent(g.Turn)
	g.TurnNo++
	g.Seq++
}

// turnMovesForHighlight — ходы этого хода в физических пунктах доски,
// чтобы соперник увидел, что именно произошло, независимо от своей дорожки.
func (g *Game) turnMovesForHighlight() []TurnMove {
	seat := g.Turn
	out := make([]TurnMove, 0, len(g.History))
	for _, rec := range g.History {
		item := TurnMove{
			FromBar: rec.From == BarTrack,
			BoreOff: rec.BoreOff,
			Hit:     rec.Hit,
		}
		to := rec.From + rec.Die
		if rec.From == BarTrack {
			item.FromPoint = -1
			to = rec.Die - 1
		} else {
			item.FromPoint = TrackToBoard(g.Mode, seat, rec.From)
		}
		if rec.BoreOff {
			item.ToPoint = -1
		} else {
			item.ToPoint = TrackToBoard(g.Mode, seat, to)
		}
		out = append(out, item)
	}
	return out
}

// Forfeit — сдача: побеждает соперник.
func (g *Game) Forfeit(seat int) {
	if g.Winner >= 0 {
		return
	}
	g.Winner = Opponent(seat)
	g.WinKind = "single"
	g.Dice = g.Dice[:0]
	g.History = g.History[:0]
	g.Seq++
}

// Clone — глубокая копия состояния.
func (g *Game) Clone() *Game {
	cp := *g
	cp.Dice = append([]int(nil), g.Dice...)
	cp.Rolled = append([]int(nil), g.Rolled...)
	cp.History = append([]MoveRecord(nil), g.History...)
	cp.LastTurn = append([]TurnMove(nil), g.LastTurn...)
	return &cp
}

// Pips — сколько очков осталось пройти игроку до снятия всех шашек.
func (g *Game) Pips(seat int) int {
	total := g.Bar[seat] * (Points + 1)
	for t := 0; t < Points; t++ {
		total += g.CountAt(seat, t) * (Points - t)
	}
	return total
}

// Encode сериализует состояние.
func Encode(g *Game) (string, error) {
	b, err := json.Marshal(g)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// Decode восстанавливает состояние.
func Decode(raw string) (*Game, error) {
	if raw == "" {
		return nil, ErrInvalidState
	}
	var g Game
	if err := json.Unmarshal([]byte(raw), &g); err != nil {
		return nil, err
	}
	g.Mode = NormalizeMode(g.Mode)
	if g.Dice == nil {
		g.Dice = []int{}
	}
	if g.Rolled == nil {
		g.Rolled = []int{}
	}
	if g.History == nil {
		g.History = []MoveRecord{}
	}
	if g.LastTurn == nil {
		g.LastTurn = []TurnMove{}
	}
	return &g, nil
}

func uniqueInts(in []int) []int {
	seen := make(map[int]struct{}, len(in))
	out := make([]int, 0, len(in))
	for _, v := range in {
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}

func indexOf(in []int, v int) int {
	for i, x := range in {
		if x == v {
			return i
		}
	}
	return -1
}

func removeAt(in []int, idx int) []int {
	out := make([]int, 0, len(in)-1)
	out = append(out, in[:idx]...)
	out = append(out, in[idx+1:]...)
	return out
}
