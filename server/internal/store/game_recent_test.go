package store

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestGroupRecentGamesCollapsesTable(t *testing.T) {
	me := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	ann := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	bob := uuid.MustParse("33333333-3333-3333-3333-333333333333")
	now := time.Date(2026, 10, 12, 12, 0, 0, 0, time.UTC)
	rows := []recentRow{
		{GameID: "table:" + bob.String(), GameType: "uno", Result: "x_won", X: me, O: bob, Winner: &me, CreatedAt: now},
		{GameID: "table:" + ann.String(), GameType: "uno", Result: "x_won", X: me, O: ann, Winner: &me, CreatedAt: now.Add(-time.Second)},
		{GameID: "older", GameType: "tictactoe", Mode: "classic", Result: "o_won", X: me, O: ann, Winner: &ann, CreatedAt: now.Add(-time.Hour)},
	}
	got := groupRecentGames(me, rows, 10)
	if len(got) != 2 {
		t.Fatalf("games: %d", len(got))
	}
	if got[0].Outcome != "win" || got[0].GameType != "uno" || len(got[0].Opponents) != 2 {
		t.Fatalf("first: %+v", got[0])
	}
	if got[0].Opponents[0].OpponentID != bob.String() || got[0].Opponents[1].OpponentID != ann.String() {
		t.Fatalf("opponents: %+v", got[0].Opponents)
	}
	if got[1].Outcome != "loss" || got[1].Mode != "classic" {
		t.Fatalf("second: %+v", got[1])
	}
}

func TestGroupRecentGamesDrawAndBot(t *testing.T) {
	me := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	rows := []recentRow{
		{GameID: "g1", GameType: "checkers", Mode: "russian", Result: "o_won", X: me, AgainstBot: true, CreatedAt: time.Now()},
	}
	got := groupRecentGames(me, rows, 10)
	if len(got) != 1 || got[0].Outcome != "loss" || len(got[0].Opponents) != 1 || !got[0].Opponents[0].Bot {
		t.Fatalf("%+v", got)
	}
}

func TestGroupRecentGamesLimit(t *testing.T) {
	me := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	other := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	rows := make([]recentRow, 0, 12)
	for i := 0; i < 12; i++ {
		w := other
		rows = append(rows, recentRow{
			GameID:    uuid.NewString(),
			GameType:  "chess",
			Result:    "o_won",
			X:         me,
			O:         other,
			Winner:    &w,
			CreatedAt: time.Now().Add(-time.Duration(i) * time.Minute),
		})
	}
	if got := groupRecentGames(me, rows, 10); len(got) != 10 {
		t.Fatalf("len %d", len(got))
	}
}

func TestPickRecentBucketsKeepsEachMode(t *testing.T) {
	games := make([]RecentGame, 0, 15)
	for i := 0; i < 12; i++ {
		games = append(games, RecentGame{GameType: "chess", Mode: "classic", Outcome: "win"})
	}
	games = append(games,
		RecentGame{GameType: "chess", Mode: "blitz", Outcome: "loss"},
		RecentGame{GameType: "chess", Mode: "blitz", Outcome: "draw"},
		RecentGame{GameType: "uno", Outcome: "win"},
	)
	got := pickRecentBuckets(games, 10)
	if len(got) != 13 {
		t.Fatalf("len %d", len(got))
	}
	blitz := 0
	uno := 0
	classic := 0
	for _, g := range got {
		switch {
		case g.GameType == "uno":
			uno++
		case g.Mode == "blitz":
			blitz++
		case g.Mode == "classic":
			classic++
		}
	}
	if classic != 10 || blitz != 2 || uno != 1 {
		t.Fatalf("classic %d blitz %d uno %d", classic, blitz, uno)
	}
}
