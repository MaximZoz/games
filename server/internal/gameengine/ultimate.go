package gameengine

// ultimateEngine — ультимейт: 9 малых 3×3 → одно мета-поле.
// Индекс клетки 0..80: sub = cell/9, local = cell%9.
type ultimateEngine struct {
	cfg Config
}

func (e *ultimateEngine) Config() Config { return e.cfg }

func (e *ultimateEngine) NewState() State {
	return State{
		Board:     emptyBoard(81),
		Turn:      e.cfg.Marks[0],
		Status:    "active",
		NextBoard: -1,
		MetaBoard: emptyBoard(9),
	}
}

func (e *ultimateEngine) LegalCells(state State) []int {
	if state.Status != "active" {
		return nil
	}
	meta := state.MetaBoard
	if meta == nil {
		meta = emptyBoard(9)
	}
	forced := state.NextBoard
	if forced >= 0 && forced < 9 && meta[forced] == "" && !subBoardFull(state.Board, forced) {
		return openCellsInSub(state.Board, forced)
	}
	// Любой открытый малый борд.
	out := make([]int, 0, 32)
	for sub := 0; sub < 9; sub++ {
		if meta[sub] != "" {
			continue
		}
		out = append(out, openCellsInSub(state.Board, sub)...)
	}
	return out
}

func (e *ultimateEngine) ApplyMove(state State, cell int) (MoveResult, error) {
	if state.Status != "active" {
		return MoveResult{}, ErrGameOver
	}
	if cell < 0 || cell >= 81 || state.Board[cell] != "" {
		return MoveResult{}, ErrIllegalMove
	}
	legal := e.LegalCells(state)
	ok := false
	for _, c := range legal {
		if c == cell {
			ok = true
			break
		}
	}
	if !ok {
		return MoveResult{}, ErrIllegalMove
	}

	mark := state.Turn
	board := cloneBoard(state.Board)
	board[cell] = mark
	meta := cloneBoard(state.MetaBoard)
	if meta == nil || len(meta) != 9 {
		meta = emptyBoard(9)
	}

	sub := cell / 9
	local := cell % 9
	subBoard := extractSub(board, sub)
	if line := findWinLine(subBoard, mark, 3, 3); len(line) == 3 {
		meta[sub] = mark
	} else if isBoardFull(subBoard) {
		meta[sub] = "d"
	}

	nextForced := local
	if meta[nextForced] != "" || subBoardFull(board, nextForced) {
		nextForced = -1
	}

	next := State{
		Board:     board,
		Turn:      nextMark(e.cfg.Marks, mark),
		Status:    "active",
		NextBoard: nextForced,
		MetaBoard: meta,
	}
	res := MoveResult{State: next}

	if metaLine := findWinLine(metaMarksOnly(meta), mark, 3, 3); len(metaLine) == 3 {
		res.State.Status = "won"
		res.State.Winner = mark
		res.State.Turn = mark
		res.MetaWinCells = metaLine
		// Подсветим клетки выигранного малого борда, если есть.
		res.WinningCells = cellsOfSub(sub)
		return res, nil
	}
	if metaFull(meta) {
		res.State.Status = "draw"
		res.State.Winner = ""
		return res, nil
	}
	return res, nil
}

func extractSub(board []string, sub int) []string {
	out := make([]string, 9)
	base := sub * 9
	for i := 0; i < 9; i++ {
		out[i] = board[base+i]
	}
	return out
}

func openCellsInSub(board []string, sub int) []int {
	out := make([]int, 0, 9)
	base := sub * 9
	for i := 0; i < 9; i++ {
		idx := base + i
		if board[idx] == "" {
			out = append(out, idx)
		}
	}
	return out
}

func subBoardFull(board []string, sub int) bool {
	base := sub * 9
	for i := 0; i < 9; i++ {
		if board[base+i] == "" {
			return false
		}
	}
	return true
}

func cellsOfSub(sub int) []int {
	out := make([]int, 9)
	base := sub * 9
	for i := 0; i < 9; i++ {
		out[i] = base + i
	}
	return out
}

func metaMarksOnly(meta []string) []string {
	out := make([]string, 9)
	for i, m := range meta {
		if m == "x" || m == "o" {
			out[i] = m
		}
	}
	return out
}

func metaFull(meta []string) bool {
	for _, m := range meta {
		if m == "" {
			return false
		}
	}
	return true
}
