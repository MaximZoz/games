// Package connect4 — «Четыре в ряд»: классика 7×6 и широкое поле 9×7.
package connect4

import (
	"encoding/json"
	"errors"
	"fmt"
)

const (
	ModeClassic = "classic"
	ModeWide    = "wide"

	WinnerNone = -1
	WinnerDraw = -2

	BotID = "bot:connect4"
)

var (
	ErrNotYourTurn = errors.New("not your turn")
	ErrIllegalMove = errors.New("illegal move")
	ErrGameOver    = errors.New("game is over")
	ErrColumnFull  = errors.New("column is full")
)

// NormalizeMode приводит режим к classic или wide.
func NormalizeMode(mode string) string {
	if mode == ModeWide {
		return ModeWide
	}
	return ModeClassic
}

// SizeForMode — ширина и высота поля.
func SizeForMode(mode string) (cols, rows int) {
	if NormalizeMode(mode) == ModeWide {
		return 9, 7
	}
	return 7, 6
}

// Game — состояние партии.
type Game struct {
	Mode   string `json:"mode"`
	Cols   int    `json:"cols"`
	Rows   int    `json:"rows"`
	Board  []int  `json:"board"` // row-major, 0 empty, 1 P0, 2 P1
	Turn   int    `json:"turn"`
	Winner int    `json:"winner"`
	Seq    int    `json:"seq"`
	LastCol int   `json:"last_col"`
	LastRow int   `json:"last_row"`
}

// NewGame создаёт пустое поле, ход игрока 0.
func NewGame(mode string) *Game {
	mode = NormalizeMode(mode)
	cols, rows := SizeForMode(mode)
	return &Game{
		Mode:    mode,
		Cols:    cols,
		Rows:    rows,
		Board:   make([]int, cols*rows),
		Turn:    0,
		Winner:  WinnerNone,
		LastCol: -1,
		LastRow: -1,
	}
}

func (g *Game) idx(c, r int) int { return r*g.Cols + c }

func (g *Game) at(c, r int) int {
	if c < 0 || r < 0 || c >= g.Cols || r >= g.Rows {
		return -1
	}
	return g.Board[g.idx(c, r)]
}

func (g *Game) IsOver() bool { return g != nil && g.Winner != WinnerNone }

// LegalColumns — колонки, куда ещё можно бросить фишку.
func (g *Game) LegalColumns() []int {
	if g == nil || g.IsOver() {
		return nil
	}
	out := make([]int, 0, g.Cols)
	for c := 0; c < g.Cols; c++ {
		if g.at(c, g.Rows-1) == 0 {
			out = append(out, c)
		}
	}
	return out
}

// Drop ставит фишку игрока seat в колонку col.
func (g *Game) Drop(seat, col int) error {
	if g == nil {
		return ErrIllegalMove
	}
	if g.IsOver() {
		return ErrGameOver
	}
	if seat != g.Turn {
		return ErrNotYourTurn
	}
	if col < 0 || col >= g.Cols {
		return ErrIllegalMove
	}
	row := -1
	for r := 0; r < g.Rows; r++ {
		if g.at(col, r) == 0 {
			row = r
			break
		}
	}
	if row < 0 {
		return ErrColumnFull
	}
	g.Board[g.idx(col, row)] = seat + 1
	g.LastCol = col
	g.LastRow = row
	g.Seq++
	if g.hasWin(col, row, seat+1) {
		g.Winner = seat
		return nil
	}
	if len(g.LegalColumns()) == 0 {
		g.Winner = WinnerDraw
		return nil
	}
	g.Turn = 1 - g.Turn
	return nil
}

// Forfeit — сдача: побеждает соперник.
func (g *Game) Forfeit(seat int) {
	if g == nil || g.IsOver() {
		return
	}
	g.Winner = 1 - seat
	g.Seq++
}

// AgreeDraw — ничья по согласию.
func (g *Game) AgreeDraw() {
	if g == nil || g.IsOver() {
		return
	}
	g.Winner = WinnerDraw
	g.Seq++
}

func (g *Game) hasWin(c, r, piece int) bool {
	dirs := [][2]int{{1, 0}, {0, 1}, {1, 1}, {1, -1}}
	for _, d := range dirs {
		n := 1
		n += g.countDir(c, r, d[0], d[1], piece)
		n += g.countDir(c, r, -d[0], -d[1], piece)
		if n >= 4 {
			return true
		}
	}
	return false
}

func (g *Game) countDir(c, r, dc, dr, piece int) int {
	n := 0
	cc, rr := c+dc, r+dr
	for g.at(cc, rr) == piece {
		n++
		cc += dc
		rr += dr
	}
	return n
}

// Encode / Decode — JSON в Redis.
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
	if g.Cols <= 0 || g.Rows <= 0 {
		g.Mode = NormalizeMode(g.Mode)
		g.Cols, g.Rows = SizeForMode(g.Mode)
	}
	need := g.Cols * g.Rows
	if len(g.Board) != need {
		return nil, errors.New("bad board size")
	}
	return &g, nil
}
