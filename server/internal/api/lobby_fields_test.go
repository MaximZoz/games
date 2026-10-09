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

func TestBoardGameInviteMode(t *testing.T) {
	t.Parallel()

	mode, ok := boardGameInviteMode("chess", map[string]string{"game_mode": "blitz"})
	if !ok || mode != "blitz" {
		t.Fatalf("chess blitz: ok=%v mode=%q", ok, mode)
	}
	mode, ok = boardGameInviteMode("chess", map[string]string{"variant": "bullet"})
	if !ok || mode != "bullet" {
		t.Fatalf("chess variant: ok=%v mode=%q", ok, mode)
	}
	mode, ok = boardGameInviteMode("checkers", map[string]string{"game_mode": "english"})
	if !ok || mode != "english" {
		t.Fatalf("checkers: ok=%v mode=%q", ok, mode)
	}
	// Пустой режим шашек — русские, не подкидной.
	mode, ok = boardGameInviteMode("checkers", map[string]string{})
	if !ok || mode != "russian" {
		t.Fatalf("checkers empty: ok=%v mode=%q", ok, mode)
	}
	if _, ok := boardGameInviteMode("durak", map[string]string{"game_mode": "podkidnoi"}); ok {
		t.Fatal("durak is not a board-game invite mode")
	}
}
