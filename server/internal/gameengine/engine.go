// Package gameengine — инжектируемые правила настольных игр (крестики и варианты).
// API/Redis остаются тонким слоем; вся валидация ходов и победы — здесь.
package gameengine

import (
	"errors"
	"fmt"
)

type Variant string

const (
	VariantClassic  Variant = "classic"  // 3×3, три в ряд, 2 игрока
	VariantGomoku   Variant = "gomoku"   // 15×15, пять в ряд, 2 игрока
	VariantUltimate Variant = "ultimate" // 9 малых 3×3, 2 игрока
	VariantMulti3   Variant = "multi3"   // 8×8, 4 в ряд, 3 игрока
	VariantMulti4   Variant = "multi4"   // 10×10, 4 в ряд, 4 игрока
)

var (
	ErrUnknownVariant = errors.New("unknown variant")
	ErrIllegalMove    = errors.New("illegal move")
	ErrNotYourTurn    = errors.New("not your turn")
	ErrGameOver       = errors.New("game over")
)

// Config — статические параметры режима (для лобби / matchmake / UI).
type Config struct {
	Variant    Variant
	GridSize   int
	WinLength  int
	MaxPlayers int
	Marks      []string // порядок хода: x, o, … 
	CellCount  int      // len(board)
}

func ConfigFor(v Variant) (Config, error) {
	switch v {
	case VariantClassic, "":
		return Config{
			Variant: VariantClassic, GridSize: 3, WinLength: 3,
			MaxPlayers: 2, Marks: []string{"x", "o"}, CellCount: 9,
		}, nil
	case VariantGomoku:
		return Config{
			Variant: VariantGomoku, GridSize: 15, WinLength: 5,
			MaxPlayers: 2, Marks: []string{"x", "o"}, CellCount: 225,
		}, nil
	case VariantUltimate:
		return Config{
			Variant: VariantUltimate, GridSize: 9, WinLength: 3,
			MaxPlayers: 2, Marks: []string{"x", "o"}, CellCount: 81,
		}, nil
	case VariantMulti3:
		return Config{
			Variant: VariantMulti3, GridSize: 8, WinLength: 4,
			MaxPlayers: 3, Marks: []string{"x", "o", "t"}, CellCount: 64,
		}, nil
	case VariantMulti4:
		return Config{
			Variant: VariantMulti4, GridSize: 10, WinLength: 4,
			MaxPlayers: 4, Marks: []string{"x", "o", "t", "s"}, CellCount: 100,
		}, nil
	default:
		return Config{}, fmt.Errorf("%w: %s", ErrUnknownVariant, v)
	}
}

func ParseVariant(s string) Variant {
	switch Variant(s) {
	case VariantGomoku, VariantUltimate, VariantMulti3, VariantMulti4:
		return Variant(s)
	default:
		return VariantClassic
	}
}

// State — полное состояние партии для движка.
type State struct {
	Board     []string
	Turn      string
	Status    string // "active" | "won" | "draw"
	Winner    string // mark
	// Ultimate: следующий малый борд 0..8, -1 = любой.
	NextBoard int
	// Ultimate: победители малых бордов "", "x", "o", "d"(ничья).
	MetaBoard []string
}

// MoveResult — результат хода.
type MoveResult struct {
	State         State
	WinningCells  []int
	MetaWinCells  []int // для ultimate — клетки мета-борда
}

// Engine — инжектируемые правила.
type Engine interface {
	Config() Config
	NewState() State
	ApplyMove(state State, cell int) (MoveResult, error)
	LegalCells(state State) []int
}

// New возвращает движок для варианта.
func New(v Variant) (Engine, error) {
	cfg, err := ConfigFor(v)
	if err != nil {
		return nil, err
	}
	switch cfg.Variant {
	case VariantUltimate:
		return &ultimateEngine{cfg: cfg}, nil
	default:
		return &lineEngine{cfg: cfg}, nil
	}
}

func emptyBoard(n int) []string {
	b := make([]string, n)
	return b
}

func nextMark(marks []string, current string) string {
	for i, m := range marks {
		if m == current {
			return marks[(i+1)%len(marks)]
		}
	}
	if len(marks) == 0 {
		return current
	}
	return marks[0]
}

func cloneBoard(b []string) []string {
	out := make([]string, len(b))
	copy(out, b)
	return out
}
