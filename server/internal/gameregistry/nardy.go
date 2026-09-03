package gameregistry

import "multigames/server/internal/store"

// NewNardy — нарды 1×1: короткие и длинные, с ботом.
func NewNardy() Module {
	return base{
		id:      store.GameTypeNardy,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "short", MinPlayers: 2, MaxPlayers: 2},
			{ID: "long", MinPlayers: 2, MaxPlayers: 2},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeNardy),
	}
}
