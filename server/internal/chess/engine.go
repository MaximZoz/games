// Package chess — классические шахматы 8×8 с полной проверкой легальности.
//
// Доска: 64 клетки row-major, индекс = r*8 + c. Ряд r=0 — первая горизонталь
// белых (ладьи/король), белые пешки на r=1 и идут вверх (к r=7). Чёрные пешки
// на r=6 и идут вниз. Seat 0 — белые, seat 1 — чёрные.
package chess

import (
	"encoding/json"
	"errors"
	"fmt"
)

const (
	ModeClassic = "classic"
	ModeRapid   = "rapid"
	ModeBlitz   = "blitz"
	ModeBullet  = "bullet"

	Empty = 0

	WhitePawn   = 1
	WhiteKnight = 2
	WhiteBishop = 3
	WhiteRook   = 4
	WhiteQueen  = 5
	WhiteKing   = 6
	BlackPawn   = 7
	BlackKnight = 8
	BlackBishop = 9
	BlackRook   = 10
	BlackQueen  = 11
	BlackKing   = 12

	WinnerNone = -1
	WinnerDraw = -2

	BotID = "bot:chess"
	Size  = 8

	// FiftyMovePlies — 50 ходов каждой стороны без прогресса (100 полуходов).
	FiftyMovePlies = 100

	DrawReasonStalemate    = "stalemate"
	DrawReasonInsufficient = "insufficient"
	DrawReasonRepetition   = "repetition"
	DrawReasonFiftyMove    = "fifty_move"
	DrawReasonAgreed       = "agreed"
)

var (
	ErrNotYourTurn = errors.New("not your turn")
	ErrIllegalMove = errors.New("illegal move")
	ErrGameOver    = errors.New("game is over")
)

// AllModes — порядок на карточке игры.
var AllModes = []string{ModeClassic, ModeRapid, ModeBlitz, ModeBullet}

// NormalizeMode — один из четырёх контролей; неизвестное → классика.
func NormalizeMode(mode string) string {
	switch mode {
	case ModeRapid, ModeBlitz, ModeBullet:
		return mode
	default:
		return ModeClassic
	}
}

// Square — клетка доски.
type Square struct {
	R int `json:"r"`
	C int `json:"c"`
}

// Move — ход; Promo != 0 для превращения пешки (тип фигуры: конь..ферзь).
type Move struct {
	From  Square `json:"from"`
	To    Square `json:"to"`
	Promo int    `json:"promo,omitempty"`
}

// Game — состояние партии.
type Game struct {
	Mode       string         `json:"mode"`
	Board      []int          `json:"board"`
	Turn       int            `json:"turn"`   // 0 белые, 1 чёрные
	Winner     int            `json:"winner"` // -1 идёт, -2 ничья, 0/1 победитель
	Seq        int            `json:"seq"`
	Castle     [4]bool        `json:"castle"`  // WK, WQ, BK, BQ
	EnPassant  int            `json:"ep"`      // индекс клетки взятия на проходе или -1
	HalfMove   int            `json:"halfmove"`
	LastFromR  int            `json:"last_from_r"`
	LastFromC  int            `json:"last_from_c"`
	LastToR    int            `json:"last_to_r"`
	LastToC    int            `json:"last_to_c"`
	PosCounts  map[string]int `json:"pos_counts,omitempty"`
	DrawReason string         `json:"draw_reason,omitempty"`
}

const (
	cWK = 0
	cWQ = 1
	cBK = 2
	cBQ = 3
)

// NewGame — стартовая расстановка.
func NewGame(mode string) *Game {
	g := &Game{
		Mode:      NormalizeMode(mode),
		Board:     make([]int, Size*Size),
		Turn:      0,
		Winner:    WinnerNone,
		Castle:    [4]bool{true, true, true, true},
		EnPassant: -1,
		LastFromR: -1,
		LastFromC: -1,
		LastToR:   -1,
		LastToC:   -1,
		PosCounts: map[string]int{},
	}
	back := []int{WhiteRook, WhiteKnight, WhiteBishop, WhiteQueen, WhiteKing, WhiteBishop, WhiteKnight, WhiteRook}
	for c := 0; c < Size; c++ {
		g.set(0, c, back[c])
		g.set(1, c, WhitePawn)
		g.set(6, c, BlackPawn)
		g.set(7, c, back[c]+6)
	}
	g.PosCounts[g.positionKey()] = 1
	return g
}

func (g *Game) idx(r, c int) int { return r*Size + c }

func inBounds(r, c int) bool { return r >= 0 && c >= 0 && r < Size && c < Size }

func (g *Game) at(r, c int) int {
	if !inBounds(r, c) {
		return -1
	}
	return g.Board[g.idx(r, c)]
}

func (g *Game) set(r, c, v int) { g.Board[g.idx(r, c)] = v }

func (g *Game) IsOver() bool { return g != nil && g.Winner != WinnerNone }

// Clone — глубокая копия для поиска хода бота.
func (g *Game) Clone() *Game {
	if g == nil {
		return nil
	}
	cp := *g
	cp.Board = append([]int(nil), g.Board...)
	if g.PosCounts != nil {
		cp.PosCounts = make(map[string]int, len(g.PosCounts))
		for k, v := range g.PosCounts {
			cp.PosCounts[k] = v
		}
	}
	return &cp
}

func colorOf(piece int) int {
	if piece >= WhitePawn && piece <= WhiteKing {
		return 0
	}
	if piece >= BlackPawn && piece <= BlackKing {
		return 1
	}
	return -1
}

// kind — тип фигуры 1..6 (пешка..король) без цвета.
func kind(piece int) int {
	if piece <= Empty {
		return 0
	}
	return ((piece - 1) % 6) + 1
}

// LegalMoves — все легальные ходы текущего игрока.
func (g *Game) LegalMoves() []Move {
	if g == nil || g.IsOver() {
		return nil
	}
	return g.legalMovesFor(g.Turn)
}

func (g *Game) legalMovesFor(seat int) []Move {
	pseudo := g.pseudoMoves(seat)
	out := make([]Move, 0, len(pseudo))
	for _, mv := range pseudo {
		child := g.Clone()
		child.applyRaw(seat, mv)
		if !child.kingInCheck(seat) {
			out = append(out, mv)
		}
	}
	return out
}

// pseudoMoves — псевдолегальные ходы (без учёта собственного шаха).
func (g *Game) pseudoMoves(seat int) []Move {
	var out []Move
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			p := g.at(r, c)
			if colorOf(p) != seat {
				continue
			}
			switch kind(p) {
			case 1:
				out = append(out, g.pawnMoves(r, c, seat)...)
			case 2:
				out = append(out, g.stepMoves(r, c, seat, knightDirs, false)...)
			case 3:
				out = append(out, g.stepMoves(r, c, seat, bishopDirs, true)...)
			case 4:
				out = append(out, g.stepMoves(r, c, seat, rookDirs, true)...)
			case 5:
				out = append(out, g.stepMoves(r, c, seat, queenDirs, true)...)
			case 6:
				out = append(out, g.stepMoves(r, c, seat, queenDirs, false)...)
				out = append(out, g.castleMoves(r, c, seat)...)
			}
		}
	}
	return out
}

var (
	knightDirs = [][2]int{{2, 1}, {2, -1}, {-2, 1}, {-2, -1}, {1, 2}, {1, -2}, {-1, 2}, {-1, -2}}
	bishopDirs = [][2]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}
	rookDirs   = [][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	queenDirs  = [][2]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}}
)

func (g *Game) stepMoves(r, c, seat int, dirs [][2]int, sliding bool) []Move {
	var out []Move
	from := Square{R: r, C: c}
	for _, d := range dirs {
		nr, nc := r+d[0], c+d[1]
		for inBounds(nr, nc) {
			target := g.at(nr, nc)
			if target == Empty {
				out = append(out, Move{From: from, To: Square{R: nr, C: nc}})
			} else {
				if colorOf(target) != seat {
					out = append(out, Move{From: from, To: Square{R: nr, C: nc}})
				}
				break
			}
			if !sliding {
				break
			}
			nr += d[0]
			nc += d[1]
		}
	}
	return out
}

func (g *Game) pawnMoves(r, c, seat int) []Move {
	var out []Move
	from := Square{R: r, C: c}
	fwd := 1
	startRow := 1
	promoRow := Size - 1
	if seat == 1 {
		fwd = -1
		startRow = Size - 2
		promoRow = 0
	}
	// Ход вперёд.
	nr := r + fwd
	if inBounds(nr, c) && g.at(nr, c) == Empty {
		out = append(out, g.pawnPushOrPromo(from, Square{R: nr, C: c}, nr == promoRow)...)
		if r == startRow {
			nr2 := r + 2*fwd
			if g.at(nr2, c) == Empty {
				out = append(out, Move{From: from, To: Square{R: nr2, C: c}})
			}
		}
	}
	// Взятия.
	for _, dc := range []int{-1, 1} {
		tr, tc := r+fwd, c+dc
		if !inBounds(tr, tc) {
			continue
		}
		target := g.at(tr, tc)
		if target != Empty && colorOf(target) != seat && colorOf(target) >= 0 {
			out = append(out, g.pawnPushOrPromo(from, Square{R: tr, C: tc}, tr == promoRow)...)
			continue
		}
		if g.EnPassant >= 0 && g.idx(tr, tc) == g.EnPassant {
			out = append(out, Move{From: from, To: Square{R: tr, C: tc}})
		}
	}
	return out
}

func (g *Game) pawnPushOrPromo(from, to Square, promo bool) []Move {
	if !promo {
		return []Move{{From: from, To: to}}
	}
	out := make([]Move, 0, 4)
	for _, p := range []int{5, 4, 3, 2} { // ферзь, ладья, слон, конь
		out = append(out, Move{From: from, To: to, Promo: p})
	}
	return out
}

func (g *Game) castleMoves(r, c, seat int) []Move {
	var out []Move
	if g.kingInCheck(seat) {
		return out
	}
	home := 0
	kingSide, queenSide := cWK, cWQ
	if seat == 1 {
		home = Size - 1
		kingSide, queenSide = cBK, cBQ
	}
	if r != home || c != 4 {
		return out
	}
	from := Square{R: r, C: c}
	// Короткая: e-f-g, ладья на h.
	if g.Castle[kingSide] && g.at(home, 5) == Empty && g.at(home, 6) == Empty &&
		kind(g.at(home, 7)) == 4 && colorOf(g.at(home, 7)) == seat {
		if !g.squareAttacked(home, 5, 1-seat) && !g.squareAttacked(home, 6, 1-seat) {
			out = append(out, Move{From: from, To: Square{R: home, C: 6}})
		}
	}
	// Длинная: d-c-b пусты, ладья на a.
	if g.Castle[queenSide] && g.at(home, 3) == Empty && g.at(home, 2) == Empty &&
		g.at(home, 1) == Empty && kind(g.at(home, 0)) == 4 && colorOf(g.at(home, 0)) == seat {
		if !g.squareAttacked(home, 3, 1-seat) && !g.squareAttacked(home, 2, 1-seat) {
			out = append(out, Move{From: from, To: Square{R: home, C: 2}})
		}
	}
	return out
}

// kingInCheck — под шахом ли король seat.
func (g *Game) kingInCheck(seat int) bool {
	kr, kc := g.findKing(seat)
	if kr < 0 {
		return false
	}
	return g.squareAttacked(kr, kc, 1-seat)
}

func (g *Game) findKing(seat int) (int, int) {
	target := WhiteKing
	if seat == 1 {
		target = BlackKing
	}
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			if g.at(r, c) == target {
				return r, c
			}
		}
	}
	return -1, -1
}

// squareAttacked — атакована ли клетка (r,c) фигурами цвета byColor.
func (g *Game) squareAttacked(r, c, byColor int) bool {
	// Пешки.
	pawnDir := 1 // белые атакуют снизу вверх: пешка на (r-1) бьёт (r)
	if byColor == 1 {
		pawnDir = -1
	}
	pawn := WhitePawn
	if byColor == 1 {
		pawn = BlackPawn
	}
	for _, dc := range []int{-1, 1} {
		if g.at(r-pawnDir, c+dc) == pawn {
			return true
		}
	}
	// Кони.
	knight := WhiteKnight + byColor*6
	for _, d := range knightDirs {
		if g.at(r+d[0], c+d[1]) == knight {
			return true
		}
	}
	// Король.
	king := WhiteKing + byColor*6
	for _, d := range queenDirs {
		if g.at(r+d[0], c+d[1]) == king {
			return true
		}
	}
	// Слон/ферзь по диагоналям.
	for _, d := range bishopDirs {
		nr, nc := r+d[0], c+d[1]
		for inBounds(nr, nc) {
			p := g.at(nr, nc)
			if p != Empty {
				if colorOf(p) == byColor && (kind(p) == 3 || kind(p) == 5) {
					return true
				}
				break
			}
			nr += d[0]
			nc += d[1]
		}
	}
	// Ладья/ферзь по прямым.
	for _, d := range rookDirs {
		nr, nc := r+d[0], c+d[1]
		for inBounds(nr, nc) {
			p := g.at(nr, nc)
			if p != Empty {
				if colorOf(p) == byColor && (kind(p) == 4 || kind(p) == 5) {
					return true
				}
				break
			}
			nr += d[0]
			nc += d[1]
		}
	}
	return false
}

// applyRaw — применяет ход без проверки легальности и без смены Turn/итогов.
// Обновляет доску, рокировки, взятие на проходе, часы пятидесяти ходов.
func (g *Game) applyRaw(seat int, mv Move) {
	piece := g.at(mv.From.R, mv.From.C)
	captured := g.at(mv.To.R, mv.To.C)
	isPawn := kind(piece) == 1
	isCapture := captured != Empty

	newEP := -1

	g.set(mv.From.R, mv.From.C, Empty)

	// Взятие на проходе: снимаем пешку соперника.
	if isPawn && mv.To.C != mv.From.C && captured == Empty {
		g.set(mv.From.R, mv.To.C, Empty)
		isCapture = true
	}

	placed := piece
	if isPawn && mv.Promo != 0 {
		placed = mv.Promo + seat*6
	}
	g.set(mv.To.R, mv.To.C, placed)

	// Рокировка: двигаем ладью.
	if kind(piece) == 6 && absInt(mv.To.C-mv.From.C) == 2 {
		home := mv.From.R
		if mv.To.C == 6 {
			g.set(home, 5, g.at(home, 7))
			g.set(home, 7, Empty)
		} else {
			g.set(home, 3, g.at(home, 0))
			g.set(home, 0, Empty)
		}
	}

	// Новая цель взятия на проходе — только при двойном ходе пешки.
	if isPawn && absInt(mv.To.R-mv.From.R) == 2 {
		newEP = g.idx((mv.From.R+mv.To.R)/2, mv.From.C)
	}
	g.EnPassant = newEP

	g.updateCastleRights(piece, mv)

	if isPawn || isCapture {
		g.HalfMove = 0
	} else {
		g.HalfMove++
	}
}

func (g *Game) updateCastleRights(piece int, mv Move) {
	switch piece {
	case WhiteKing:
		g.Castle[cWK] = false
		g.Castle[cWQ] = false
	case BlackKing:
		g.Castle[cBK] = false
		g.Castle[cBQ] = false
	case WhiteRook:
		if mv.From.R == 0 && mv.From.C == 0 {
			g.Castle[cWQ] = false
		}
		if mv.From.R == 0 && mv.From.C == 7 {
			g.Castle[cWK] = false
		}
	case BlackRook:
		if mv.From.R == 7 && mv.From.C == 0 {
			g.Castle[cBQ] = false
		}
		if mv.From.R == 7 && mv.From.C == 7 {
			g.Castle[cBK] = false
		}
	}
	// Взятие ладьи на её исходной клетке тоже гасит рокировку.
	loseRookRight := func(r, c, right int) {
		if mv.To.R == r && mv.To.C == c {
			g.Castle[right] = false
		}
	}
	loseRookRight(0, 0, cWQ)
	loseRookRight(0, 7, cWK)
	loseRookRight(7, 0, cBQ)
	loseRookRight(7, 7, cBK)
}

// Apply ставит ход seat с полной проверкой легальности.
func (g *Game) Apply(seat int, mv Move) error {
	if g == nil {
		return ErrIllegalMove
	}
	if g.IsOver() {
		return ErrGameOver
	}
	if seat != g.Turn {
		return ErrNotYourTurn
	}
	legal := g.LegalMoves()
	var chosen *Move
	for i := range legal {
		cand := legal[i]
		if cand.From == mv.From && cand.To == mv.To {
			if g.isPromotion(cand) {
				promo := mv.Promo
				if promo == 0 {
					promo = 5 // по умолчанию ферзь
				}
				if cand.Promo != promo {
					continue
				}
			}
			chosen = &cand
			break
		}
	}
	if chosen == nil {
		return ErrIllegalMove
	}
	g.applyRaw(seat, *chosen)
	g.LastFromR, g.LastFromC = chosen.From.R, chosen.From.C
	g.LastToR, g.LastToC = chosen.To.R, chosen.To.C
	g.Seq++
	g.Turn = 1 - g.Turn
	g.resolveEnd()
	return nil
}

func (g *Game) isPromotion(mv Move) bool {
	piece := g.at(mv.From.R, mv.From.C)
	if kind(piece) != 1 {
		return false
	}
	return mv.To.R == 0 || mv.To.R == Size-1
}

func (g *Game) resolveEnd() {
	if g.IsOver() {
		return
	}
	if g.HalfMove >= FiftyMovePlies {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonFiftyMove
		return
	}
	if g.insufficientMaterial() {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonInsufficient
		return
	}
	key := g.positionKey()
	g.PosCounts[key] = g.PosCounts[key] + 1
	if g.PosCounts[key] >= 3 {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonRepetition
		return
	}
	if len(g.LegalMoves()) > 0 {
		return
	}
	// Ходов нет: мат либо пат.
	if g.kingInCheck(g.Turn) {
		g.Winner = 1 - g.Turn
		return
	}
	g.Winner = WinnerDraw
	g.DrawReason = DrawReasonStalemate
}

func (g *Game) insufficientMaterial() bool {
	knights, bishops := 0, 0
	for _, p := range g.Board {
		switch kind(p) {
		case 1, 4, 5: // пешка, ладья, ферзь — материала достаточно
			return false
		case 2:
			knights++
		case 3:
			bishops++
		}
	}
	// K vs K, K+minor vs K.
	return knights+bishops <= 1
}

// positionKey — ключ для троекратного повторения: фигуры, очередь, рокировки, ep.
func (g *Game) positionKey() string {
	buf := make([]byte, 0, Size*Size+8)
	for _, p := range g.Board {
		buf = append(buf, byte('a'+p))
	}
	buf = append(buf, byte('0'+g.Turn))
	for _, b := range g.Castle {
		if b {
			buf = append(buf, '1')
		} else {
			buf = append(buf, '0')
		}
	}
	// Цель взятия на проходе важна для равенства позиций.
	buf = append(buf, byte('0'+g.EnPassant/16), byte('0'+g.EnPassant%16+1))
	return string(buf)
}

// Forfeit — сдача seat.
func (g *Game) Forfeit(seat int) {
	if g == nil || g.IsOver() {
		return
	}
	g.Winner = 1 - seat
	g.Seq++
}

// AgreeDraw — ничья по соглашению.
func (g *Game) AgreeDraw() {
	if g == nil || g.IsOver() {
		return
	}
	g.Winner = WinnerDraw
	g.DrawReason = DrawReasonAgreed
	g.Seq++
}

// InCheck — под шахом ли сторона, чей ход (для подсветки на клиенте).
func (g *Game) InCheck() bool {
	if g == nil || g.IsOver() {
		return false
	}
	return g.kingInCheck(g.Turn)
}

func Encode(g *Game) (string, error) {
	if g == nil {
		return "", fmt.Errorf("nil game")
	}
	b, err := json.Marshal(g)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func Decode(raw string) (*Game, error) {
	if raw == "" {
		return nil, errors.New("empty state")
	}
	var g Game
	if err := json.Unmarshal([]byte(raw), &g); err != nil {
		return nil, err
	}
	if len(g.Board) != Size*Size {
		return nil, errors.New("bad board size")
	}
	if g.PosCounts == nil {
		g.PosCounts = map[string]int{}
	}
	g.Mode = NormalizeMode(g.Mode)
	return &g, nil
}

func absInt(v int) int {
	if v < 0 {
		return -v
	}
	return v
}
