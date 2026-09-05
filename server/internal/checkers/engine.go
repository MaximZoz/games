// Package checkers — русские шашки и поддавки на доске 8×8.
package checkers

import (
	"encoding/json"
	"errors"
	"fmt"
)

const (
	ModeRussian  = "russian"
	ModeGiveaway = "giveaway"

	Empty     int = 0
	WhiteMan  int = 1
	BlackMan  int = 2
	WhiteKing int = 3
	BlackKing int = 4

	WinnerNone = -1
	WinnerDraw = -2

	BotID = "bot:checkers"
	Size  = 8
)

var (
	ErrNotYourTurn = errors.New("not your turn")
	ErrIllegalMove = errors.New("illegal move")
	ErrGameOver    = errors.New("game is over")
)

// NormalizeMode — russian или giveaway.
func NormalizeMode(mode string) string {
	if mode == ModeGiveaway {
		return ModeGiveaway
	}
	return ModeRussian
}

// Square — клетка доски.
type Square struct {
	R int `json:"r"`
	C int `json:"c"`
}

// Move — тихий ход или взятие (через jumped).
type Move struct {
	From   Square   `json:"from"`
	To     Square   `json:"to"`
	Jumped []Square `json:"jumped,omitempty"`
}

// Game — состояние партии.
type Game struct {
	Mode             string  `json:"mode"`
	Board            []int   `json:"board"` // 64 клетки, row-major
	Turn             int     `json:"turn"`  // 0 белые, 1 чёрные
	Winner           int     `json:"winner"`
	Seq              int     `json:"seq"`
	ContR            int     `json:"cont_r"`
	ContC            int     `json:"cont_c"`
	MustContinue     bool    `json:"must_continue"`
	LastFromR        int     `json:"last_from_r"`
	LastFromC        int     `json:"last_from_c"`
	LastToR          int     `json:"last_to_r"`
	LastToC          int     `json:"last_to_c"`
}

// NewGame — стартовая расстановка.
func NewGame(mode string) *Game {
	g := &Game{
		Mode:    NormalizeMode(mode),
		Board:   make([]int, Size*Size),
		Turn:    0,
		Winner:  WinnerNone,
		ContR:   -1,
		ContC:   -1,
		LastFromR: -1,
		LastFromC: -1,
		LastToR:   -1,
		LastToC:   -1,
	}
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			if (r+c)%2 == 0 {
				continue
			}
			if r <= 2 {
				g.set(r, c, WhiteMan)
			} else if r >= 5 {
				g.set(r, c, BlackMan)
			}
		}
	}
	return g
}

func (g *Game) idx(r, c int) int { return r*Size + c }

func (g *Game) at(r, c int) int {
	if r < 0 || c < 0 || r >= Size || c >= Size {
		return -1
	}
	return g.Board[g.idx(r, c)]
}

func (g *Game) set(r, c, v int) { g.Board[g.idx(r, c)] = v }

func (g *Game) IsOver() bool { return g != nil && g.Winner != WinnerNone }

func owner(piece int) int {
	if piece == WhiteMan || piece == WhiteKing {
		return 0
	}
	if piece == BlackMan || piece == BlackKing {
		return 1
	}
	return -1
}

func isKing(piece int) bool { return piece == WhiteKing || piece == BlackKing }

func dark(r, c int) bool { return (r+c)%2 == 1 }

// LegalMoves — все легальные ходы текущего игрока (с учётом обязательного боя).
func (g *Game) LegalMoves() []Move {
	if g == nil || g.IsOver() {
		return nil
	}
	if g.MustContinue {
		return g.capturesFrom(g.ContR, g.ContC)
	}
	captures := g.allCaptures(g.Turn)
	if len(captures) > 0 {
		return captures
	}
	return g.quietMoves(g.Turn)
}

func (g *Game) allCaptures(seat int) []Move {
	var out []Move
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			if owner(g.at(r, c)) != seat {
				continue
			}
			out = append(out, g.capturesFrom(r, c)...)
		}
	}
	return out
}

func (g *Game) capturesFrom(r, c int) []Move {
	piece := g.at(r, c)
	if owner(piece) < 0 {
		return nil
	}
	if isKing(piece) {
		return g.kingCaptures(r, c)
	}
	return g.manCaptures(r, c)
}

func (g *Game) manCaptures(r, c int) []Move {
	piece := g.at(r, c)
	seat := owner(piece)
	var out []Move
	for _, d := range [][2]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}} {
		jr, jc := r+d[0], c+d[1]
		tr, tc := r+2*d[0], c+2*d[1]
		mid := g.at(jr, jc)
		if owner(mid) < 0 || owner(mid) == seat {
			continue
		}
		if g.at(tr, tc) != Empty {
			continue
		}
		if !dark(tr, tc) {
			continue
		}
		out = append(out, Move{
			From:   Square{R: r, C: c},
			To:     Square{R: tr, C: tc},
			Jumped: []Square{{R: jr, C: jc}},
		})
	}
	return out
}

func (g *Game) kingCaptures(r, c int) []Move {
	piece := g.at(r, c)
	seat := owner(piece)
	var out []Move
	for _, d := range [][2]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}} {
		jr, jc := r+d[0], c+d[1]
		for g.at(jr, jc) == Empty {
			jr += d[0]
			jc += d[1]
		}
		mid := g.at(jr, jc)
		if owner(mid) < 0 || owner(mid) == seat {
			continue
		}
		lr, lc := jr+d[0], jc+d[1]
		for g.at(lr, lc) == Empty && dark(lr, lc) {
			out = append(out, Move{
				From:   Square{R: r, C: c},
				To:     Square{R: lr, C: lc},
				Jumped: []Square{{R: jr, C: jc}},
			})
			lr += d[0]
			lc += d[1]
		}
	}
	return out
}

func (g *Game) quietMoves(seat int) []Move {
	var out []Move
	for r := 0; r < Size; r++ {
		for c := 0; c < Size; c++ {
			piece := g.at(r, c)
			if owner(piece) != seat {
				continue
			}
			if isKing(piece) {
				for _, d := range [][2]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}} {
					nr, nc := r+d[0], c+d[1]
					for g.at(nr, nc) == Empty && dark(nr, nc) {
						out = append(out, Move{
							From: Square{R: r, C: c},
							To:   Square{R: nr, C: nc},
						})
						nr += d[0]
						nc += d[1]
					}
				}
				continue
			}
			fwd := 1
			if seat == 1 {
				fwd = -1
			}
			for _, dc := range []int{-1, 1} {
				nr, nc := r+fwd, c+dc
				if g.at(nr, nc) == Empty && dark(nr, nc) {
					out = append(out, Move{
						From: Square{R: r, C: c},
						To:   Square{R: nr, C: nc},
					})
				}
			}
		}
	}
	return out
}

func sameMove(a, b Move) bool {
	if a.From != b.From || a.To != b.To {
		return false
	}
	if len(a.Jumped) != len(b.Jumped) {
		return false
	}
	for i := range a.Jumped {
		if a.Jumped[i] != b.Jumped[i] {
			return false
		}
	}
	return true
}

// Apply ставит ход seat.
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
	ok := false
	var chosen Move
	for _, cand := range legal {
		if sameMove(cand, mv) {
			ok = true
			chosen = cand
			break
		}
	}
	if !ok {
		return ErrIllegalMove
	}
	piece := g.at(chosen.From.R, chosen.From.C)
	g.set(chosen.From.R, chosen.From.C, Empty)
	for _, j := range chosen.Jumped {
		g.set(j.R, j.C, Empty)
	}
	promoted := false
	if !isKing(piece) {
		if (seat == 0 && chosen.To.R == Size-1) || (seat == 1 && chosen.To.R == 0) {
			if seat == 0 {
				piece = WhiteKing
			} else {
				piece = BlackKing
			}
			promoted = true
		}
	}
	g.set(chosen.To.R, chosen.To.C, piece)
	g.LastFromR, g.LastFromC = chosen.From.R, chosen.From.C
	g.LastToR, g.LastToC = chosen.To.R, chosen.To.C
	g.Seq++

	if len(chosen.Jumped) > 0 {
		more := g.capturesFrom(chosen.To.R, chosen.To.C)
		// После превращения в дамку бой продолжается дамкой.
		_ = promoted
		if len(more) > 0 {
			g.MustContinue = true
			g.ContR, g.ContC = chosen.To.R, chosen.To.C
			return nil
		}
	}
	g.MustContinue = false
	g.ContR, g.ContC = -1, -1
	g.Turn = 1 - g.Turn
	g.resolveEnd()
	return nil
}

func (g *Game) resolveEnd() {
	if len(g.LegalMoves()) > 0 {
		return
	}
	// Нет ходов у того, чья очередь.
	loser := g.Turn
	if g.Mode == ModeGiveaway {
		g.Winner = loser
		return
	}
	g.Winner = 1 - loser
}

// Forfeit — сдача.
func (g *Game) Forfeit(seat int) {
	if g == nil || g.IsOver() {
		return
	}
	if g.Mode == ModeGiveaway {
		g.Winner = seat
	} else {
		g.Winner = 1 - seat
	}
	g.Seq++
}

// AgreeDraw — ничья.
func (g *Game) AgreeDraw() {
	if g == nil || g.IsOver() {
		return
	}
	g.Winner = WinnerDraw
	g.Seq++
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
	g.Mode = NormalizeMode(g.Mode)
	return &g, nil
}
