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
		{GameType: "go", TurnTimeSec: 0, GridSize: 3, StakeBronze: 2},
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

func TestNormalizeBattleshipGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:             store.GameTypeBattleship,
		TurnTimeSec:          20,
		StakeBronze:          10,
		FirstMoveRestriction: true,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeBattleship || s.GridSize != 10 || !s.FirstMoveRestriction || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
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

func TestNormalizePokerGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypePoker,
		TurnTimeSec: 60,
		StakeBronze: 10,
		MaxPlayers:  4,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypePoker || s.MaxPlayers != 4 || s.GameMode != "holdem" || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypePoker,
		TurnTimeSec: 20,
		StakeBronze: 2,
		MaxPlayers:  9,
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.MaxPlayers != 2 {
		t.Fatalf("max_players=%d want 2 (clamp)", s2.MaxPlayers)
	}
}

func TestNormalizeUnoGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeUno,
		TurnTimeSec: 60,
		StakeBronze: 10,
		MaxPlayers:  4,
		GameMode:    "unknown",
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeUno || s.MaxPlayers != 4 ||
		s.GameMode != "classic" || s.Variant != "classic" ||
		s.DeckSize != 108 || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeUno,
		TurnTimeSec: 20,
		StakeBronze: 2,
		MaxPlayers:  5,
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.MaxPlayers != 2 {
		t.Fatalf("max_players=%d want 2 (clamp)", s2.MaxPlayers)
	}
}

func TestNormalizeDominoGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeDomino,
		TurnTimeSec: 60,
		StakeBronze: 10,
		MaxPlayers:  4,
		GameMode:    "unknown",
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeDomino || s.MaxPlayers != 4 ||
		s.GameMode != "kozel" || s.Variant != "kozel" ||
		s.DeckSize != 28 || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeDomino,
		TurnTimeSec: 20,
		StakeBronze: 2,
		MaxPlayers:  5,
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.MaxPlayers != 2 {
		t.Fatalf("max_players=%d want 2 (clamp)", s2.MaxPlayers)
	}
}

func TestNormalizeNardyGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeNardy,
		TurnTimeSec: 60,
		StakeBronze: 10,
		GameMode:    "long",
		MaxPlayers:  4,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeNardy || s.MaxPlayers != 2 ||
		s.GameMode != "long" || s.Variant != "long" || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeNardy,
		TurnTimeSec: 20,
		StakeBronze: 2,
		GameMode:    "unknown",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.GameMode != "short" || s2.MaxPlayers != 2 {
		t.Fatalf("mode=%s players=%d", s2.GameMode, s2.MaxPlayers)
	}
}

func TestNormalizeCheckersGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeCheckers,
		TurnTimeSec: 60,
		StakeBronze: 10,
		GameMode:    "giveaway",
		MaxPlayers:  4,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeCheckers || s.MaxPlayers != 2 ||
		s.GameMode != "giveaway" || s.Variant != "giveaway" || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeCheckers,
		TurnTimeSec: 20,
		StakeBronze: 2,
		GameMode:    "unknown",
		Variant:     "corners",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.GameMode != "russian" || s2.Variant != "russian" || s2.MaxPlayers != 2 {
		t.Fatalf("mode=%s players=%d", s2.GameMode, s2.MaxPlayers)
	}
	s3, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeCheckers,
		TurnTimeSec: 0,
		StakeBronze: 2,
		GameMode:    "english",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s3.GameMode != "english" || s3.Variant != "english" {
		t.Fatalf("english must stay english: %+v", s3)
	}
	s4, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeCheckers,
		TurnTimeSec: 60,
		StakeBronze: 2,
		GameMode:    "corners",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s4.GameMode != "corners" || s4.Variant != "corners" {
		t.Fatalf("corners: %+v", s4)
	}
}

func TestNormalizeChessGameSettings(t *testing.T) {
	s, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeChess,
		TurnTimeSec: 60,
		StakeBronze: 10,
		GameMode:    "rapid",
		MaxPlayers:  4,
	})
	if errMsg != "" {
		t.Fatalf("err=%s", errMsg)
	}
	if s.GameType != store.GameTypeChess || s.MaxPlayers != 2 ||
		s.GameMode != "rapid" || s.Variant != "rapid" ||
		s.GridSize != 8 || s.StakeBronze != 10 {
		t.Fatalf("unexpected %+v", s)
	}
	s2, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeChess,
		TurnTimeSec: 20,
		StakeBronze: 2,
		GameMode:    "unknown",
		Variant:     "bullet",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s2.GameMode != "bullet" || s2.Variant != "bullet" {
		t.Fatalf("bullet from variant: %+v", s2)
	}
	s3, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeChess,
		TurnTimeSec: 0,
		StakeBronze: 2,
		GameMode:    "classic",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s3.GameMode != "classic" || s3.Variant != "classic" {
		t.Fatalf("classic: %+v", s3)
	}
	s4, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeChess,
		TurnTimeSec: 20,
		StakeBronze: 2,
		GameMode:    "blitz",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if s4.GameMode != "blitz" || s4.Variant != "blitz" {
		t.Fatalf("blitz: %+v", s4)
	}
	legacy, errMsg := normalizeGameSettings(gameSettingsBody{
		GameType:    store.GameTypeChess,
		TurnTimeSec: 600,
		StakeBronze: 2,
		GameMode:    "chess960",
		Variant:     "antichess",
	})
	if errMsg != "" {
		t.Fatal(errMsg)
	}
	if legacy.GameMode != "classic" || legacy.Variant != "classic" ||
		legacy.TurnTimeSec != 60 {
		t.Fatalf("legacy 960/antichess and 10 min: %+v", legacy)
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
