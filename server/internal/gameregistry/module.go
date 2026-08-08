package gameregistry

import "multigames/server/internal/store"

// ModeDescriptor описывает режим/вариант создания лобби.
type ModeDescriptor struct {
	ID         string `json:"id"`
	MinPlayers int    `json:"min_players"`
	MaxPlayers int    `json:"max_players"`
}

// Module — плагин одной игры в общий каркас.
//
// Сейчас модуль несёт метаданные и политики (ничья, оффлайн, пути).
// HTTP-обработчики Create/Join/Move пока в api.GamesHandler; следующий шаг —
// перенос lifecycle-методов в Module (см. docs/ADDING_A_GAME.md).
type Module interface {
	// ID совпадает с game_type в Redis/API (`tictactoe`, `durak`).
	ID() string
	// Modes — публикуемые режимы (для админки / будущей витрины).
	Modes() []ModeDescriptor
	// SupportsOffline — есть бот / локальная партия.
	SupportsOffline() bool
	// SupportsDrawOffer — можно предлагать ничью при данном числе игроков.
	SupportsDrawOffer(playerCount int) bool
	// DefaultSettings — дефолты user_game_settings.
	DefaultSettings() store.UserGameSettings
}

// base — общие политики для 1×1 / multi.
type base struct {
	id       string
	offline  bool
	modes    []ModeDescriptor
	defaults store.UserGameSettings
}

func (b base) ID() string                         { return b.id }
func (b base) Modes() []ModeDescriptor            { return b.modes }
func (b base) SupportsOffline() bool              { return b.offline }
func (b base) DefaultSettings() store.UserGameSettings { return b.defaults }

func (b base) SupportsDrawOffer(playerCount int) bool {
	return playerCount == 2
}
