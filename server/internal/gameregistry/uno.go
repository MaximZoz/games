package gameregistry

import "multigames/server/internal/store"

// NewUno — классическая UNO для 2–4 игроков с офлайн-ботом.
func NewUno() Module {
	return base{
		id:      store.GameTypeUno,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "classic", MinPlayers: 2, MaxPlayers: 4},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeUno),
	}
}
