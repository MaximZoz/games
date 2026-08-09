package gameregistry

import "multigames/server/internal/store"

// NewBattleship — модуль «Морской бой» (1×1, русская расстановка).
func NewBattleship() Module {
	return base{
		id:      store.GameTypeBattleship,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "classic", MinPlayers: 2, MaxPlayers: 2},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeBattleship),
	}
}
