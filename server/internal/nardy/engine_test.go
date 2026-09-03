package nardy

import (
	"math/rand"
	"testing"
)

func totalOnBoard(g *Game, seat int) int {
	total := g.Bar[seat] + g.Off[seat]
	for t := 0; t < Points; t++ {
		total += g.CountAt(seat, t)
	}
	return total
}

func TestNewGameShortSetup(t *testing.T) {
	g := NewGame(ModeShort)
	if g.Mode != ModeShort {
		t.Fatalf("mode = %q", g.Mode)
	}
	for _, seat := range []int{0, 1} {
		if got := totalOnBoard(g, seat); got != Checkers {
			t.Fatalf("seat %d has %d checkers, want %d", seat, got, Checkers)
		}
		for track, want := range map[int]int{0: 2, 11: 5, 16: 3, 18: 5} {
			if got := g.CountAt(seat, track); got != want {
				t.Fatalf("seat %d track %d = %d, want %d", seat, track, got, want)
			}
		}
	}
	// Классическая доска: 2 шашки белых на 24-м пункте и 2 чёрных на 1-м.
	if g.Board[23] != 2 {
		t.Fatalf("board[23] = %d, want 2", g.Board[23])
	}
	if g.Board[0] != -2 {
		t.Fatalf("board[0] = %d, want -2", g.Board[0])
	}
}

func TestNewGameLongSetup(t *testing.T) {
	g := NewGame(ModeLong)
	for _, seat := range []int{0, 1} {
		if got := g.CountAt(seat, 0); got != Checkers {
			t.Fatalf("seat %d head = %d, want %d", seat, got, Checkers)
		}
		if got := totalOnBoard(g, seat); got != Checkers {
			t.Fatalf("seat %d total = %d", seat, got)
		}
	}
	if g.Board[23] != Checkers {
		t.Fatalf("white head at board[23] = %d", g.Board[23])
	}
	if g.Board[11] != -Checkers {
		t.Fatalf("black head at board[11] = %d", g.Board[11])
	}
}

func TestTrackMappingRoundTrip(t *testing.T) {
	for _, mode := range []string{ModeShort, ModeLong} {
		for seat := 0; seat < 2; seat++ {
			for track := 0; track < Points; track++ {
				p := TrackToBoard(mode, seat, track)
				if p < 0 || p >= Points {
					t.Fatalf("%s seat %d track %d -> %d", mode, seat, track, p)
				}
				if back := BoardToTrack(mode, seat, p); back != track {
					t.Fatalf("%s seat %d track %d -> %d -> %d", mode, seat, track, p, back)
				}
			}
		}
	}
}

func TestLongHeadLimitOnePerTurn(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(5, 2); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 5}); err != nil {
		t.Fatalf("first head move: %v", err)
	}
	for _, mv := range g.LegalMoves() {
		if mv.From == 0 {
			t.Fatalf("second checker left the head: %+v", mv)
		}
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 2}); err == nil {
		t.Fatal("expected head limit to reject the second checker")
	}
}

func TestLongFirstTurnDoubleAllowsTwoFromHead(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(6, 6); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 6}); err != nil {
		t.Fatalf("first head move: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 6}); err != nil {
		t.Fatalf("second head move on 6-6: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 6}); err == nil {
		t.Fatal("third checker from the head must be rejected")
	}
}

func TestLongDoubleTwoIsNotHeadException(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(2, 2); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 2}); err != nil {
		t.Fatalf("first head move: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 2}); err == nil {
		t.Fatal("2-2 does not allow a second checker from the head")
	}
}

func TestLongNoHittingOpponentPointIsBlocked(t *testing.T) {
	g := NewGame(ModeLong)
	// Ставим одиночную шашку соперника прямо перед белыми.
	g.Board = [Points]int{}
	g.setTrack(0, 0, 1)
	g.setTrack(1, 0, 1)
	// Пункт дорожки 3 белых = физический 20; ставим туда чёрную шашку.
	g.Board[20] = -1
	if g.CanLand(0, 3) {
		t.Fatal("long nardy must not allow landing on an opponent point")
	}
}

func TestShortHitSendsBlotToBar(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 0, 1)
	// Одиночная шашка соперника на дорожке 3 белых.
	g.Board[TrackToBoard(ModeShort, 0, 3)] = -1
	g.Off[1] = 0
	if err := g.RollWith(3, 4); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 3}); err != nil {
		t.Fatalf("hit: %v", err)
	}
	if g.Bar[1] != 1 {
		t.Fatalf("bar[1] = %d, want 1", g.Bar[1])
	}
	if g.CountAt(0, 3) != 1 {
		t.Fatalf("white checker did not land on track 3")
	}
}

func TestShortBarMustReenterFirst(t *testing.T) {
	g := NewGame(ModeShort)
	g.Bar[0] = 1
	if err := g.RollWith(1, 2); err != nil {
		t.Fatalf("roll: %v", err)
	}
	for _, mv := range g.LegalMoves() {
		if mv.From != BarTrack {
			t.Fatalf("with a checker on the bar only re-entry is legal, got %+v", mv)
		}
	}
	if err := g.ApplyMove(0, Move{From: BarTrack, Die: 1}); err != nil {
		t.Fatalf("re-enter: %v", err)
	}
	if g.Bar[0] != 0 {
		t.Fatalf("bar[0] = %d after re-entry", g.Bar[0])
	}
}

func TestBearOffOnlyWhenAllHome(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 20, 1)
	g.setTrack(0, 10, 1)
	g.setTrack(1, 0, 2)
	if g.AllHome(0) {
		t.Fatal("checker outside home must block bearing off")
	}
	g.Board[TrackToBoard(ModeShort, 0, 10)] = 0
	g.setTrack(0, 21, 1)
	if !g.AllHome(0) {
		t.Fatal("all checkers are home now")
	}
	if err := g.RollWith(4, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	// Дорожка 20 + 4 = 24 — ровное снятие.
	if err := g.ApplyMove(0, Move{From: 20, Die: 4}); err != nil {
		t.Fatalf("bear off: %v", err)
	}
	if g.Off[0] != 1 {
		t.Fatalf("off[0] = %d, want 1", g.Off[0])
	}
}

func TestBearOffOverflowUsesFarthestChecker(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 21, 1)
	g.setTrack(0, 22, 1)
	g.setTrack(1, 0, 2)
	if err := g.RollWith(6, 1); err != nil {
		t.Fatalf("roll: %v", err)
	}
	// Перебор шестёркой допустим только с самого дальнего пункта (21).
	if err := g.ApplyMove(0, Move{From: 22, Die: 6}); err == nil {
		t.Fatal("overflow bear off from the near point must be rejected")
	}
	if err := g.ApplyMove(0, Move{From: 21, Die: 6}); err != nil {
		t.Fatalf("overflow bear off from the farthest point: %v", err)
	}
}

func TestWinnerAndMars(t *testing.T) {
	g := NewGame(ModeLong)
	g.Board = [Points]int{}
	g.Off[0] = Checkers - 1
	g.setTrack(0, 23, 1)
	g.setTrack(1, 0, Checkers)
	if err := g.RollWith(1, 1); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 23, Die: 1}); err != nil {
		t.Fatalf("final bear off: %v", err)
	}
	if g.Winner != 0 {
		t.Fatalf("winner = %d, want 0", g.Winner)
	}
	if g.WinKind != "mars" {
		t.Fatalf("win kind = %q, want mars", g.WinKind)
	}
}

func TestMaxDiceRuleForcesLargerDie(t *testing.T) {
	g := NewGame(ModeLong)
	g.Board = [Points]int{}
	// Одна белая шашка на дорожке 20; закрываем пункт под меньший кубик.
	g.setTrack(0, 20, 1)
	g.setTrack(1, 0, Checkers)
	g.Board[TrackToBoard(ModeLong, 0, 22)] = -1
	if err := g.RollWith(5, 2); err != nil {
		t.Fatalf("roll: %v", err)
	}
	// 20+2 закрыт соперником, 20+5 = 25 — снятия ещё нет (не все дома? дома).
	// Остаться должен только больший играбельный кубик.
	if len(g.Dice) != 1 {
		t.Fatalf("dice = %v, want a single forced die", g.Dice)
	}
	if g.Dice[0] != 5 {
		t.Fatalf("forced die = %d, want 5", g.Dice[0])
	}
}

func TestRollWithoutMovesPassesTurn(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.Bar[0] = 1
	// Соперник закрыл весь дом — ввести шашку невозможно.
	for track := 0; track < 6; track++ {
		g.Board[TrackToBoard(ModeShort, 0, track)] = -2
	}
	if err := g.RollWith(3, 4); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if g.Turn != 1 {
		t.Fatalf("turn = %d, want the turn to pass", g.Turn)
	}
	if len(g.Rolled) == 0 {
		t.Fatal("the skipped roll must stay visible for the client")
	}
}

func TestEncodeDecodeRoundTrip(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(6, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	raw, err := Encode(g)
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	back, err := Decode(raw)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if back.Mode != g.Mode || back.Turn != g.Turn || len(back.Dice) != len(g.Dice) {
		t.Fatalf("decoded state differs: %+v vs %+v", back, g)
	}
	if back.Board != g.Board {
		t.Fatalf("board differs")
	}
}

func TestPipsCountsBarAndProgress(t *testing.T) {
	g := NewGame(ModeLong)
	// 15 шашек на голове: каждая должна пройти 24 пункта.
	if got, want := g.Pips(0), Checkers*Points; got != want {
		t.Fatalf("pips = %d, want %d", got, want)
	}
	g.Bar[0] = 1
	if got, want := g.Pips(0), Checkers*Points+Points+1; got != want {
		t.Fatalf("pips with bar = %d, want %d", got, want)
	}
}

func TestBotFinishesLongGame(t *testing.T) {
	g := NewGame(ModeLong)
	rng := rand.New(rand.NewSource(7))
	for turn := 0; turn < 4000 && g.Winner < 0; turn++ {
		if len(g.Dice) == 0 {
			if err := g.Roll(rng); err != nil {
				t.Fatalf("roll: %v", err)
			}
			continue
		}
		mv, ok := BotBestMove(g, rng)
		if !ok {
			g.EndTurn()
			continue
		}
		seat := g.Turn
		if err := g.ApplyMove(seat, mv); err != nil {
			t.Fatalf("bot move %+v: %v", mv, err)
		}
	}
	if g.Winner < 0 {
		t.Fatalf("bots did not finish the game: off=%v", g.Off)
	}
	if g.Off[g.Winner] != Checkers {
		t.Fatalf("winner has %d checkers off", g.Off[g.Winner])
	}
}

func TestBotFinishesShortGame(t *testing.T) {
	g := NewGame(ModeShort)
	rng := rand.New(rand.NewSource(11))
	for turn := 0; turn < 6000 && g.Winner < 0; turn++ {
		if len(g.Dice) == 0 {
			if err := g.Roll(rng); err != nil {
				t.Fatalf("roll: %v", err)
			}
			continue
		}
		mv, ok := BotBestMove(g, rng)
		if !ok {
			g.EndTurn()
			continue
		}
		if err := g.ApplyMove(g.Turn, mv); err != nil {
			t.Fatalf("bot move %+v: %v", mv, err)
		}
	}
	if g.Winner < 0 {
		t.Fatalf("bots did not finish the short game: off=%v", g.Off)
	}
}

func TestCheckerCountStaysConsistent(t *testing.T) {
	for _, mode := range []string{ModeShort, ModeLong} {
		g := NewGame(mode)
		rng := rand.New(rand.NewSource(3))
		for i := 0; i < 3000 && g.Winner < 0; i++ {
			if len(g.Dice) == 0 {
				if err := g.Roll(rng); err != nil {
					t.Fatalf("%s roll: %v", mode, err)
				}
				continue
			}
			mv, ok := BotBestMove(g, rng)
			if !ok {
				g.EndTurn()
				continue
			}
			if err := g.ApplyMove(g.Turn, mv); err != nil {
				t.Fatalf("%s move: %v", mode, err)
			}
			for seat := 0; seat < 2; seat++ {
				if got := totalOnBoard(g, seat); got != Checkers {
					t.Fatalf("%s seat %d lost checkers: %d", mode, seat, got)
				}
			}
		}
	}
}

func TestUndoRestoresPositionAndDice(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(5, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	before := g.Board
	beforeDice := append([]int(nil), g.Dice...)
	if err := g.ApplyMove(0, Move{From: 0, Die: 5}); err != nil {
		t.Fatalf("move: %v", err)
	}
	if !g.CanUndo() {
		t.Fatal("move must be undoable")
	}
	if err := g.Undo(0); err != nil {
		t.Fatalf("undo: %v", err)
	}
	if g.Board != before {
		t.Fatal("board was not restored")
	}
	if len(g.Dice) != len(beforeDice) {
		t.Fatalf("dice = %v, want %v", g.Dice, beforeDice)
	}
	if g.HeadMoved != 0 {
		t.Fatalf("head counter = %d, want 0", g.HeadMoved)
	}
	if g.CanUndo() {
		t.Fatal("history must be empty after undo")
	}
}

func TestUndoRestoresHitChecker(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 0, 1)
	g.Board[TrackToBoard(ModeShort, 0, 3)] = -1
	if err := g.RollWith(3, 4); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 3}); err != nil {
		t.Fatalf("hit: %v", err)
	}
	if g.Bar[1] != 1 {
		t.Fatalf("bar[1] = %d, want 1", g.Bar[1])
	}
	if err := g.Undo(0); err != nil {
		t.Fatalf("undo: %v", err)
	}
	if g.Bar[1] != 0 {
		t.Fatalf("bar[1] = %d after undo, want 0", g.Bar[1])
	}
	if g.OpponentAt(0, 3) != 1 {
		t.Fatal("hit checker was not returned to its point")
	}
	if g.CountAt(0, 0) != 1 {
		t.Fatal("own checker was not returned to the head")
	}
}

func TestUndoRestoresBorneOffChecker(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 20, 1)
	g.setTrack(1, 0, 2)
	if err := g.RollWith(4, 2); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 20, Die: 4}); err != nil {
		t.Fatalf("bear off: %v", err)
	}
	if g.Off[0] != 1 {
		t.Fatalf("off = %d", g.Off[0])
	}
	if err := g.Undo(0); err != nil {
		t.Fatalf("undo: %v", err)
	}
	if g.Off[0] != 0 || g.CountAt(0, 20) != 1 {
		t.Fatalf("bear off not undone: off=%d track20=%d", g.Off[0], g.CountAt(0, 20))
	}
}

func TestTurnStaysOpenUntilConfirmed(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(5, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 5}); err != nil {
		t.Fatalf("first move: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 5, Die: 3}); err != nil {
		t.Fatalf("second move: %v", err)
	}
	if g.Turn != 0 {
		t.Fatal("turn must wait for confirmation so the player can undo")
	}
	if !g.TurnComplete() {
		t.Fatal("all dice are used — turn is complete")
	}
	if err := g.Undo(0); err != nil {
		t.Fatalf("undo after the last die: %v", err)
	}
	if len(g.Dice) == 0 {
		t.Fatal("undo must return the die")
	}
}

func TestUndoRejectedForOtherSeat(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(5, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 5}); err != nil {
		t.Fatalf("move: %v", err)
	}
	if err := g.Undo(1); err == nil {
		t.Fatal("opponent must not undo your move")
	}
}

func TestEndTurnPublishesLastMoves(t *testing.T) {
	g := NewGame(ModeLong)
	if err := g.RollWith(5, 3); err != nil {
		t.Fatalf("roll: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 0, Die: 5}); err != nil {
		t.Fatalf("move: %v", err)
	}
	if err := g.ApplyMove(0, Move{From: 5, Die: 3}); err != nil {
		t.Fatalf("move: %v", err)
	}
	g.EndTurn()
	if len(g.LastTurn) != 2 {
		t.Fatalf("last turn = %+v, want 2 moves", g.LastTurn)
	}
	if g.LastTurnSeat != 0 {
		t.Fatalf("last turn seat = %d", g.LastTurnSeat)
	}
	first := g.LastTurn[0]
	if first.FromPoint != TrackToBoard(ModeLong, 0, 0) {
		t.Fatalf("from point = %d", first.FromPoint)
	}
	if first.ToPoint != TrackToBoard(ModeLong, 0, 5) {
		t.Fatalf("to point = %d", first.ToPoint)
	}
	if g.CanUndo() {
		t.Fatal("history must be cleared after the turn ends")
	}
}

func TestForfeitGivesWinToOpponent(t *testing.T) {
	g := NewGame(ModeShort)
	g.Forfeit(1)
	if g.Winner != 0 {
		t.Fatalf("winner = %d, want 0", g.Winner)
	}
	if len(g.Dice) != 0 {
		t.Fatalf("dice must be cleared after forfeit")
	}
}
