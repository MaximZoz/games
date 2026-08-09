package gameregistry

import (
	"testing"

	"multigames/server/internal/store"
)

func TestDefaultRegistry(t *testing.T) {
	r := Default()
	if !r.Has(store.GameTypeTicTacToe) || !r.Has(store.GameTypeDurak) || !r.Has(store.GameTypeBattleship) {
		t.Fatalf("expected tictactoe+durak+battleship, got %v", r.IDs())
	}
	ttt := r.MustGet(store.GameTypeTicTacToe)
	if !ttt.SupportsDrawOffer(2) || ttt.SupportsDrawOffer(3) {
		t.Fatalf("ttt draw policy: 2=%v 3=%v", ttt.SupportsDrawOffer(2), ttt.SupportsDrawOffer(3))
	}
	bs := r.MustGet(store.GameTypeBattleship)
	if !bs.SupportsOffline() || !bs.SupportsDrawOffer(2) {
		t.Fatalf("battleship policies offline=%v draw2=%v", bs.SupportsOffline(), bs.SupportsDrawOffer(2))
	}
	if r.Normalize("") != store.GameTypeTicTacToe {
		t.Fatalf("normalize empty: %s", r.Normalize(""))
	}
	if r.Normalize("durak") != store.GameTypeDurak {
		t.Fatalf("normalize durak")
	}
	if r.Normalize("battleship") != store.GameTypeBattleship {
		t.Fatalf("normalize battleship")
	}
	if r.Normalize("unknown") != store.GameTypeTicTacToe {
		t.Fatalf("normalize unknown")
	}
}
