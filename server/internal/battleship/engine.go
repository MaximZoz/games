// Package battleship реализует правила «Морского боя» (русская расстановка).
package battleship

import (
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"sort"
)

const (
	BoardSize = 10
	CellCount = BoardSize * BoardSize
)

// Fleet — классический русский состав: 1×4, 2×3, 3×2, 4×1.
var Fleet = []int{4, 3, 3, 2, 2, 2, 1, 1, 1, 1}

var (
	ErrInvalidShips = errors.New("invalid ships")
	ErrInvalidCell  = errors.New("invalid cell")
)

// Ships — список кораблей; каждый корабль — упорядоченный список индексов клеток 0..99.
type Ships [][]int

// ValidateShips проверяет состав флота, прямолинейность и правило «не касаться»
// (включая диагонали).
func ValidateShips(ships Ships) error {
	if len(ships) != len(Fleet) {
		return fmt.Errorf("%w: expected %d ships, got %d", ErrInvalidShips, len(Fleet), len(ships))
	}
	lengths := make([]int, 0, len(ships))
	occupied := make(map[int]int) // cell → ship index
	for i, ship := range ships {
		if len(ship) == 0 {
			return fmt.Errorf("%w: empty ship", ErrInvalidShips)
		}
		seen := make(map[int]struct{}, len(ship))
		for _, c := range ship {
			if c < 0 || c >= CellCount {
				return fmt.Errorf("%w: cell out of range", ErrInvalidShips)
			}
			if _, ok := seen[c]; ok {
				return fmt.Errorf("%w: duplicate cell in ship", ErrInvalidShips)
			}
			seen[c] = struct{}{}
			if prev, ok := occupied[c]; ok {
				return fmt.Errorf("%w: ships %d and %d overlap", ErrInvalidShips, prev, i)
			}
			occupied[c] = i
		}
		if !isStraightLine(ship) {
			return fmt.Errorf("%w: ship must be a straight line", ErrInvalidShips)
		}
		lengths = append(lengths, len(ship))
	}
	want := append([]int(nil), Fleet...)
	sort.Ints(want)
	got := append([]int(nil), lengths...)
	sort.Ints(got)
	for i := range want {
		if want[i] != got[i] {
			return fmt.Errorf("%w: fleet mismatch", ErrInvalidShips)
		}
	}
	// Не касаться даже по диагонали.
	for a := 0; a < len(ships); a++ {
		for b := a + 1; b < len(ships); b++ {
			for _, ca := range ships[a] {
				ra, cola := ca/BoardSize, ca%BoardSize
				for _, cb := range ships[b] {
					rb, colb := cb/BoardSize, cb%BoardSize
					dr := ra - rb
					if dr < 0 {
						dr = -dr
					}
					dc := cola - colb
					if dc < 0 {
						dc = -dc
					}
					if dr <= 1 && dc <= 1 {
						return fmt.Errorf("%w: ships touch", ErrInvalidShips)
					}
				}
			}
		}
	}
	return nil
}

func isStraightLine(ship []int) bool {
	if len(ship) == 1 {
		return true
	}
	cells := append([]int(nil), ship...)
	sort.Ints(cells)
	sameRow := true
	sameCol := true
	row0 := cells[0] / BoardSize
	col0 := cells[0] % BoardSize
	for _, c := range cells[1:] {
		if c/BoardSize != row0 {
			sameRow = false
		}
		if c%BoardSize != col0 {
			sameCol = false
		}
	}
	if !sameRow && !sameCol {
		return false
	}
	if sameRow {
		for i := 1; i < len(cells); i++ {
			if cells[i] != cells[i-1]+1 {
				return false
			}
		}
		return true
	}
	for i := 1; i < len(cells); i++ {
		if cells[i] != cells[i-1]+BoardSize {
			return false
		}
	}
	return true
}

func ParseShipsJSON(raw string) (Ships, error) {
	if raw == "" || raw == "null" {
		return nil, nil
	}
	var ships Ships
	if err := json.Unmarshal([]byte(raw), &ships); err != nil {
		return nil, err
	}
	return ships, nil
}

func ShipsToJSON(ships Ships) string {
	if ships == nil {
		return "[]"
	}
	b, err := json.Marshal(ships)
	if err != nil {
		return "[]"
	}
	return string(b)
}

func ParseShotsJSON(raw string) ([]int, error) {
	if raw == "" || raw == "null" {
		return nil, nil
	}
	var shots []int
	if err := json.Unmarshal([]byte(raw), &shots); err != nil {
		return nil, err
	}
	return shots, nil
}

func ShotsToJSON(shots []int) string {
	if shots == nil {
		shots = []int{}
	}
	b, err := json.Marshal(shots)
	if err != nil {
		return "[]"
	}
	return string(b)
}

// ShotsToHitSet — множество клеток, по которым уже стреляли.
func ShotsToHitSet(shots []int) map[int]struct{} {
	out := make(map[int]struct{}, len(shots))
	for _, c := range shots {
		out[c] = struct{}{}
	}
	return out
}

// IsHit — попал ли выстрел в какой-либо корабль.
func IsHit(ships Ships, cell int) bool {
	for _, ship := range ships {
		for _, c := range ship {
			if c == cell {
				return true
			}
		}
	}
	return false
}

// AllSunk — все клетки всех кораблей есть среди выстрелов.
func AllSunk(ships Ships, shots []int) bool {
	if len(ships) == 0 {
		return false
	}
	hit := ShotsToHitSet(shots)
	for _, ship := range ships {
		for _, c := range ship {
			if _, ok := hit[c]; !ok {
				return false
			}
		}
	}
	return true
}

// CollectSunkCells — клетки полностью потопленных кораблей (для подсветки клиенту).
func CollectSunkCells(ships Ships, shots []int) []int {
	hit := ShotsToHitSet(shots)
	var out []int
	for _, ship := range ships {
		sunk := true
		for _, c := range ship {
			if _, ok := hit[c]; !ok {
				sunk = false
				break
			}
		}
		if sunk {
			out = append(out, ship...)
		}
	}
	sort.Ints(out)
	return out
}

// CollectHitCells — клетки выстрелов, попавших в корабли (в т.ч. ещё не потопленные).
func CollectHitCells(ships Ships, shots []int) []int {
	var out []int
	for _, c := range shots {
		if IsHit(ships, c) {
			out = append(out, c)
		}
	}
	sort.Ints(out)
	return out
}

// CollectSunkShips — полностью потопленные корабли (группы клеток).
func CollectSunkShips(ships Ships, shots []int) Ships {
	hit := ShotsToHitSet(shots)
	var out Ships
	for _, ship := range ships {
		sunk := true
		for _, c := range ship {
			if _, ok := hit[c]; !ok {
				sunk = false
				break
			}
		}
		if sunk {
			cp := make([]int, len(ship))
			copy(cp, ship)
			out = append(out, cp)
		}
	}
	return out
}

// RandomShips расставляет флот случайно с соблюдением ValidateShips.
func RandomShips(rng *rand.Rand) Ships {
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	for attempt := 0; attempt < 500; attempt++ {
		ships := make(Ships, 0, len(Fleet))
		occupied := make(map[int]struct{})
		blocked := make(map[int]struct{})
		ok := true
		for _, length := range Fleet {
			placed := false
			for try := 0; try < 200; try++ {
				horizontal := rng.Intn(2) == 0
				var start int
				if horizontal {
					row := rng.Intn(BoardSize)
					col := rng.Intn(BoardSize - length + 1)
					start = row*BoardSize + col
				} else {
					row := rng.Intn(BoardSize - length + 1)
					col := rng.Intn(BoardSize)
					start = row*BoardSize + col
				}
				cells := make([]int, length)
				conflict := false
				for i := 0; i < length; i++ {
					c := start
					if horizontal {
						c = start + i
					} else {
						c = start + i*BoardSize
					}
					if _, taken := occupied[c]; taken {
						conflict = true
						break
					}
					if _, b := blocked[c]; b {
						conflict = true
						break
					}
					cells[i] = c
				}
				if conflict {
					continue
				}
				for _, c := range cells {
					occupied[c] = struct{}{}
					r, col := c/BoardSize, c%BoardSize
					for dr := -1; dr <= 1; dr++ {
						for dc := -1; dc <= 1; dc++ {
							rr, cc := r+dr, col+dc
							if rr < 0 || rr >= BoardSize || cc < 0 || cc >= BoardSize {
								continue
							}
							blocked[rr*BoardSize+cc] = struct{}{}
						}
					}
				}
				ships = append(ships, cells)
				placed = true
				break
			}
			if !placed {
				ok = false
				break
			}
		}
		if ok && ValidateShips(ships) == nil {
			return ships
		}
	}
	// Детерминированный fallback: горизонтальные ряды с зазором.
	return fallbackShips()
}

// DefaultShips — фиксированная валидная расстановка (таймаут setup без своей).
func DefaultShips() Ships {
	return fallbackShips()
}

func fallbackShips() Ships {
	// Гарантированно валидная расстановка.
	return Ships{
		{0, 1, 2, 3},
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
}

// BotNeighborCandidates — клетки рядом с попаданиями (ортогонально), ещё не обстрелянные.
func BotNeighborCandidates(ships Ships, shots []int) []int {
	hitSet := ShotsToHitSet(shots)
	seen := make(map[int]struct{})
	var out []int
	for _, cell := range shots {
		if !IsHit(ships, cell) {
			continue
		}
		r, c := cell/BoardSize, cell%BoardSize
		for _, d := range [][2]int{{-1, 0}, {1, 0}, {0, -1}, {0, 1}} {
			rr, cc := r+d[0], c+d[1]
			if rr < 0 || rr >= BoardSize || cc < 0 || cc >= BoardSize {
				continue
			}
			n := rr*BoardSize + cc
			if _, shot := hitSet[n]; shot {
				continue
			}
			if _, ok := seen[n]; ok {
				continue
			}
			seen[n] = struct{}{}
			out = append(out, n)
		}
	}
	sort.Ints(out)
	return out
}

// BotPickShot — добивание по линии, затем соседи, затем шахматный поиск.
func BotPickShot(ships Ships, shots []int, rng *rand.Rand) (int, error) {
	if rng == nil {
		rng = rand.New(rand.NewSource(1))
	}
	hitSet := ShotsToHitSet(shots)
	if line := botLineCandidates(ships, shots); len(line) > 0 {
		return line[rng.Intn(len(line))], nil
	}
	if cands := BotNeighborCandidates(ships, shots); len(cands) > 0 {
		return cands[rng.Intn(len(cands))], nil
	}
	return botHuntCell(ships, shots, hitSet, rng)
}

func botHuntCell(ships Ships, shots []int, hitSet map[int]struct{}, rng *rand.Rand) (int, error) {
	remaining := botRemainingLens(ships, shots)
	scores := make([]int, CellCount)
	bestScore := 0
	for _, length := range remaining {
		addShipPlacements(scores, hitSet, length)
	}
	var best, free []int
	for i := 0; i < CellCount; i++ {
		if _, ok := hitSet[i]; ok {
			continue
		}
		free = append(free, i)
		if scores[i] > bestScore {
			bestScore = scores[i]
			best = []int{i}
		} else if scores[i] == bestScore && bestScore > 0 {
			best = append(best, i)
		}
	}
	if len(best) > 0 {
		if botMinLen(remaining) >= 2 {
			best = botPreferEvenParity(best)
		}
		return best[rng.Intn(len(best))], nil
	}
	if len(free) == 0 {
		return 0, ErrInvalidCell
	}
	return free[rng.Intn(len(free))], nil
}

func botMinLen(lens []int) int {
	minLen := 0
	for _, n := range lens {
		if n <= 0 {
			continue
		}
		if minLen == 0 || n < minLen {
			minLen = n
		}
	}
	if minLen == 0 {
		return 1
	}
	return minLen
}

// botPreferEvenParity — при равной плотности клетки шахматной раскраски
// покрывают все корабли длиной от двух.
func botPreferEvenParity(cells []int) []int {
	even := make([]int, 0, len(cells))
	for _, cell := range cells {
		r, c := cell/BoardSize, cell%BoardSize
		if (r+c)%2 == 0 {
			even = append(even, cell)
		}
	}
	if len(even) == 0 {
		return cells
	}
	return even
}

func botRemainingLens(ships Ships, shots []int) []int {
	hitSet := ShotsToHitSet(shots)
	var out []int
	for _, ship := range ships {
		sunk := true
		for _, c := range ship {
			if _, ok := hitSet[c]; !ok {
				sunk = false
				break
			}
		}
		if !sunk {
			out = append(out, len(ship))
		}
	}
	if len(out) == 0 {
		return []int{1}
	}
	return out
}

func addShipPlacements(scores []int, blocked map[int]struct{}, length int) {
	if length <= 0 {
		return
	}
	place := func(cells []int) {
		for _, cell := range cells {
			if _, ok := blocked[cell]; ok {
				return
			}
		}
		for _, cell := range cells {
			scores[cell]++
		}
	}
	for r := 0; r < BoardSize; r++ {
		for c := 0; c <= BoardSize-length; c++ {
			cells := make([]int, length)
			for k := 0; k < length; k++ {
				cells[k] = r*BoardSize + c + k
			}
			place(cells)
		}
	}
	for c := 0; c < BoardSize; c++ {
		for r := 0; r <= BoardSize-length; r++ {
			cells := make([]int, length)
			for k := 0; k < length; k++ {
				cells[k] = (r+k)*BoardSize + c
			}
			place(cells)
		}
	}
}

func botLineCandidates(ships Ships, shots []int) []int {
	hits := botUnsunkHits(ships, shots)
	if len(hits) < 2 {
		return nil
	}
	hitSet := ShotsToHitSet(shots)
	seen := map[int]struct{}{}
	var out []int
	add := func(cell int) {
		if cell < 0 || cell >= CellCount {
			return
		}
		if _, ok := hitSet[cell]; ok {
			return
		}
		if _, ok := seen[cell]; ok {
			return
		}
		seen[cell] = struct{}{}
		out = append(out, cell)
	}
	for i := 0; i < len(hits); i++ {
		for j := i + 1; j < len(hits); j++ {
			a, b := hits[i], hits[j]
			ar, ac := a/BoardSize, a%BoardSize
			br, bc := b/BoardSize, b%BoardSize
			if ar == br {
				lo, hi := ac, bc
				if lo > hi {
					lo, hi = hi, lo
				}
				if hi-lo == 1 || cellsFilled(ar, lo, hi, true, hitSet) {
					add(ar*BoardSize + lo - 1)
					add(ar*BoardSize + hi + 1)
				}
			} else if ac == bc {
				lo, hi := ar, br
				if lo > hi {
					lo, hi = hi, lo
				}
				if hi-lo == 1 || cellsFilled(ac, lo, hi, false, hitSet) {
					add((lo-1)*BoardSize + ac)
					add((hi+1)*BoardSize + ac)
				}
			}
		}
	}
	sort.Ints(out)
	return out
}

func cellsFilled(fixed, lo, hi int, horizontal bool, hitSet map[int]struct{}) bool {
	for x := lo + 1; x < hi; x++ {
		cell := fixed*BoardSize + x
		if !horizontal {
			cell = x*BoardSize + fixed
		}
		if _, ok := hitSet[cell]; !ok {
			return false
		}
	}
	return hi > lo
}

func botUnsunkHits(ships Ships, shots []int) []int {
	hitSet := ShotsToHitSet(shots)
	var out []int
	for _, ship := range ships {
		sunk := true
		for _, c := range ship {
			if _, ok := hitSet[c]; !ok {
				sunk = false
				break
			}
		}
		if sunk {
			continue
		}
		for _, c := range ship {
			if _, ok := hitSet[c]; ok {
				out = append(out, c)
			}
		}
	}
	sort.Ints(out)
	return out
}
