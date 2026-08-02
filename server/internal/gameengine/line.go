package gameengine

// lineEngine — классика / гомоку / multi: N×N, K в ряд.
type lineEngine struct {
	cfg Config
}

func (e *lineEngine) Config() Config { return e.cfg }

func (e *lineEngine) NewState() State {
	return State{
		Board:     emptyBoard(e.cfg.CellCount),
		Turn:      e.cfg.Marks[0],
		Status:    "active",
		NextBoard: -1,
	}
}

func (e *lineEngine) LegalCells(state State) []int {
	if state.Status != "active" {
		return nil
	}
	out := make([]int, 0, 16)
	for i, c := range state.Board {
		if c == "" {
			out = append(out, i)
		}
	}
	return out
}

func (e *lineEngine) ApplyMove(state State, cell int) (MoveResult, error) {
	if state.Status != "active" {
		return MoveResult{}, ErrGameOver
	}
	n := e.cfg.GridSize
	if cell < 0 || cell >= n*n || state.Board[cell] != "" {
		return MoveResult{}, ErrIllegalMove
	}
	mark := state.Turn
	board := cloneBoard(state.Board)
	board[cell] = mark

	line := findWinLine(board, mark, n, e.cfg.WinLength)
	next := State{
		Board:     board,
		Turn:      nextMark(e.cfg.Marks, mark),
		Status:    "active",
		NextBoard: -1,
	}
	res := MoveResult{State: next}
	if len(line) == e.cfg.WinLength {
		res.State.Status = "won"
		res.State.Winner = mark
		res.State.Turn = mark
		res.WinningCells = line
		return res, nil
	}
	if isBoardFull(board) {
		res.State.Status = "draw"
		res.State.Winner = ""
		return res, nil
	}
	return res, nil
}

func isBoardFull(board []string) bool {
	for _, c := range board {
		if c == "" {
			return false
		}
	}
	return true
}

func findWinLine(board []string, mark string, gridSize, winLen int) []int {
	if winLen > gridSize {
		return nil
	}
	dirs := [][2]int{{0, 1}, {1, 0}, {1, 1}, {1, -1}}
	for row := 0; row < gridSize; row++ {
		for col := 0; col < gridSize; col++ {
			for _, d := range dirs {
				line := make([]int, 0, winLen)
				ok := true
				for k := 0; k < winLen; k++ {
					r := row + d[0]*k
					c := col + d[1]*k
					if r < 0 || r >= gridSize || c < 0 || c >= gridSize {
						ok = false
						break
					}
					idx := r*gridSize + c
					if board[idx] != mark {
						ok = false
						break
					}
					line = append(line, idx)
				}
				if ok {
					return line
				}
			}
		}
	}
	return nil
}
