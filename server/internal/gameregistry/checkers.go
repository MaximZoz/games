package gameregistry

import "multigames/server/internal/store"

func NewCheckers() Module {
	return base{
		id:      store.GameTypeCheckers,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "russian", MinPlayers: 2, MaxPlayers: 2},
			{ID: "english", MinPlayers: 2, MaxPlayers: 2},
			{ID: "giveaway", MinPlayers: 2, MaxPlayers: 2},
			{ID: "corners", MinPlayers: 2, MaxPlayers: 2},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeCheckers),
	}
}
