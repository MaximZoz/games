package gameregistry

import "multigames/server/internal/store"

// NewTicTacToe — модуль крестиков (classic / gomoku / ultimate / multi).
func NewTicTacToe() Module {
	return base{
		id:      store.GameTypeTicTacToe,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "classic", MinPlayers: 2, MaxPlayers: 2},
			{ID: "gomoku", MinPlayers: 2, MaxPlayers: 2},
			{ID: "ultimate", MinPlayers: 2, MaxPlayers: 2},
			{ID: "multi3", MinPlayers: 3, MaxPlayers: 3},
			{ID: "multi4", MinPlayers: 4, MaxPlayers: 4},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeTicTacToe),
	}
}
