package gameregistry

import (
	"testing"

	"multigames/server/internal/store"
)

func TestDefaultRegistry(t *testing.T) {
	r := Default()
	if !r.Has(store.GameTypeTicTacToe) || !r.Has(store.GameTypeDurak) {
		t.Fatalf("expected tictactoe+durak, got %v", r.IDs())
	}
	ttt := r.MustGet(store.GameTypeTicTacToe)
	if !ttt.SupportsDrawOffer(2) || ttt.SupportsDrawOffer(3) {
		t.Fatalf("ttt draw policy: 2=%v 3=%v", ttt.SupportsDrawOffer(2), ttt.SupportsDrawOffer(3))
	}
	if r.Normalize("") != store.GameTypeTicTacToe {
		t.Fatalf("normalize empty: %s", r.Normalize(""))
	}
	if r.Normalize("durak") != store.GameTypeDurak {
		t.Fatalf("normalize durak")
	}
	if r.Normalize("unknown") != store.GameTypeTicTacToe {
		t.Fatalf("normalize unknown")
	}
}
