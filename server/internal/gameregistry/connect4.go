package gameregistry

import "multigames/server/internal/store"

func NewConnect4() Module {
	return base{
		id:      store.GameTypeConnect4,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "classic", MinPlayers: 2, MaxPlayers: 2},
			{ID: "wide", MinPlayers: 2, MaxPlayers: 2},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeConnect4),
	}
}
