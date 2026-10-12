package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// RecentOpponent — соперник в одной из последних партий.
type RecentOpponent struct {
	OpponentID  string `json:"opponent_id,omitempty"`
	DisplayName string `json:"display_name"`
	Bot         bool   `json:"bot,omitempty"`
}

// RecentGame — одна завершённая партия с точки зрения игрока.
// Несколько строк одного стола (UNO, покер, дурак) склеены в одну карточку.
type RecentGame struct {
	GameType  string           `json:"game_type"`
	Mode      string           `json:"mode,omitempty"`
	Outcome   string           `json:"outcome"` // win | loss | draw
	CreatedAt time.Time        `json:"created_at"`
	Opponents []RecentOpponent `json:"opponents"`
}

// recentRow — сырая строка game_results до склейки столов.
type recentRow struct {
	GameID     string
	GameType   string
	Mode       string
	Result     string
	X          uuid.UUID
	O          uuid.UUID
	Winner     *uuid.UUID
	AgainstBot bool
	CreatedAt  time.Time
}

// recentRowWindow — сколько последних строк брать внутри одной игры и одного режима,
// чтобы после склейки столов набрать limit партий в каждом срезе.
const recentRowWindow = 60

// ListRecentGames возвращает партии для срезов «все», «игра» и «игра+режим».
// В каждом срезе не больше limit самых новых партий, включая игры с ботом.
func ListRecentGames(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, limit int) ([]RecentGame, error) {
	if limit <= 0 || limit > 20 {
		limit = 10
	}
	rows, err := pool.Query(ctx, `
		SELECT
			game_id,
			game_type,
			game_mode,
			result,
			x_user_id,
			o_user_id,
			winner_user_id,
			against_bot,
			created_at
		FROM (
			SELECT
				game_id,
				COALESCE(NULLIF(game_type, ''), 'tictactoe') AS game_type,
				COALESCE(game_mode, '') AS game_mode,
				result,
				x_user_id,
				o_user_id,
				winner_user_id,
				against_bot,
				created_at,
				ROW_NUMBER() OVER (
					PARTITION BY COALESCE(NULLIF(game_type, ''), 'tictactoe')
					ORDER BY created_at DESC
				) AS rn_type,
				ROW_NUMBER() OVER (
					PARTITION BY COALESCE(NULLIF(game_type, ''), 'tictactoe'), COALESCE(game_mode, '')
					ORDER BY created_at DESC
				) AS rn_mode
			FROM game_results
			WHERE x_user_id = $1 OR o_user_id = $1
		) recent_rows
		WHERE rn_type <= $2 OR rn_mode <= $2
		ORDER BY created_at DESC
	`, userID, recentRowWindow)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var raw []recentRow
	for rows.Next() {
		var r recentRow
		var xID, oID *uuid.UUID
		if err := rows.Scan(&r.GameID, &r.GameType, &r.Mode, &r.Result, &xID, &oID, &r.Winner, &r.AgainstBot, &r.CreatedAt); err != nil {
			return nil, err
		}
		if xID != nil {
			r.X = *xID
		}
		if oID != nil {
			r.O = *oID
		}
		raw = append(raw, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	games := pickRecentBuckets(groupRecentGames(userID, raw, len(raw)+1), limit)
	if err := fillRecentNames(ctx, pool, games); err != nil {
		return nil, err
	}
	return games, nil
}

// recentGroupKey склеивает строки одного стола: gameID и gameID:<соперник>.
func recentGroupKey(gameID string) string {
	if i := strings.IndexByte(gameID, ':'); i > 0 {
		return gameID[:i]
	}
	return gameID
}

func groupRecentGames(userID uuid.UUID, rows []recentRow, limit int) []RecentGame {
	if limit <= 0 {
		limit = 10
	}
	order := make([]string, 0, limit)
	byKey := map[string][]recentRow{}
	for _, r := range rows {
		key := recentGroupKey(r.GameID)
		if _, ok := byKey[key]; !ok {
			if len(order) >= limit {
				continue
			}
			order = append(order, key)
		}
		byKey[key] = append(byKey[key], r)
	}
	out := make([]RecentGame, 0, len(order))
	for _, key := range order {
		group := byKey[key]
		if len(group) == 0 {
			continue
		}
		newest := group[0]
		game := RecentGame{
			GameType:  newest.GameType,
			Mode:      newest.Mode,
			Outcome:   recentOutcome(userID, group),
			CreatedAt: newest.CreatedAt,
			Opponents: recentOpponents(userID, group),
		}
		out = append(out, game)
	}
	return out
}

// pickRecentBuckets оставляет последние n партий в целом, по каждой игре
// и по каждой паре игра+режим. Список уже отсортирован от новых к старым.
func pickRecentBuckets(games []RecentGame, n int) []RecentGame {
	if n <= 0 {
		n = 10
	}
	all := 0
	byType := map[string]int{}
	byMode := map[string]int{}
	out := make([]RecentGame, 0)
	for _, g := range games {
		typeKey := g.GameType
		modeKey := typeKey + "\x00" + g.Mode
		if all < n || byType[typeKey] < n || byMode[modeKey] < n {
			out = append(out, g)
		}
		all++
		byType[typeKey]++
		byMode[modeKey]++
	}
	return out
}

func recentOutcome(userID uuid.UUID, rows []recentRow) string {
	loss := false
	for _, r := range rows {
		switch rowOutcome(userID, r) {
		case "win":
			return "win"
		case "loss":
			loss = true
		}
	}
	if loss {
		return "loss"
	}
	return "draw"
}

// rowOutcome учитывает и живого победителя, и бота: у бота нет UUID,
// победа бота записана как x_won/o_won при пустом слоте.
func rowOutcome(userID uuid.UUID, r recentRow) string {
	switch r.Result {
	case "x_won":
		if r.X == userID {
			return "win"
		}
		return "loss"
	case "o_won":
		if r.O == userID {
			return "win"
		}
		return "loss"
	default:
		if r.Winner != nil && *r.Winner == userID {
			return "win"
		}
		if r.Winner != nil && *r.Winner != uuid.Nil {
			return "loss"
		}
		return "draw"
	}
}

func recentOpponents(userID uuid.UUID, rows []recentRow) []RecentOpponent {
	var out []RecentOpponent
	seen := map[uuid.UUID]bool{}
	bot := false
	for _, r := range rows {
		other := r.O
		if r.X != userID {
			other = r.X
		}
		if other == uuid.Nil || other == userID {
			if r.AgainstBot {
				bot = true
			}
			continue
		}
		if seen[other] {
			continue
		}
		seen[other] = true
		out = append(out, RecentOpponent{OpponentID: other.String()})
	}
	if bot {
		out = append(out, RecentOpponent{Bot: true, DisplayName: "Бот"})
	}
	if out == nil {
		out = []RecentOpponent{}
	}
	return out
}

func fillRecentNames(ctx context.Context, pool *pgxpool.Pool, games []RecentGame) error {
	ids := make([]uuid.UUID, 0)
	seen := map[uuid.UUID]bool{}
	for _, g := range games {
		for _, o := range g.Opponents {
			if o.Bot || o.OpponentID == "" {
				continue
			}
			id, err := uuid.Parse(o.OpponentID)
			if err != nil || seen[id] {
				continue
			}
			seen[id] = true
			ids = append(ids, id)
		}
	}
	if len(ids) == 0 {
		return nil
	}
	names, err := fetchDisplayNames(ctx, pool, ids)
	if err != nil {
		return err
	}
	for gi := range games {
		for oi := range games[gi].Opponents {
			o := &games[gi].Opponents[oi]
			if o.Bot || o.OpponentID == "" {
				continue
			}
			id, err := uuid.Parse(o.OpponentID)
			if err != nil {
				continue
			}
			o.DisplayName = names[id]
		}
	}
	return nil
}
