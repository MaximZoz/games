package api

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"multigames/server/internal/gameengine"
)

// resolveVariantConfig читает variant из тела/Redis и возвращает конфиг движка.
func resolveVariantConfig(variantStr string, legacyGrid int) (gameengine.Config, gameengine.Variant) {
	v := gameengine.ParseVariant(variantStr)
	// Обратная совместимость: старые клиенты шлют только grid_size.
	if variantStr == "" && legacyGrid > 0 {
		switch legacyGrid {
		case 15:
			v = gameengine.VariantGomoku
		case 3:
			v = gameengine.VariantClassic
		default:
			// Старые 4–8 → классика (режимы убраны).
			v = gameengine.VariantClassic
		}
	}
	cfg, err := gameengine.ConfigFor(v)
	if err != nil {
		cfg, _ = gameengine.ConfigFor(gameengine.VariantClassic)
		v = gameengine.VariantClassic
	}
	return cfg, v
}

func matchmakeKeyVariant(turnTimeSec int, variant gameengine.Variant, stakeBronze int) string {
	return "tictactoe:matchmake:" + strconv.Itoa(turnTimeSec) + ":" + string(variant) + ":" + strconv.Itoa(stakeBronze)
}

func statusFromEngineResult(res gameengine.MoveResult) (status, winner string) {
	switch res.State.Status {
	case "won":
		winner = res.State.Winner
		switch winner {
		case "x":
			return gameStatusXWon, winner
		case "o":
			return gameStatusOWon, winner
		case "t":
			return gameStatusTWon, winner
		case "s":
			return gameStatusSWon, winner
		default:
			return gameStatusXWon, winner
		}
	case "draw":
		return gameStatusDraw, ""
	default:
		return gameStatusActive, ""
	}
}

func engineStateFromRedis(m map[string]string, cfg gameengine.Config) gameengine.State {
	board := parseBoard(m["board"], cfg.GridSize)
	if cfg.Variant == gameengine.VariantUltimate && len(board) != 81 {
		board = parseBoard(m["board"], 9)
		if len(board) != 81 {
			board = make([]string, 81)
		}
	}
	st := gameengine.State{
		Board:     board,
		Turn:      m["turn"],
		Status:    "active",
		NextBoard: -1,
	}
	if cfg.Variant == gameengine.VariantUltimate {
		if nb, err := strconv.Atoi(m["next_board"]); err == nil {
			st.NextBoard = nb
		}
		st.MetaBoard = parseMetaBoard(m["meta_board"])
	}
	return st
}

func parseMetaBoard(s string) []string {
	if s == "" {
		return make([]string, 9)
	}
	var b []string
	if err := json.Unmarshal([]byte(s), &b); err != nil || len(b) != 9 {
		return make([]string, 9)
	}
	return b
}

func formatMetaBoard(b []string) string {
	if len(b) != 9 {
		b = make([]string, 9)
	}
	raw, _ := json.Marshal(b)
	return string(raw)
}

func markOwnerUserID(m map[string]string, mark string) string {
	if uid := m["mark_"+mark]; uid != "" {
		return uid
	}
	switch mark {
	case "x":
		return m["x_user_id"]
	case "o":
		return m["o_user_id"]
	case "t":
		return m["t_user_id"]
	case "s":
		return m["s_user_id"]
	default:
		return ""
	}
}

func gamePlayerUserIDs(m map[string]string) []string {
	seen := map[string]bool{}
	var out []string
	add := func(id string) {
		id = strings.TrimSpace(id)
		if id == "" || seen[id] {
			return
		}
		seen[id] = true
		out = append(out, id)
	}
	for _, mark := range []string{"x", "o", "t", "s"} {
		add(markOwnerUserID(m, mark))
	}
	add(m["x_user_id"])
	add(m["o_user_id"])
	add(m["t_user_id"])
	add(m["s_user_id"])
	return out
}

func humanUserIDsFromGame(m map[string]string) []uuid.UUID {
	var out []uuid.UUID
	for _, id := range gamePlayerUserIDs(m) {
		if isBot(id) {
			continue
		}
		if u, e := uuid.Parse(id); e == nil {
			out = append(out, u)
		}
	}
	return out
}

func parsePlayerIDsCSV(s string) []string {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func formatPlayerIDsCSV(ids []string) string {
	return strings.Join(ids, ",")
}

func assignMarksRandom(marks []string, playerIDs []string, shuffle func(n int, swap func(i, j int))) map[string]string {
	ids := append([]string(nil), playerIDs...)
	if shuffle != nil && len(ids) > 1 {
		shuffle(len(ids), func(i, j int) { ids[i], ids[j] = ids[j], ids[i] })
	}
	out := make(map[string]string, len(marks))
	for i, mark := range marks {
		if i < len(ids) {
			out[mark] = ids[i]
		}
	}
	return out
}

func markFieldsForRedis(assignment map[string]string) []any {
	fields := make([]any, 0, len(assignment)*4)
	for mark, uid := range assignment {
		fields = append(fields, "mark_"+mark, uid)
		switch mark {
		case "x":
			fields = append(fields, "x_user_id", uid)
		case "o":
			fields = append(fields, "o_user_id", uid)
		case "t":
			fields = append(fields, "t_user_id", uid)
		case "s":
			fields = append(fields, "s_user_id", uid)
		}
	}
	return fields
}
