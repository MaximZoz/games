package gameregistry

import "multigames/server/internal/store"

// NewPoker — модуль Texas Hold'em No-Limit (2–6 игроков, оффлайн-бот).
func NewPoker() Module {
	return base{
		id:      store.GameTypePoker,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "holdem", MinPlayers: 2, MaxPlayers: 6},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypePoker),
	}
}
