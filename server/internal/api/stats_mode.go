package api

import (
	"fmt"
	"strconv"
	"strings"

	"multigames/server/internal/checkers"
	"multigames/server/internal/chess"
	"multigames/server/internal/nardy"
	"multigames/server/internal/store"
)

// statsGameMode — стабильный ключ режима для game_results.game_mode.
// Пустая строка: у игры нет переключателя режима.
func statsGameMode(gameType string, m map[string]string) string {
	if m == nil {
		m = map[string]string{}
	}
	switch strings.TrimSpace(gameType) {
	case "", "tictactoe":
		v := strings.TrimSpace(m["variant"])
		if v == "" {
			return "classic"
		}
		return v
	case store.GameTypeDurak:
		players := len(parsePlayerIDsCSV(m["player_ids"]))
		if players < 2 {
			players = 2
		}
		deck, _ := strconv.Atoi(strings.TrimSpace(m["deck_size"]))
		if deck == 0 {
			deck = 36
		}
		return fmt.Sprintf("%d:%d", players, deck)
	case store.GameTypeCheckers:
		return checkers.NormalizeMode(m["game_mode"])
	case store.GameTypeNardy:
		return nardy.NormalizeMode(m["game_mode"])
	case store.GameTypeChess:
		return chess.NormalizeMode(m["game_mode"])
	default:
		return ""
	}
}
