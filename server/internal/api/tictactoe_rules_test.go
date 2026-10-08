package api

import (
	"reflect"
	"testing"

	"multigames/server/internal/gameengine"
)

func board3(cells ...string) []string {
	b := make([]string, 9)
	copy(b, cells)
	return b
}

func TestWinLength(t *testing.T) {
	cases := []struct {
		grid int
		want int
	}{
		{3, 3}, {4, 4}, {5, 5}, {6, 5}, {7, 5}, {8, 5}, {2, 2}, {1, 1},
	}
	for _, c := range cases {
		if got := winLength(c.grid); got != c.want {
			t.Fatalf("winLength(%d)=%d want %d", c.grid, got, c.want)
		}
	}
}

func TestCenterCellIndices(t *testing.T) {
	cases := map[int][]int{
		3: {4},
		4: {5, 6, 9, 10},
		5: {12},
		6: {14, 15, 20, 21},
		7: {24},
		8: {27, 28, 35, 36},
		9: nil,
		0: nil,
	}
	for grid, want := range cases {
		got := centerCellIndices(grid)
		if !reflect.DeepEqual(got, want) {
			t.Fatalf("centerCellIndices(%d)=%v want %v", grid, got, want)
		}
	}
}

func TestCheckWin3x3RowsColsDiags(t *testing.T) {
	// Горизонталь
	if !checkWin(board3("x", "x", "x", "", "", "", "", "", ""), "x", 3) {
		t.Fatal("row win")
	}
	// Вертикаль
	if !checkWin(board3("o", "", "", "o", "", "", "o", "", ""), "o", 3) {
		t.Fatal("col win")
	}
	// Диагональ \
	if !checkWin(board3("x", "", "", "", "x", "", "", "", "x"), "x", 3) {
		t.Fatal("diag \\ win")
	}
	// Диагональ /
	if !checkWin(board3("", "", "o", "", "o", "", "o", "", ""), "o", 3) {
		t.Fatal("diag / win")
	}
	if checkWin(board3("x", "o", "x", "o", "x", "o", "o", "x", "o"), "x", 3) {
		t.Fatal("no win expected")
	}
}

func TestCheckWinLineReturnsIndices(t *testing.T) {
	line := checkWinLine(board3("x", "x", "x", "", "", "", "", "", ""), "x", 3)
	if !reflect.DeepEqual(line, []int{0, 1, 2}) {
		t.Fatalf("line=%v", line)
	}
	if checkWinLine(board3(), "x", 3) != nil {
		t.Fatal("empty board")
	}
}

func TestCheckWin4x4NeedsFour(t *testing.T) {
	b := make([]string, 16)
	b[0], b[1], b[2] = "x", "x", "x"
	if checkWin(b, "x", 4) {
		t.Fatal("3 in a row on 4x4 is not enough")
	}
	b[3] = "x"
	if !checkWin(b, "x", 4) {
		t.Fatal("4 in a row should win")
	}
}

func TestCheckWin6x6NeedsFive(t *testing.T) {
	b := make([]string, 36)
	for i := 0; i < 4; i++ {
		b[i] = "x"
	}
	if checkWin(b, "x", 6) {
		t.Fatal("4 on 6x6 is not enough (need 5)")
	}
	b[4] = "x"
	if !checkWin(b, "x", 6) {
		t.Fatal("5 on 6x6 should win")
	}
}

func TestIsDraw(t *testing.T) {
	full := board3("x", "o", "x", "x", "o", "o", "o", "x", "x")
	if !isDraw(full, 3) {
		t.Fatal("full board is draw")
	}
	partial := board3("x", "o", "", "", "", "", "", "", "")
	if isDraw(partial, 3) {
		t.Fatal("open board is not draw")
	}
	if isDraw([]string{"x"}, 3) {
		t.Fatal("short board is not draw")
	}
}

func TestCellCompletesWin(t *testing.T) {
	b := board3("x", "x", "", "", "", "", "", "", "")
	if !cellCompletesWin(b, 2, "x", 3) {
		t.Fatal("cell 2 should complete win")
	}
	if cellCompletesWin(b, 3, "x", 3) {
		t.Fatal("cell 3 should not win")
	}
}

func TestValidMovesFirstMoveRestriction(t *testing.T) {
	empty := make([]string, 9)
	all := validMoves(empty, 3, "x", false)
	if len(all) != 9 {
		t.Fatalf("without restriction want 9 moves, got %d", len(all))
	}
	restricted := validMoves(empty, 3, "x", true)
	for _, m := range restricted {
		if m == 4 {
			t.Fatal("center must be banned on first X move")
		}
	}
	if len(restricted) != 8 {
		t.Fatalf("want 8 moves, got %d", len(restricted))
	}
	// После первого хода центр снова доступен.
	after := board3("x", "", "", "", "", "", "", "", "")
	moves := validMoves(after, 3, "x", true)
	foundCenter := false
	for _, m := range moves {
		if m == 4 {
			foundCenter = true
		}
	}
	if !foundCenter {
		t.Fatal("center should be allowed after first move")
	}
}

func TestValidMovesSkipsOccupied(t *testing.T) {
	b := board3("x", "", "o", "", "", "", "", "", "")
	moves := validMoves(b, 3, "x", false)
	for _, m := range moves {
		if m == 0 || m == 2 {
			t.Fatalf("occupied cell %d in moves", m)
		}
	}
	if len(moves) != 7 {
		t.Fatalf("want 7, got %d", len(moves))
	}
}

func TestMatchmakeKey(t *testing.T) {
	k1 := matchmakeKeyVariant(30, gameengine.VariantClassic, 100)
	k2 := matchmakeKeyVariant(30, gameengine.VariantClassic, 100)
	k3 := matchmakeKeyVariant(30, gameengine.VariantGomoku, 100)
	if k1 != k2 {
		t.Fatal("same params must match")
	}
	if k1 == k3 {
		t.Fatal("variant must change key")
	}
	want := "tictactoe:matchmake:30:classic:100"
	if k1 != want {
		t.Fatalf("got %q want %q", k1, want)
	}
}

func TestParseBoardAndEmptyBoardJSON(t *testing.T) {
	raw := emptyBoardJSON(3)
	b := parseBoard(raw, 3)
	if len(b) != 9 {
		t.Fatalf("len=%d", len(b))
	}
	for _, c := range b {
		if c != "" {
			t.Fatal("expected empty cells")
		}
	}
	// Невалидный JSON / неверный размер → пустая доска нужной длины.
	bad := parseBoard(`["x"]`, 3)
	if len(bad) != 9 {
		t.Fatalf("bad len=%d", len(bad))
	}
	// Слишком большой grid → fallback 9
	huge := parseBoard(`[]`, 100)
	if len(huge) != 9 {
		t.Fatalf("huge fallback len=%d", len(huge))
	}
	if emptyBoardJSON(0) == "" {
		t.Fatal("emptyBoardJSON(0) should still return JSON")
	}
}

func TestFormatBoard(t *testing.T) {
	out := formatBoard(nil)
	if out == "" {
		t.Fatal("empty input should produce JSON array")
	}
	b := parseBoard(out, 3)
	if len(b) != 9 {
		t.Fatalf("roundtrip len=%d", len(b))
	}
}

func TestBotPickCellSmartWinsAndBlocks(t *testing.T) {
	// Бот (o) может выиграть.
	winBoard := board3("o", "o", "", "x", "x", "", "", "", "")
	if cell := botPickCellSmart(winBoard, 3, "o", false); cell != 2 {
		t.Fatalf("bot should take winning cell 2, got %d", cell)
	}
	// Бот должен блокировать победу x.
	blockBoard := board3("x", "x", "", "o", "", "", "", "", "")
	if cell := botPickCellSmart(blockBoard, 3, "o", false); cell != 2 {
		t.Fatalf("bot should block at 2, got %d", cell)
	}
	if botPickCellSmart(board3("x", "o", "x", "x", "o", "o", "o", "x", "x"), 3, "o", false) != -1 {
		t.Fatal("full board → -1")
	}
	forkBoard := board3("x", "", "", "", "o", "x", "", "", "")
	if cell := botPickCellSmart(forkBoard, 3, "x", false); cell != 2 {
		t.Fatalf("bot should take fork at 2, got %d", cell)
	}
	multi := make([]string, 64)
	multi[0], multi[1], multi[2] = "t", "t", "t"
	if cell := botPickCellSmartAt(multi, 8, "o", false, 4); cell != 3 {
		t.Fatalf("multi bot should block 4-in-row at 3, got %d", cell)
	}
}

func TestAttachTttIdentity(t *testing.T) {
	payload := map[string]any{
		"type":    "game_state",
		"game_id": "g1",
		"board":   []string{"x", "", "", "", "", "", "", "", ""},
	}
	attachTttIdentity(payload, map[string]string{
		"x_user_id":    "u1",
		"o_user_id":    "u2",
		"stake_bronze": "4",
	})
	if payload["x_user_id"] != "u1" || payload["o_user_id"] != "u2" {
		t.Fatalf("missing player ids: %v", payload)
	}
	if payload["stake_bronze"] != 4 {
		t.Fatalf("stake=%v", payload["stake_bronze"])
	}
}
