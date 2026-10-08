package gameregistry

import "multigames/server/internal/store"

func NewChess() Module {
	return base{
		id:      store.GameTypeChess,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "classic", MinPlayers: 2, MaxPlayers: 2},
			{ID: "rapid", MinPlayers: 2, MaxPlayers: 2},
			{ID: "blitz", MinPlayers: 2, MaxPlayers: 2},
			{ID: "bullet", MinPlayers: 2, MaxPlayers: 2},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeChess),
	}
}
