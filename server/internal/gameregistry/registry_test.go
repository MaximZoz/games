package gameregistry

import (
	"testing"

	"multigames/server/internal/store"
)

func TestDefaultRegistry(t *testing.T) {
	r := Default()
	if !r.Has(store.GameTypeTicTacToe) || !r.Has(store.GameTypeDurak) ||
		!r.Has(store.GameTypeBattleship) || !r.Has(store.GameTypePoker) ||
		!r.Has(store.GameTypeUno) || !r.Has(store.GameTypeNardy) {
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
	nardy := r.MustGet(store.GameTypeNardy)
	if !nardy.SupportsOffline() || !nardy.SupportsDrawOffer(2) {
		t.Fatalf("nardy policies offline=%v draw2=%v",
			nardy.SupportsOffline(), nardy.SupportsDrawOffer(2))
	}
	nardyModes := nardy.Modes()
	if len(nardyModes) != 2 || nardyModes[0].ID != "short" || nardyModes[1].ID != "long" {
		t.Fatalf("nardy modes: %+v", nardyModes)
	}
	for _, mode := range nardyModes {
		if mode.MinPlayers != 2 || mode.MaxPlayers != 2 {
			t.Fatalf("nardy mode %q must be strictly 1x1: %+v", mode.ID, mode)
		}
	}
	if r.Normalize("nardy") != store.GameTypeNardy {
		t.Fatalf("normalize nardy")
	}
	if r.Normalize("unknown") != store.GameTypeTicTacToe {
		t.Fatalf("normalize unknown")
	}
	if !r.Has(store.GameTypeCheckers) {
		t.Fatalf("expected checkers, got %v", r.IDs())
	}
	domino := r.MustGet(store.GameTypeDomino)
	if !domino.SupportsOffline() || domino.SupportsDrawOffer(2) || domino.SupportsDrawOffer(4) {
		t.Fatalf("domino policies offline=%v draw2=%v",
			domino.SupportsOffline(), domino.SupportsDrawOffer(2))
	}
	dominoModes := domino.Modes()
	if len(dominoModes) != 3 || dominoModes[0].ID != "kozel" ||
		dominoModes[1].ID != "classic" || dominoModes[2].ID != "sea" ||
		dominoModes[0].MinPlayers != 2 || dominoModes[0].MaxPlayers != 4 {
		t.Fatalf("domino modes: %+v", dominoModes)
	}
	dominoDefaults := domino.DefaultSettings()
	if dominoDefaults.MaxPlayers != 2 || dominoDefaults.TurnTimeSec != 60 ||
		dominoDefaults.GameMode != "kozel" || dominoDefaults.Variant != "kozel" {
		t.Fatalf("domino defaults: %+v", dominoDefaults)
	}
	if r.Normalize("domino") != store.GameTypeDomino {
		t.Fatalf("normalize domino")
	}
}
