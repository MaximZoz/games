package gameregistry

import (
	"testing"

	"multigames/server/internal/store"
)

func TestDefaultRegistry(t *testing.T) {
	r := Default()
	if !r.Has(store.GameTypeTicTacToe) || !r.Has(store.GameTypeDurak) ||
		!r.Has(store.GameTypeBattleship) || !r.Has(store.GameTypePoker) ||
		!r.Has(store.GameTypeUno) {
		t.Fatalf("expected all built-in games, got %v", r.IDs())
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
	uno := r.MustGet(store.GameTypeUno)
	if !uno.SupportsOffline() {
		t.Fatal("uno must support offline mode")
	}
	modes := uno.Modes()
	if len(modes) != 1 || modes[0].ID != "classic" ||
		modes[0].MinPlayers != 2 || modes[0].MaxPlayers != 4 {
		t.Fatalf("uno modes: %+v", modes)
	}
	defaults := uno.DefaultSettings()
	if defaults.MaxPlayers != 2 || defaults.TurnTimeSec != 60 ||
		defaults.GameMode != "classic" || defaults.Variant != "classic" {
		t.Fatalf("uno defaults: %+v", defaults)
	}
	if r.Normalize("unknown") != store.GameTypeTicTacToe {
		t.Fatalf("normalize unknown")
	}
}
