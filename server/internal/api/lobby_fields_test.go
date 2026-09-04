package api

import (
	"testing"

	"multigames/server/internal/nardy"
)

func TestApplyLobbyTypeFields_NoFakeClassic(t *testing.T) {
	t.Parallel()

	uno := LobbyItem{GameType: unoGameType, Variant: "classic", GridSize: 3}
	applyLobbyTypeFields(&uno, map[string]string{"variant": "classic", "game_mode": "classic"})
	if uno.Variant != "" {
		t.Fatalf("uno must not expose tictactoe variant, got %q", uno.Variant)
	}
	if uno.GameMode != "classic" {
		t.Fatalf("uno internal game_mode: %q", uno.GameMode)
	}

	nardyLong := LobbyItem{GameType: nardyGameType, Variant: "classic", GridSize: 3}
	applyLobbyTypeFields(&nardyLong, map[string]string{"game_mode": nardy.ModeLong})
	if nardyLong.Variant != "" {
		t.Fatalf("nardy must not leak classic variant, got %q", nardyLong.Variant)
	}
	if nardyLong.GameMode != nardy.ModeLong {
		t.Fatalf("nardy long mode: %q", nardyLong.GameMode)
	}

	nardyFromVariant := LobbyItem{GameType: nardyGameType, Variant: "classic"}
	applyLobbyTypeFields(&nardyFromVariant, map[string]string{"variant": nardy.ModeShort})
	if nardyFromVariant.GameMode != nardy.ModeShort {
		t.Fatalf("nardy short from variant field: %q", nardyFromVariant.GameMode)
	}

	poker := LobbyItem{GameType: pokerGameType, Variant: "classic"}
	applyLobbyTypeFields(&poker, map[string]string{})
	if poker.Variant != "" || poker.GameMode != "holdem" {
		t.Fatalf("poker fields: variant=%q mode=%q", poker.Variant, poker.GameMode)
	}

	future := LobbyItem{GameType: "chess", Variant: "classic", GridSize: 3}
	applyLobbyTypeFields(&future, map[string]string{"variant": "classic", "game_mode": ""})
	if future.Variant != "" {
		t.Fatalf("unknown game must not keep classic variant, got %q", future.Variant)
	}

	ttt := LobbyItem{GameType: "tictactoe", Variant: "classic", GridSize: 3}
	applyLobbyTypeFields(&ttt, map[string]string{"variant": "classic"})
	if ttt.Variant != "classic" {
		t.Fatalf("tictactoe classic is a real mode, got %q", ttt.Variant)
	}
}
