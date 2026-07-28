package api

import (
	"testing"

	"multigames/server/internal/store"
)

func TestNormalizeGameSettingsDefaultsAndValid(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		TurnTimeSec: 30,
		GridSize:    5,
		SwapRule:    true,
		FirstMoveRestriction: true,
		StakeBronze: 50,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeTicTacToe {
		t.Fatalf("game_type=%s", s.GameType)
	}
	if s.TurnTimeSec != 30 || s.GridSize != 5 || !s.SwapRule || !s.FirstMoveRestriction || s.StakeBronze != 50 {
		t.Fatalf("unexpected %+v", s)
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
		{TurnTimeSec: 0, GridSize: 2, StakeBronze: 1},
		{TurnTimeSec: 0, GridSize: 9, StakeBronze: 1},
	}
	for i, body := range cases {
		if _, errMsg := normalizeGameSettings(body); errMsg == "" {
			t.Fatalf("case %d expected error for %+v", i, body)
		}
	}
}

func TestNormalizeGameSettingsAllTurnTimesAndGrids(t *testing.T) {
	for _, tt := range []int{0, 10, 30, 60, 600} {
		for _, g := range []int{3, 4, 5, 6, 7, 8} {
			_, errMsg := normalizeGameSettings(gameSettingsBody{
				TurnTimeSec: tt,
				GridSize:    g,
				StakeBronze: 1,
			})
			if errMsg != "" {
				t.Fatalf("tt=%d g=%d: %s", tt, g, errMsg)
			}
		}
	}
}

func TestGameSettingsToJSON(t *testing.T) {
	m := gameSettingsToJSON(store.UserGameSettings{
		GameType:             "tictactoe",
		TurnTimeSec:          60,
		GridSize:             4,
		SwapRule:             true,
		FirstMoveRestriction: false,
		StakeBronze:          10,
	})
	if m["turn_time_sec"] != 60 || m["grid_size"] != 4 || m["swap_rule"] != true {
		t.Fatalf("%v", m)
	}
	if m["first_move_restriction"] != false || m["stake_bronze"] != 10 {
		t.Fatalf("%v", m)
	}
}
