package api

import (
	"strconv"
	"strings"

	"multigames/server/internal/nardy"
	"multigames/server/internal/store"
)

// applyLobbyTypeFields заполняет variant/game_mode по типу игры.
//
// Крестики-нолики оставляют variant из resolveVariantConfig («Классика» —
// реальный режим). Остальные игры не наследуют этот variant: иначе Уно и
// нарды в списке лобби рисуются как «Классика». Новая игра без своих
// пользовательских режимов тоже не должна получать classic.
func applyLobbyTypeFields(item *LobbyItem, m map[string]string) {
	if item == nil {
		return
	}
	switch item.GameType {
	case durakGameType:
		deckSize, _ := strconv.Atoi(m["deck_size"])
		if deckSize == 0 {
			deckSize = 36
		}
		gm := strings.TrimSpace(m["game_mode"])
		if gm == "" {
			gm = "podkidnoi"
		}
		item.DeckSize = deckSize
		item.GameMode = gm
		item.Variant = ""
		item.GridSize = 0
	case battleshipGameType:
		item.Variant = ""
		item.GridSize = 10
		item.FirstMoveRestriction = m["first_move_restriction"] == "true"
	case pokerGameType:
		item.Variant = ""
		item.GridSize = 0
		item.GameMode = "holdem"
	case unoGameType:
		item.Variant = ""
		item.GridSize = 0
		item.GameMode = "classic"
	case nardyGameType:
		raw := strings.TrimSpace(m["game_mode"])
		if raw == "" {
			raw = strings.TrimSpace(m["variant"])
		}
		mode := nardy.NormalizeMode(raw)
		item.Variant = ""
		item.GridSize = 0
		item.GameMode = mode
	case store.GameTypeTicTacToe, "":
		// variant/grid уже выставлены из конфига крестиков-ноликов.
	default:
		// Будущая игра: не подставлять tictactoe-classic.
		v := strings.TrimSpace(m["variant"])
		if v == "classic" {
			v = ""
		}
		item.Variant = v
		item.GameMode = strings.TrimSpace(m["game_mode"])
		item.GridSize = 0
	}
}
