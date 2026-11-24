package domino

import (
	"fmt"
	"strings"
	"testing"
)

func TestTileCatalog(t *testing.T) {
	if TileID(0, 0) != 0 || TileID(6, 6) != 27 || TileID(5, 3) != TileID(3, 5) {
		t.Fatalf("ids 0-0=%d 6-6=%d 3-5=%d", TileID(0, 0), TileID(6, 6), TileID(3, 5))
	}
	seen := map[int]bool{}
	for hi := 0; hi <= 6; hi++ {
		for lo := 0; lo <= hi; lo++ {
			id := TileID(lo, hi)
			gotLo, gotHi := Pips(id)
			if gotLo != lo || gotHi != hi || seen[id] {
				t.Fatalf("tile %d-%d → %d → %d-%d", lo, hi, id, gotLo, gotHi)
			}
			seen[id] = true
		}
	}
	if len(seen) != 28 {
		t.Fatalf("catalog %d", len(seen))
	}
}

func TestDealShapeAndOpening(t *testing.T) {
	two, err := NewGame([]string{"a", "b"}, 7)
	if err != nil {
		t.Fatal(err)
	}
	if len(two.Boneyard) != 14 || len(two.Players[0].Hand) != 7 || len(two.Players[1].Hand) != 7 {
		t.Fatalf("2p deal bone=%d hands=%d/%d", len(two.Boneyard), len(two.Players[0].Hand), len(two.Players[1].Hand))
	}
	seat, tile, ok := two.pickOpening()
	if !ok || two.Turn != seat || two.ForcedTile != tile {
		t.Fatalf("opening seat=%d tile=%d turn=%d forced=%d", seat, tile, two.Turn, two.ForcedTile)
	}
	moves := two.LegalMoves(two.Turn)
	if len(moves) != 1 || moves[0].Tile != tile {
		t.Fatalf("forced moves %+v want %d", moves, tile)
	}
	if err := two.Apply(Action{Type: ActionPlay, Tile: tile, End: "left"}); err != nil {
		t.Fatal(err)
	}
	if two.LeftEnd < 0 || len(two.Chain) != 1 {
		t.Fatalf("chain %+v ends %d-%d", two.Chain, two.LeftEnd, two.RightEnd)
	}

	three, err := NewGame([]string{"a", "b", "c"}, 9)
	if err != nil || len(three.Boneyard) != 7 {
		t.Fatalf("3p bone=%d err=%v", len(three.Boneyard), err)
	}
	four, err := NewGame([]string{"a", "b", "c", "d"}, 11)
	if err != nil || len(four.Boneyard) != 0 {
		t.Fatalf("4p bone=%d err=%v", len(four.Boneyard), err)
	}
}

func freshGame(hands [][]int, boneyard []int, left, right int) *Game {
	g := &Game{
		LeftEnd:    left,
		RightEnd:   right,
		ForcedTile: -1,
		OutSeat:    -1,
		GoatSeat:   -1,
		Status:     StatusPlaying,
		Round:      2,
		Target:     GoatScore,
		Rng:        99,
		LastTile:   -1,
		LastTile2:  -1,
		LastActor:  -1,
		Starter:    0,
	}
	for i, hand := range hands {
		g.Players = append(g.Players, Player{
			UserID: fmt.Sprintf("p%d", i),
			Hand:   append([]int(nil), hand...),
		})
	}
	g.Boneyard = append([]int(nil), boneyard...)
	if left >= 0 {
		g.Chain = []Placed{{
			ID: TileID(left, right), Lo: left, Hi: right, Inward: left, Outward: right, End: "start", Double: left == right,
		}}
	}
	return g
}

func TestDoubleKeepsEnd(t *testing.T) {
	g := freshGame([][]int{{TileID(3, 5), TileID(3, 3)}, {TileID(1, 1)}}, nil, -1, -1)
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(3, 5), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if g.LeftEnd != 3 || g.RightEnd != 5 {
		t.Fatalf("ends %d-%d", g.LeftEnd, g.RightEnd)
	}
	if g.Turn != 1 {
		t.Fatalf("turn %d", g.Turn)
	}
	if err := g.Apply(Action{Type: ActionPass}); err != nil {
		t.Fatal(err)
	}
	if g.Status != StatusPlaying {
		t.Fatalf("status %s, p0 can still play the double", g.Status)
	}
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(3, 3), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if g.LeftEnd != 3 || g.RightEnd != 5 {
		t.Fatalf("double changed ends %d-%d", g.LeftEnd, g.RightEnd)
	}
	if len(g.Chain) != 2 || !g.Chain[0].Double {
		t.Fatalf("chain %+v", g.Chain)
	}
}

func TestDrawThenMustPlayAndHiddenTile(t *testing.T) {
	match := TileID(0, 4)
	g := freshGame([][]int{{TileID(2, 2)}, {TileID(1, 1)}}, []int{match, TileID(5, 5)}, 0, 1)
	if err := g.Apply(Action{Type: ActionPass}); err == nil {
		t.Fatal("pass while boneyard has tiles")
	}
	if err := g.Apply(Action{Type: ActionDraw}); err != nil {
		t.Fatal(err)
	}
	if g.Turn != 0 || len(g.Players[0].Hand) != 2 || g.LastTile != TileID(5, 5) {
		t.Fatalf("draw hand=%v tile=%d turn=%d", g.Players[0].Hand, g.LastTile, g.Turn)
	}
	if err := g.Apply(Action{Type: ActionPass}); err == nil {
		t.Fatal("pass after a useless draw while boneyard remains")
	}
	if err := g.Apply(Action{Type: ActionDraw}); err != nil {
		t.Fatal(err)
	}
	if g.LastTile != match {
		t.Fatalf("drew %d", g.LastTile)
	}
	opp := g.View("p1")
	if opp.LastTile != -1 {
		t.Fatalf("opponent saw drawn tile %d", opp.LastTile)
	}
	me := g.View("p0")
	if me.LastTile != match || len(me.Players[1].Hand) != 0 {
		t.Fatalf("view leak hand=%v tile=%d", me.Players[1].Hand, me.LastTile)
	}
	if len(me.Legal) != 1 || me.Legal[0].Tile != match {
		t.Fatalf("must play %+v", me.Legal)
	}
	if err := g.Apply(Action{Type: ActionPlay, Tile: match, End: "left"}); err != nil {
		t.Fatal(err)
	}
}

func TestFishAndOutScoring(t *testing.T) {
	light := TileID(1, 1)
	heavy := TileID(2, 3)
	g := freshGame([][]int{{light}, {heavy}}, nil, 6, 6)
	if err := g.Apply(Action{Type: ActionPass}); err != nil {
		t.Fatal(err)
	}
	if g.Status != StatusRoundEnd || g.RoundKind != RoundFish {
		t.Fatalf("fish status=%s kind=%s", g.Status, g.RoundKind)
	}
	if g.Players[0].RoundDelta != 0 || g.Players[1].RoundDelta != 5 {
		t.Fatalf("fish deltas %d %d", g.Players[0].RoundDelta, g.Players[1].RoundDelta)
	}
	tied := freshGame([][]int{{light}, {light}}, nil, 6, 6)
	if err := tied.Apply(Action{Type: ActionPass}); err != nil {
		t.Fatal(err)
	}
	if tied.Players[0].RoundDelta != 2 || tied.Players[1].RoundDelta != 2 {
		t.Fatalf("tied fish %d %d", tied.Players[0].RoundDelta, tied.Players[1].RoundDelta)
	}

	out := freshGame([][]int{{TileID(4, 6)}, {heavy, light}}, nil, 6, 0)
	if err := out.Apply(Action{Type: ActionPlay, Tile: TileID(4, 6), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if out.RoundKind != RoundOut || out.Players[0].RoundDelta != 0 || out.Players[1].Score != 7 {
		t.Fatalf("out kind=%s d0=%d s1=%d", out.RoundKind, out.Players[0].RoundDelta, out.Players[1].Score)
	}
	if err := out.Apply(Action{Type: ActionNextRound}); err != nil {
		t.Fatal(err)
	}
	if out.Starter != 0 || out.Turn != 0 || out.Status != StatusPlaying || out.ForcedTile != -1 {
		t.Fatalf("next starter=%d turn=%d forced=%d status=%s", out.Starter, out.Turn, out.ForcedTile, out.Status)
	}
}

func TestFishStarterTieBreak(t *testing.T) {
	g := freshGame([][]int{{TileID(1, 1)}, {TileID(1, 1)}, {TileID(2, 3)}}, nil, 6, 6)
	g.Starter = 0
	if err := g.Apply(Action{Type: ActionPass}); err != nil {
		t.Fatal(err)
	}
	if g.RoundKind != RoundFish {
		t.Fatal(g.RoundKind)
	}
	if err := g.Apply(Action{Type: ActionNextRound}); err != nil {
		t.Fatal(err)
	}
	if g.Starter != 1 {
		t.Fatalf("tied fish should start at the next seat, got %d", g.Starter)
	}
}

func TestGoatIsHighestScore(t *testing.T) {
	g := freshGame([][]int{
		{TileID(0, 1)},
		{TileID(6, 6)},
		{TileID(0, 5)},
	}, nil, 1, 2)
	g.Players[0].Score = 100
	g.Players[1].Score = 100
	g.Players[2].Score = 99
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(0, 1), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if g.Status != StatusOver || g.GoatSeat != 1 {
		t.Fatalf("status=%s goat=%d scores=%d %d %d", g.Status, g.GoatSeat, g.Players[0].Score, g.Players[1].Score, g.Players[2].Score)
	}
	if len(g.WinnerUserIDs) != 1 || g.WinnerUserIDs[0] != "p0" {
		t.Fatalf("winners %v", g.WinnerUserIDs)
	}
	view := g.View("p2")
	if len(view.Players[1].Hand) == 0 {
		t.Fatal("finished round must reveal hands")
	}
}

func TestForfeitLeavesWinner(t *testing.T) {
	g := freshGame([][]int{{TileID(0, 0), TileID(1, 1)}, {TileID(2, 2)}}, nil, -1, -1)
	if err := g.Apply(Action{Type: ActionForfeit, Actor: "p0"}); err != nil {
		t.Fatal(err)
	}
	if !g.IsOver() || len(g.WinnerUserIDs) != 1 || g.WinnerUserIDs[0] != "p1" || g.GoatSeat != 0 {
		t.Fatalf("winners=%v goat=%d", g.WinnerUserIDs, g.GoatSeat)
	}
}

func TestModesDealOpeningAndScore(t *testing.T) {
	four, err := NewMatch([]string{"a", "b", "c", "d"}, 3, ModeClassic)
	if err != nil || four.Target != ClassicScore || four.Mode != ModeClassic {
		t.Fatalf("classic err=%v mode=%s target=%d", err, four.Mode, four.Target)
	}
	if len(four.Players[0].Hand) != 5 || len(four.Boneyard) != 8 {
		t.Fatalf("classic 4p hands=%d bone=%d", len(four.Players[0].Hand), len(four.Boneyard))
	}
	sea, err := NewMatch([]string{"a", "b"}, 5, ModeSea)
	if err != nil || sea.Target != SeaScore || len(sea.Players[0].Hand) != 7 || len(sea.Boneyard) != 14 {
		t.Fatalf("sea err=%v target=%d bone=%d", err, sea.Target, len(sea.Boneyard))
	}
	if NormalizeMode("nope") != ModeKozel || NormalizeMode(" classic ") != ModeClassic {
		t.Fatal("normalize")
	}

	opening := freshGame([][]int{{TileID(1, 1)}, {TileID(6, 6), TileID(0, 0)}}, nil, -1, -1)
	opening.Mode = ModeClassic
	seat, tile, ok := opening.pickOpening()
	if !ok || seat != 1 || tile != TileID(6, 6) {
		t.Fatalf("classic open seat=%d tile=%d", seat, tile)
	}
	opening.Players[1].Hand = []int{TileID(0, 0)}
	seat, tile, ok = opening.pickOpening()
	if !ok || seat != 1 || tile != TileID(0, 0) {
		t.Fatalf("classic blank open seat=%d tile=%d", seat, tile)
	}
	opening.Mode = ModeKozel
	opening.Players[0].Hand = []int{TileID(1, 1)}
	opening.Players[1].Hand = []int{TileID(6, 6)}
	seat, tile, ok = opening.pickOpening()
	if !ok || seat != 0 || tile != TileID(1, 1) {
		t.Fatalf("goat open seat=%d tile=%d", seat, tile)
	}
}

func TestClassicOutAndFish(t *testing.T) {
	g := freshGame([][]int{{TileID(1, 1)}, {TileID(3, 3), TileID(4, 4)}}, nil, 1, 2)
	g.Mode = ModeClassic
	g.Target = ClassicScore
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(1, 1), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if g.Status != StatusRoundEnd || g.Players[0].Score != 14 || g.Players[1].Score != 0 || g.RoundKind != RoundOut {
		t.Fatalf("classic out scores=%d/%d kind=%s status=%s", g.Players[0].Score, g.Players[1].Score, g.RoundKind, g.Status)
	}

	fish := freshGame([][]int{{TileID(2, 3)}, {TileID(4, 4)}, {TileID(5, 5), TileID(6, 6)}}, nil, 0, 1)
	fish.Mode = ModeClassic
	fish.Target = ClassicScore
	fish.finishRound(RoundFish, -1)
	if fish.Players[0].Score != 20 || fish.Players[1].Score != 0 || fish.Players[2].Score != 0 {
		t.Fatalf("classic fish %d %d %d", fish.Players[0].Score, fish.Players[1].Score, fish.Players[2].Score)
	}

	tie := freshGame([][]int{{TileID(2, 2)}, {TileID(0, 4)}}, nil, 0, 1)
	tie.Mode = ModeClassic
	tie.Target = ClassicScore
	tie.finishRound(RoundFish, -1)
	if tie.Players[0].Score != 0 || tie.Players[1].Score != 0 || tie.Status != StatusRoundEnd {
		t.Fatalf("tie fish %d %d %s", tie.Players[0].Score, tie.Players[1].Score, tie.Status)
	}

	win := freshGame([][]int{{TileID(6, 6)}, {TileID(5, 5), TileID(5, 4), TileID(6, 5)}}, nil, 6, 0)
	win.Mode = ModeClassic
	win.Target = ClassicScore
	win.Players[0].Score = 90
	if err := win.Apply(Action{Type: ActionPlay, Tile: TileID(6, 6), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if !win.IsOver() || len(win.WinnerUserIDs) != 1 || win.WinnerUserIDs[0] != "p0" || win.GoatSeat != -1 {
		t.Fatalf("classic win winners=%v goat=%d score=%d", win.WinnerUserIDs, win.GoatSeat, win.Players[0].Score)
	}
}

func seaGame(hands [][]int, boneyard []int, left, right int) *Game {
	g := freshGame(hands, boneyard, left, right)
	g.Mode = ModeSea
	g.Target = SeaScore
	return g
}

func TestSeaScoring(t *testing.T) {
	// 0-0 посреди кона — обычная кость: кон идёт дальше.
	blank := seaGame([][]int{{TileID(0, 0), TileID(1, 2)}, {TileID(6, 6), TileID(5, 1)}}, nil, 0, 5)
	if err := blank.Apply(Action{Type: ActionPlay, Tile: TileID(0, 0), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if blank.Status != StatusPlaying || blank.Turn != 1 || blank.Players[1].Score != 0 || len(blank.Players[0].Hand) != 1 {
		t.Fatalf("blank status=%s turn=%d score=%d hand=%d", blank.Status, blank.Turn, blank.Players[1].Score, len(blank.Players[0].Hand))
	}

	light := seaGame([][]int{{}, {TileID(5, 5), TileID(4, 4)}}, nil, 0, 1)
	light.finishRound(RoundOut, 0)
	if light.Players[1].Score != 0 || light.Players[1].RoundPips != 18 {
		t.Fatalf("under 25 score=%d pips=%d", light.Players[1].Score, light.Players[1].RoundPips)
	}

	rec := seaGame([][]int{{}, {TileID(6, 6), TileID(6, 5), TileID(6, 4)}}, nil, 0, 1)
	rec.finishRound(RoundOut, 0)
	if rec.Players[1].Score != 33 {
		t.Fatalf("record %d", rec.Players[1].Score)
	}

	both := freshGame([][]int{{TileID(6, 6), TileID(6, 5), TileID(6, 4)}, {TileID(5, 5), TileID(5, 4), TileID(5, 3)}}, nil, 0, 1)
	both.Mode = ModeSea
	both.Target = SeaScore
	both.Players[0].Score = 40
	both.finishRound(RoundFish, -1)
	if both.Players[0].Score != 40 || both.Players[1].Score != 0 {
		t.Fatalf("wipe %d %d", both.Players[0].Score, both.Players[1].Score)
	}

	six := freshGame([][]int{{TileID(6, 6)}, {TileID(5, 5)}}, nil, 6, 1)
	six.Mode = ModeSea
	six.Target = SeaScore
	six.Players[0].Score = 40
	if err := six.Apply(Action{Type: ActionPlay, Tile: TileID(6, 6), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if six.Players[0].Score != 0 || six.Players[1].Score != SeaSixHit || six.RoundKind != RoundOut {
		t.Fatalf("six scores=%d/%d kind=%s", six.Players[0].Score, six.Players[1].Score, six.RoundKind)
	}

	lose := freshGame([][]int{{TileID(6, 6)}, {TileID(3, 3)}}, nil, 6, 0)
	lose.Mode = ModeSea
	lose.Target = SeaScore
	lose.Players[1].Score = 50
	if err := lose.Apply(Action{Type: ActionPlay, Tile: TileID(6, 6), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if !lose.IsOver() || lose.GoatSeat != 1 || len(lose.WinnerUserIDs) != 1 || lose.WinnerUserIDs[0] != "p0" {
		t.Fatalf("sea lose goat=%d winners=%v scores=%d/%d", lose.GoatSeat, lose.WinnerUserIDs, lose.Players[0].Score, lose.Players[1].Score)
	}
}

func TestSeaLoneDoubles(t *testing.T) {
	cases := []struct {
		name string
		hand []int
		want int
	}{
		{"одна 0-0", []int{TileID(0, 0)}, SeaLoneBlank},
		{"одна 6-6", []int{TileID(6, 6)}, SeaLoneSix},
		{"0-0 и 6-6", []int{TileID(6, 6), TileID(0, 0)}, SeaBlankSix},
		{"6-6 с другой костью", []int{TileID(6, 6), TileID(0, 1)}, 0},
		{"0-0 с другой костью", []int{TileID(0, 0), TileID(6, 5), TileID(6, 4), TileID(5, 5)}, 31},
	}
	for _, tc := range cases {
		g := seaGame([][]int{{}, tc.hand}, nil, 3, 1)
		g.finishRound(RoundOut, 0)
		if g.Players[1].Score != tc.want || g.Players[1].RoundDelta != tc.want || g.Players[0].Score != 0 {
			t.Fatalf("%s: score=%d delta=%d", tc.name, g.Players[1].Score, g.Players[1].RoundDelta)
		}
	}

	// Одинокий дубль тяжелее обычной руки: пишут ему, а не руке на 20.
	three := seaGame([][]int{{}, {TileID(0, 0)}, {TileID(6, 4), TileID(5, 5)}}, nil, 3, 1)
	three.finishRound(RoundOut, 0)
	if three.Players[1].Score != SeaLoneBlank || three.Players[2].Score != 0 {
		t.Fatalf("lone blank vs 20: %d %d", three.Players[1].Score, three.Players[2].Score)
	}
}

func TestSeaFastOpening(t *testing.T) {
	// Пока у соперника нет записи, зайти с 0-0 или 6-6 нельзя.
	g := seaGame([][]int{{TileID(0, 0), TileID(6, 6), TileID(2, 3)}, {TileID(3, 5)}}, nil, -1, -1)
	moves := g.LegalMoves(0)
	if len(moves) != 1 || moves[0].Tile != TileID(2, 3) {
		t.Fatalf("opening without records: %+v", moves)
	}
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(0, 0), End: "left"}); err == nil {
		t.Fatal("fast opening must be rejected")
	}
	g.Players[1].Score = 30
	if len(g.LegalMoves(0)) != 3 {
		t.Fatalf("opening with records: %+v", g.LegalMoves(0))
	}
	// В «Козле» ограничения нет.
	goat := freshGame([][]int{{TileID(0, 0), TileID(2, 3)}, {TileID(3, 5)}}, nil, -1, -1)
	if len(goat.LegalMoves(0)) != 2 {
		t.Fatalf("goat opening: %+v", goat.LegalMoves(0))
	}

	for _, tc := range []struct {
		pip, want int
	}{{0, SeaFastBlank}, {6, SeaFastSix}} {
		fast := seaGame([][]int{{TileID(tc.pip, tc.pip), TileID(tc.pip, 3)}, {TileID(3, 5), TileID(1, 1)}}, nil, -1, -1)
		fast.Players[1].Score = 30
		if err := fast.Apply(Action{Type: ActionPlay, Tile: TileID(tc.pip, tc.pip), End: "left"}); err != nil {
			t.Fatal(err)
		}
		if fast.Status != StatusPlaying {
			t.Fatalf("fast opening must not end the round: %s", fast.Status)
		}
		// Соперник пасует: 3-5 и 1-1 к концу не подходят, базар пуст.
		if err := fast.Apply(Action{Type: ActionPass}); err != nil {
			t.Fatal(err)
		}
		if err := fast.Apply(Action{Type: ActionPlay, Tile: TileID(tc.pip, 3), End: "left"}); err != nil {
			t.Fatal(err)
		}
		if fast.Status != StatusRoundEnd || fast.Players[1].Score != 30+tc.want || fast.Players[1].RoundDelta != tc.want {
			t.Fatalf("fast %d: status=%s score=%d", tc.pip, fast.Status, fast.Players[1].Score)
		}
	}

	// Рыба в быстром коне не пишется никому.
	fish := seaGame([][]int{{TileID(1, 2), TileID(1, 3), TileID(1, 4)}, {TileID(5, 5), TileID(5, 4), TileID(5, 3)}}, nil, 6, 6)
	fish.Players[0].Score = 40
	fish.finishRound(RoundFish, -1)
	if fish.Status != StatusRoundEnd || fish.Players[0].Score != 40 || fish.Players[1].Score != 0 {
		t.Fatalf("fast fish %s %d %d", fish.Status, fish.Players[0].Score, fish.Players[1].Score)
	}
}

func TestSeaOutOnBlankEndsMatch(t *testing.T) {
	// Соперник ведёт по записи, но кон закрыт на 0-0: козёл — тяжёлая рука.
	g := seaGame([][]int{{TileID(0, 0)}, {TileID(1, 2)}, {TileID(6, 5), TileID(4, 4)}}, nil, 0, 3)
	g.Players[0].Score = 90
	g.Players[1].Score = 110
	g.Players[2].Score = 10
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(0, 0), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if !g.IsOver() || g.GoatSeat != 2 || len(g.WinnerUserIDs) != 1 || g.WinnerUserIDs[0] != "p0" {
		t.Fatalf("blank out: status=%s goat=%d winners=%v", g.Status, g.GoatSeat, g.WinnerUserIDs)
	}
	if g.Players[0].Score != 90 || g.Players[1].Score != 110 || g.Players[2].Score != 10 {
		t.Fatalf("blank out must not change scores: %d %d %d", g.Players[0].Score, g.Players[1].Score, g.Players[2].Score)
	}
}

func TestSeaPairOfDoubles(t *testing.T) {
	g := seaGame([][]int{{TileID(3, 3), TileID(5, 5), TileID(1, 2)}, {TileID(3, 4), TileID(5, 1)}}, nil, 3, 5)
	if !g.CanPair(0) || !g.View("p0").CanPair || g.View("p1").CanPair {
		t.Fatal("pair must be offered to the mover only")
	}
	if err := g.Apply(Action{Type: ActionPlayPair}); err != nil {
		t.Fatal(err)
	}
	if len(g.Players[0].Hand) != 1 || g.LeftEnd != 3 || g.RightEnd != 5 || g.Turn != 1 {
		t.Fatalf("pair hand=%v ends=%d/%d turn=%d", g.Players[0].Hand, g.LeftEnd, g.RightEnd, g.Turn)
	}
	if g.LastAction != ActionPlayPair || g.LastTile != TileID(3, 3) || g.LastTile2 != TileID(5, 5) || len(g.Chain) != 3 {
		t.Fatalf("pair last=%s %d %d chain=%d", g.LastAction, g.LastTile, g.LastTile2, len(g.Chain))
	}
	if g.Chain[0].ID != TileID(3, 3) || g.Chain[2].ID != TileID(5, 5) {
		t.Fatalf("pair chain %+v", g.Chain)
	}
	view := g.View("p1")
	if view.LastTile != TileID(3, 3) || view.LastTile2 != TileID(5, 5) {
		t.Fatalf("pair view %d %d", view.LastTile, view.LastTile2)
	}
	if err := g.Apply(Action{Type: ActionPlay, Tile: TileID(3, 4), End: "left"}); err != nil {
		t.Fatal(err)
	}
	if g.LastTile2 != -1 {
		t.Fatalf("single play must clear the second tile, got %d", g.LastTile2)
	}

	// Обычная кость, потом пара: после 5-4 концы 3 и 4, дубли 3-3 и 4-4
	// остаются в руке. Ход уже ушёл, поэтому «Два дубля» не кладёт ещё две.
	after := seaGame([][]int{{TileID(5, 4), TileID(3, 3), TileID(5, 5), TileID(4, 4)}, {TileID(0, 1)}}, []int{TileID(6, 6)}, 3, 5)
	if !after.CanPair(0) {
		t.Fatal("pair button is available before the plain tile")
	}
	if err := after.Apply(Action{Type: ActionPlay, Tile: TileID(5, 4), End: "right"}); err != nil {
		t.Fatal(err)
	}
	if after.Turn != 1 || after.LeftEnd != 3 || after.RightEnd != 4 || len(after.Chain) != 2 || len(after.Players[0].Hand) != 3 {
		t.Fatalf("plain tile must end the turn: turn=%d ends=%d/%d chain=%d hand=%v", after.Turn, after.LeftEnd, after.RightEnd, len(after.Chain), after.Players[0].Hand)
	}
	if after.CanPair(0) || after.Apply(Action{Type: ActionPlayPair}) == nil {
		t.Fatal("pair after a plain tile must be rejected")
	}
	after.Turn = 0
	if !after.CanPair(0) {
		t.Fatal("the same hand could pair if the turn had not passed")
	}

	// Одного дубля мало, как и одинаковых концов.
	one := seaGame([][]int{{TileID(3, 3), TileID(1, 2)}, {TileID(3, 4)}}, nil, 3, 5)
	if one.CanPair(0) || one.Apply(Action{Type: ActionPlayPair}) == nil {
		t.Fatal("pair needs both doubles")
	}
	same := seaGame([][]int{{TileID(3, 3), TileID(1, 2)}, {TileID(3, 4)}}, nil, 3, 3)
	if same.CanPair(0) {
		t.Fatal("equal ends take one double")
	}
	// Только морской режим.
	goat := freshGame([][]int{{TileID(3, 3), TileID(5, 5), TileID(1, 2)}, {TileID(3, 4)}}, nil, 3, 5)
	if goat.CanPair(0) || goat.Apply(Action{Type: ActionPlayPair}) == nil {
		t.Fatal("pair is a sea-only move")
	}

	// Пара закрывает кон: 6-6 в паре — 100 и сброс счёта закрывшего.
	six := seaGame([][]int{{TileID(6, 6), TileID(2, 2)}, {TileID(1, 3)}}, nil, 6, 2)
	six.Players[0].Score = 60
	if err := six.Apply(Action{Type: ActionPlayPair}); err != nil {
		t.Fatal(err)
	}
	if six.Status != StatusRoundEnd || six.RoundKind != RoundOut || six.Players[0].Score != 0 || six.Players[1].Score != SeaSixHit {
		t.Fatalf("pair six status=%s scores=%d/%d", six.Status, six.Players[0].Score, six.Players[1].Score)
	}
	// 0-0 в паре — конец партии, даже вместе с 6-6.
	admiral := seaGame([][]int{{TileID(6, 6), TileID(0, 0)}, {TileID(1, 3)}}, nil, 6, 0)
	admiral.Players[0].Score = 60
	if err := admiral.Apply(Action{Type: ActionPlayPair}); err != nil {
		t.Fatal(err)
	}
	if !admiral.IsOver() || admiral.GoatSeat != 1 || admiral.WinnerUserIDs[0] != "p0" || admiral.Players[0].Score != 60 {
		t.Fatalf("admiral status=%s goat=%d score=%d", admiral.Status, admiral.GoatSeat, admiral.Players[0].Score)
	}
}

func TestDecodeLegacyStateHasNoSecondTile(t *testing.T) {
	g, err := NewMatch([]string{"a", "b"}, 7, ModeSea)
	if err != nil {
		t.Fatal(err)
	}
	if g.LastTile2 != -1 {
		t.Fatalf("new match last_tile2=%d", g.LastTile2)
	}
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	legacy := strings.Replace(raw, `"last_tile2":-1,`, "", 1)
	if legacy == raw {
		t.Fatal("last_tile2 not found in the encoded state")
	}
	back, err := Decode(legacy)
	if err != nil {
		t.Fatal(err)
	}
	if back.LastTile2 != -1 {
		t.Fatalf("legacy last_tile2=%d", back.LastTile2)
	}
}

func TestEncodeRoundTrip(t *testing.T) {
	g, err := NewGame([]string{"a", "b", "c"}, 42)
	if err != nil {
		t.Fatal(err)
	}
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	back, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if back.ForcedTile != g.ForcedTile || len(back.Boneyard) != len(g.Boneyard) || back.Players[1].UserID != "b" {
		t.Fatalf("roundtrip %+v", back)
	}
}
