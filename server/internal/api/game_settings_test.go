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
	if s.StakeBronze != 2 {
		t.Fatalf("stake=%d want 2", s.StakeBronze)
	}
}

func TestNormalizeGameSettingsRejects(t *testing.T) {
	cases := []gameSettingsBody{
		{GameType: "chess", TurnTimeSec: 0, GridSize: 3, StakeBronze: 2},
		{TurnTimeSec: 15, GridSize: 3, StakeBronze: 2},
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
				StakeBronze: 2,
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

func TestNormalizeDurakGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeDurak,
		TurnTimeSec: 60,
		StakeBronze: 10,
		DeckSize:    52,
		MaxPlayers:  3,
		GameMode:    "perevodnoi",
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeDurak {
		t.Fatalf("game_type=%s", s.GameType)
	}
	if s.DeckSize != 52 || s.MaxPlayers != 3 || s.GameMode != "perevodnoi" || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	// 24 только вдвоём → clamp.
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeDurak,
		TurnTimeSec: 0,
		StakeBronze: 2,
		DeckSize:    24,
		MaxPlayers:  4,
		GameMode:    "podkidnoi",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.DeckSize != 36 {
		t.Fatalf("deck=%d want 36", s2.DeckSize)
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
		DeckSize:             36,
		MaxPlayers:           2,
		GameMode:             "podkidnoi",
	})
	if m["turn_time_sec"] != 60 || m["grid_size"] != 3 || m["variant"] != "classic" {
		t.Fatalf("%v", m)
	}
	if m["swap_rule"] != false || m["first_move_restriction"] != false || m["stake_bronze"] != 10 {
		t.Fatalf("%v", m)
	}
	md := gameSettingsToJSON(store.UserGameSettings{
		GameType:    store.GameTypeDurak,
		TurnTimeSec: 60,
		StakeBronze: 2,
		DeckSize:    36,
		MaxPlayers:  2,
		GameMode:    "podkidnoi",
	})
	if md["deck_size"] != 36 || md["game_mode"] != "podkidnoi" {
		t.Fatalf("%v", md)
	}
}
