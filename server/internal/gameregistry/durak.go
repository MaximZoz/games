package gameregistry

import "multigames/server/internal/store"

// NewDurak — модуль Дурака (подкидной / переводной, 2–4 игрока).
func NewDurak() Module {
	return base{
		id:      store.GameTypeDurak,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "podkidnoi", MinPlayers: 2, MaxPlayers: 4},
			{ID: "perevodnoi", MinPlayers: 2, MaxPlayers: 4},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeDurak),
	}
}
