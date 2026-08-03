package api

import (
	"testing"

	"multigames/server/internal/store"
)

func TestNormalizeGameSettingsDefaultsAndValid(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		TurnTimeSec:          20,
		Variant:              "gomoku",
		SwapRule:             true,
		FirstMoveRestriction: true,
		StakeBronze:          50,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeTicTacToe {
		t.Fatalf("game_type=%s", s.GameType)
	}
	if s.TurnTimeSec != 20 || s.GridSize != 15 || s.Variant != "gomoku" || s.StakeBronze != 50 {
		t.Fatalf("unexpected %+v", s)
	}
	if s.SwapRule || s.FirstMoveRestriction {
		t.Fatalf("deprecated flags must be false: %+v", s)
	}
}

func TestNormalizeGameSettingsStakeClamp(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		TurnTimeSec: 0,
		GridSize:    3,
		StakeBronze: 0,
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s.StakeBronze != 1 {
		t.Fatalf("stake=%d want 1", s.StakeBronze)
	}
}

func TestNormalizeGameSettingsRejects(t *testing.T) {
	cases := []gameSettingsBody{
		{GameType: "chess", TurnTimeSec: 0, GridSize: 3, StakeBronze: 1},
		{TurnTimeSec: 15, GridSize: 3, StakeBronze: 1},
	}
	for i, body := range cases {
		if _, errMsg := normalizeGameSettings(body); errMsg == "" {
			t.Fatalf("case %d expected error for %+v", i, body)
		}
	}
}

func TestNormalizeGameSettingsVariants(t *testing.T) {
	for _, tt := range []int{0, 20, 60, 600} {
		for _, v := range []string{"classic", "gomoku", "ultimate", "multi3", "multi4"} {
			s, errMsg := normalizeGameSettings(gameSettingsBody{
				TurnTimeSec: tt,
				Variant:     v,
				StakeBronze: 1,
			})
			if errMsg != "" {
				t.Fatalf("tt=%d v=%s: %s", tt, v, errMsg)
			}
			if s.Variant != v {
				t.Fatalf("variant=%s want %s", s.Variant, v)
			}
		}
	}
}

func TestGameSettingsToJSON(t *testing.T) {
	m := gameSettingsToJSON(store.UserGameSettings{
		GameType:             "tictactoe",
		TurnTimeSec:          60,
		GridSize:             3,
		Variant:              "classic",
		SwapRule:             true,
		FirstMoveRestriction: true,
		StakeBronze:          10,
	})
	if m["turn_time_sec"] != 60 || m["grid_size"] != 3 || m["variant"] != "classic" {
		t.Fatalf("%v", m)
	}
	// swap / nocenter больше не используются.
	if m["swap_rule"] != false || m["first_move_restriction"] != false || m["stake_bronze"] != 10 {
		t.Fatalf("%v", m)
	}
}
