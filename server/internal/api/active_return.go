package api

import (
	"strconv"
	"strings"

	"multigames/server/internal/store"
)

// ActiveReturn — куда вернуть игрока из GetActive.
//
// Игра инжектит классификатор через [RegisterActiveReturn]. Если регистрация
// забыта, но в Redis есть game_type, отличный от крестиков, и player_ids,
// срабатывает общий разбор по местам: тип не подменяется на tictactoe.
type ActiveReturn struct {
	// Play — игрок ещё в партии (вкладка «Игры» открывает стол).
	Play bool
	// Observe — выбыл, партия идёт (карточка наблюдения).
	Observe bool
	// Clear — указатель active_game протух.
	Clear bool
	// MyTurn — сейчас ход этого игрока.
	MyTurn bool
}

// ActiveReturnFunc классифицирует хеш партии. handled=false — не этот хеш.
type ActiveReturnFunc func(hash map[string]string, userID string) (ActiveReturn, bool)

var activeReturnByType = map[string]ActiveReturnFunc{}

// RegisterActiveReturn подключает возврат в партию для game_type.
// Вызывать из init() пакета игры. Повтор id — ошибка конфигурации.
func RegisterActiveReturn(gameType string, fn ActiveReturnFunc) {
	gameType = strings.TrimSpace(gameType)
	if gameType == "" || gameType == store.GameTypeTicTacToe || fn == nil {
		panic("api: invalid active return registration")
	}
	if _, ok := activeReturnByType[gameType]; ok {
		panic("api: duplicate active return " + gameType)
	}
	activeReturnByType[gameType] = fn
}

func lookupActiveReturn(hash map[string]string) (ActiveReturnFunc, bool) {
	gt := strings.TrimSpace(hash["game_type"])
	if gt == "" || gt == store.GameTypeTicTacToe {
		return nil, false
	}
	if fn, ok := activeReturnByType[gt]; ok {
		return fn, true
	}
	return seatActiveReturn(gt), true
}

// seatActiveReturn — дефолт новой игры: участие по player_ids, ход по
// turn_actor_idx. Без player_ids классификатор отказывается, чтобы вызывающий
// код мог разобрать крестики по меткам, не переписывая чужой game_type.
func seatActiveReturn(gameType string) ActiveReturnFunc {
	return func(hash map[string]string, userID string) (ActiveReturn, bool) {
		if strings.TrimSpace(hash["game_type"]) != gameType {
			return ActiveReturn{}, false
		}
		players := parsePlayerIDsCSV(hash["player_ids"])
		if len(players) == 0 {
			return ActiveReturn{}, false
		}
		if !stringSliceContains(players, userID) {
			return ActiveReturn{Clear: true}, true
		}
		actor, err := strconv.Atoi(strings.TrimSpace(hash["turn_actor_idx"]))
		seat := simple1v1SeatOf(players, userID)
		myTurn := err == nil &&
			hash["status"] == gameStatusActive &&
			seat >= 0 &&
			seat == actor
		return ActiveReturn{Play: true, MyTurn: myTurn}, true
	}
}

type activeClass int

const (
	activeClassPlay activeClass = iota
	activeClassObserve
	activeClassClear
)

type activeClassResult struct {
	Class    activeClass
	MyTurn   bool
	GameType string
}

// classifyNonTictactoeActive — решение GetActive для любой игры, кроме крестиков.
// ok=false значит «это крестики» либо классификатор не смог разобрать хеш.
func classifyNonTictactoeActive(hash map[string]string, userID string) (activeClassResult, bool) {
	fn, ok := lookupActiveReturn(hash)
	if !ok {
		return activeClassResult{}, false
	}
	ret, handled := fn(hash, userID)
	if !handled {
		return activeClassResult{}, false
	}
	gt := strings.TrimSpace(hash["game_type"])
	switch {
	case ret.Observe:
		return activeClassResult{Class: activeClassObserve, GameType: gt}, true
	case ret.Play:
		return activeClassResult{Class: activeClassPlay, MyTurn: ret.MyTurn, GameType: gt}, true
	default:
		return activeClassResult{Class: activeClassClear, GameType: gt}, true
	}
}

// tictactoeTimeoutApplies — таймаут крестиков нельзя применять к чужому хешу.
// Иначе возврат на вкладку «Игры» портит партию и рисует чужой стол.
func tictactoeTimeoutApplies(gameType string) bool {
	gt := strings.TrimSpace(gameType)
	return gt == "" || gt == store.GameTypeTicTacToe
}
