package domino

import (
	"fmt"
	"testing"
)

// seaSignature доигрывает морскую партию ботами и сворачивает её в строку:
// козёл, счёт, число событий, конов и ходов двумя дублями.
func seaSignature(players int, seed int64) (string, error) {
	ids := make([]string, players)
	for i := range ids {
		ids[i] = fmt.Sprintf("p%d", i)
	}
	g, err := NewMatch(ids, seed, ModeSea)
	if err != nil {
		return "", err
	}
	pairs := 0
	for step := 0; step < 20000 && !g.IsOver(); step++ {
		if g.Status == StatusRoundEnd {
			if err := g.Apply(Action{Type: ActionNextRound}); err != nil {
				return "", err
			}
			continue
		}
		action := BestAction(g, g.Turn)
		if action.Type == ActionPlayPair {
			pairs++
		}
		if err := g.Apply(action); err != nil {
			return "", fmt.Errorf("step %d %+v: %w", step, action, err)
		}
	}
	scores := ""
	for i, player := range g.Players {
		if i > 0 {
			scores += ","
		}
		scores += fmt.Sprint(player.Score)
	}
	return fmt.Sprintf("goat=%d scores=%s events=%d rounds=%d pairs=%d", g.GoatSeat, scores, g.EventSeq, g.Round, pairs), nil
}

// Те же строки сверяет client/test/domino_engine_test.dart: движок и бот на
// Go и на Dart обязаны сыграть морскую партию одинаково, ход в ход.
var seaParity = []struct {
	players int
	seed    int64
	want    string
}{
	{2, 3, "goat=1 scores=25,125 events=336 rounds=13 pairs=5"},
	{2, 11, "goat=0 scores=136,0 events=221 rounds=8 pairs=1"},
	{3, 5, "goat=1 scores=33,50,0 events=350 rounds=12 pairs=7"},
	{4, 9, "goat=2 scores=75,50,150,0 events=1047 rounds=41 pairs=16"},
}

func TestSeaParityWithClient(t *testing.T) {
	for _, tc := range seaParity {
		got, err := seaSignature(tc.players, tc.seed)
		if err != nil {
			t.Fatalf("players=%d seed=%d: %v", tc.players, tc.seed, err)
		}
		if got != tc.want {
			t.Errorf("players=%d seed=%d:\n got %q\nwant %q", tc.players, tc.seed, got, tc.want)
		}
	}
}
