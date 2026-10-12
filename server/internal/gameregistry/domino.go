package gameregistry

import "multigames/server/internal/store"

// noDraw — штрафная партия: предложение ничьей выключено.
type noDraw struct{ base }

func (noDraw) SupportsDrawOffer(int) bool { return false }

// NewDomino — «Козёл»: 2–4 игрока, офлайн-бот, без предложения ничьей.
func NewDomino() Module {
	return noDraw{base{
		id:      store.GameTypeDomino,
		offline: true,
		modes: []ModeDescriptor{
			{ID: "kozel", MinPlayers: 2, MaxPlayers: 4},
		},
		defaults: store.DefaultUserGameSettings(store.GameTypeDomino),
	}}
}
