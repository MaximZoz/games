package api

import "testing"

func TestStatsGameMode(t *testing.T) {
	if got := statsGameMode("tictactoe", map[string]string{"variant": "gomoku"}); got != "gomoku" {
		t.Fatalf("ttt %q", got)
	}
	if got := statsGameMode("durak", map[string]string{"player_ids": "a,b,c", "deck_size": "52"}); got != "3:52" {
		t.Fatalf("durak %q", got)
	}
	if got := statsGameMode("checkers", map[string]string{"game_mode": "english"}); got != "english" {
		t.Fatalf("checkers %q", got)
	}
	if got := statsGameMode("nardy", map[string]string{"game_mode": "long"}); got != "long" {
		t.Fatalf("nardy %q", got)
	}
	if got := statsGameMode("chess", map[string]string{"game_mode": "blitz"}); got != "blitz" {
		t.Fatalf("chess %q", got)
	}
	if got := statsGameMode("uno", map[string]string{"game_mode": "classic"}); got != "" {
		t.Fatalf("uno %q", got)
	}
}
