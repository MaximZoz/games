package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// GameResult — зафиксированный результат завершённой партии.
type GameResult struct {
	GameID        string
	GameType      string
	XUserID       uuid.UUID
	OUserID       uuid.UUID
	WinnerUserID  *uuid.UUID // nil — ничья
	Result        string     // 'x_won' | 'o_won' | 'draw'
	FinishReason  string     // 'normal' | 'forfeit' | 'timeout' | 'draw_agreement'
	GridSize      int
	StakeBronze   int
	DurationSec   int
	AgainstBot    bool
}

// GameStats — агрегированная статистика игрока.
type GameStats struct {
	Wins             int `json:"wins"`
	Draws            int `json:"draws"`
	Losses           int `json:"losses"`
	TotalPlayed      int `json:"total_played"`
	TotalDurationSec int `json:"total_duration_sec"`
}

// WinRate возвращает долю побед [0..1]; при отсутствии игр — 0.
func (s GameStats) WinRate() float64 {
	if s.TotalPlayed <= 0 {
		return 0
	}
	return float64(s.Wins) / float64(s.TotalPlayed)
}

// OpponentStat — счёт между игроком и конкретным соперником.
type OpponentStat struct {
	OpponentID    uuid.UUID `json:"opponent_id"`
	DisplayName   string    `json:"display_name"`
	Won           int       `json:"won"`
	Drawn         int       `json:"drawn"`
	Lost          int       `json:"lost"`
	TotalDuration int       `json:"-"`
}

// GameTypeScore — счёт head-to-head по одному типу игры.
type GameTypeScore struct {
	GameType string `json:"game_type"`
	Won      int    `json:"won"`
	Drawn    int    `json:"drawn"`
	Lost     int    `json:"lost"`
}

// GameTypeStats — статистика игрока по одному типу игры (для экрана статистики).
type GameTypeStats struct {
	GameType         string         `json:"game_type"`
	Won              int            `json:"won"`
	Drawn            int            `json:"drawn"`
	Lost             int            `json:"lost"`
	TotalDurationSec int            `json:"total_duration_sec"`
	TopWon           []OpponentStat `json:"top_won"`
	TopDrawn         []OpponentStat `json:"top_drawn"`
	TopLost          []OpponentStat `json:"top_lost"`
}

// HeadToHead — счёт между двумя игроками с разбивкой по играм.
type HeadToHead struct {
	OpponentID  uuid.UUID       `json:"opponent_id"`
	DisplayName string          `json:"display_name"`
	Won         int             `json:"won"`
	Drawn       int             `json:"drawn"`
	Lost        int             `json:"lost"`
	Games       []GameTypeScore `json:"games"`
}

// RecordGameResult сохраняет результат завершённой партии.
func RecordGameResult(ctx context.Context, pool *pgxpool.Pool, r GameResult) error {
	gameType := r.GameType
	if gameType == "" {
		gameType = "tictactoe"
	}
	finishReason := r.FinishReason
	if finishReason == "" {
		finishReason = "normal"
	}
	_, err := pool.Exec(ctx, `
		INSERT INTO game_results
			(game_id, game_type, x_user_id, o_user_id, winner_user_id,
			 result, finish_reason, grid_size, stake_bronze, duration_sec, against_bot)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`, r.GameID, gameType, r.XUserID, r.OUserID, r.WinnerUserID,
		r.Result, finishReason, r.GridSize, r.StakeBronze, r.DurationSec, r.AgainstBot)
	return err
}

// GetGameStats возвращает агрегированную статистику игрока (как по X, так и по O).
// Учитываются только партии с двумя живыми людьми-участниками (не SET NULL при удалении).
func GetGameStats(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (GameStats, error) {
	var s GameStats
	// Один запрос считает победы/ничьи/поражения и суммарную длительность.
	// Победа = winner_user_id = $1; поражение = есть победитель, но не $1; ничья = winner_user_id IS NULL.
	err := pool.QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE winner_user_id = $1)::int                          AS wins,
			COUNT(*) FILTER (WHERE winner_user_id IS NULL)::int                       AS draws,
			COUNT(*) FILTER (WHERE winner_user_id IS NOT NULL AND winner_user_id <> $1)::int AS losses,
			COUNT(*)::int                                                              AS total_played,
			COALESCE(SUM(duration_sec), 0)::int                                        AS total_duration
		FROM game_results
		WHERE (x_user_id = $1 OR o_user_id = $1)
		  AND x_user_id IS NOT NULL
		  AND o_user_id IS NOT NULL
	`, userID).Scan(&s.Wins, &s.Draws, &s.Losses, &s.TotalPlayed, &s.TotalDurationSec)
	if err != nil {
		return GameStats{}, err
	}
	return s, nil
}

// GetGameStatsByType — статистика игрока с разбивкой по типу игры.
func GetGameStatsByType(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]GameTypeStats, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			COALESCE(NULLIF(game_type, ''), 'tictactoe') AS game_type,
			COUNT(*) FILTER (WHERE winner_user_id = $1)::int                          AS wins,
			COUNT(*) FILTER (WHERE winner_user_id IS NULL)::int                       AS draws,
			COUNT(*) FILTER (WHERE winner_user_id IS NOT NULL AND winner_user_id <> $1)::int AS losses,
			COALESCE(SUM(duration_sec), 0)::int                                        AS total_duration
		FROM game_results
		WHERE (x_user_id = $1 OR o_user_id = $1)
		  AND x_user_id IS NOT NULL
		  AND o_user_id IS NOT NULL
		GROUP BY 1
		ORDER BY 1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := make([]GameTypeStats, 0)
	for rows.Next() {
		var g GameTypeStats
		if err := rows.Scan(&g.GameType, &g.Won, &g.Drawn, &g.Lost, &g.TotalDurationSec); err != nil {
			return nil, err
		}
		if g.Won == 0 && g.Drawn == 0 && g.Lost == 0 {
			continue
		}
		g.TopWon = []OpponentStat{}
		g.TopDrawn = []OpponentStat{}
		g.TopLost = []OpponentStat{}
		out = append(out, g)
	}
	return out, rows.Err()
}

// GetHeadToHead возвращает счёт between userID и opponentID (только живые PvP, без ботов),
// с разбивкой по типу игры.
func GetHeadToHead(ctx context.Context, pool *pgxpool.Pool, userID, opponentID uuid.UUID) (HeadToHead, error) {
	h := HeadToHead{
		OpponentID: opponentID,
		Games:      []GameTypeScore{},
	}
	_ = pool.QueryRow(ctx, `SELECT COALESCE(display_name, '') FROM users WHERE id = $1`, opponentID).Scan(&h.DisplayName)

	rows, err := pool.Query(ctx, `
		SELECT
			COALESCE(NULLIF(game_type, ''), 'tictactoe') AS game_type,
			COUNT(*) FILTER (WHERE winner_user_id = $1)::int                          AS won,
			COUNT(*) FILTER (WHERE winner_user_id IS NULL)::int                       AS drawn,
			COUNT(*) FILTER (WHERE winner_user_id = $2)::int                          AS lost
		FROM game_results
		WHERE NOT against_bot
		  AND ((x_user_id = $1 AND o_user_id = $2) OR (x_user_id = $2 AND o_user_id = $1))
		GROUP BY 1
		ORDER BY 1
	`, userID, opponentID)
	if err != nil {
		return HeadToHead{}, err
	}
	defer rows.Close()

	for rows.Next() {
		var g GameTypeScore
		if err := rows.Scan(&g.GameType, &g.Won, &g.Drawn, &g.Lost); err != nil {
			return HeadToHead{}, err
		}
		if g.Won == 0 && g.Drawn == 0 && g.Lost == 0 {
			continue
		}
		h.Games = append(h.Games, g)
		h.Won += g.Won
		h.Drawn += g.Drawn
		h.Lost += g.Lost
	}
	if err := rows.Err(); err != nil {
		return HeadToHead{}, err
	}
	return h, nil
}

// GetTopOpponents возвращает соперников, отсортированных по указанному критерию.
// metric: "won" | "drawn" | "lost". В список попадают только с метрикой > 0.
// gameType пустой — по всем играм; иначе фильтр по типу.
func GetTopOpponents(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, metric string, limit int, gameType string) ([]OpponentStat, error) {
	if limit <= 0 || limit > 50 {
		limit = 10
	}
	// Соперник = «другой» участник партии (NOT against_bot, оба живых человека).
	rows, err := pool.Query(ctx, `
		WITH pairs AS (
			SELECT
				CASE WHEN x_user_id = $1 THEN o_user_id ELSE x_user_id END AS opponent_id,
				winner_user_id
			FROM game_results
			WHERE NOT against_bot
			  AND x_user_id IS NOT NULL
			  AND o_user_id IS NOT NULL
			  AND (x_user_id = $1 OR o_user_id = $1)
			  AND ($2 = '' OR COALESCE(NULLIF(game_type, ''), 'tictactoe') = $2)
		)
		SELECT
			opponent_id,
			COUNT(*) FILTER (WHERE winner_user_id = $1)::int        AS won,
			COUNT(*) FILTER (WHERE winner_user_id IS NULL)::int     AS drawn,
			COUNT(*) FILTER (WHERE winner_user_id = opponent_id)::int AS lost
		FROM pairs
		GROUP BY opponent_id
	`, userID, gameType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var all []OpponentStat
	for rows.Next() {
		var os OpponentStat
		if err := rows.Scan(&os.OpponentID, &os.Won, &os.Drawn, &os.Lost); err != nil {
			return nil, err
		}
		all = append(all, os)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Только соперники с ненулевой метрикой.
	filtered := all[:0]
	switch metric {
	case "lost":
		for _, o := range all {
			if o.Lost > 0 {
				filtered = append(filtered, o)
			}
		}
		sortOpponents(filtered, func(a, b OpponentStat) bool { return a.Lost > b.Lost })
	case "drawn":
		for _, o := range all {
			if o.Drawn > 0 {
				filtered = append(filtered, o)
			}
		}
		sortOpponents(filtered, func(a, b OpponentStat) bool { return a.Drawn > b.Drawn })
	default:
		for _, o := range all {
			if o.Won > 0 {
				filtered = append(filtered, o)
			}
		}
		sortOpponents(filtered, func(a, b OpponentStat) bool { return a.Won > b.Won })
	}
	all = filtered
	if len(all) > limit {
		all = all[:limit]
	}

	// Подтягиваем display_name одним батчем.
	if len(all) > 0 {
		ids := make([]uuid.UUID, 0, len(all))
		for _, o := range all {
			ids = append(ids, o.OpponentID)
		}
		names, err := fetchDisplayNames(ctx, pool, ids)
		if err != nil {
			return nil, err
		}
		for i := range all {
			all[i].DisplayName = names[all[i].OpponentID]
		}
	}
	return all, nil
}

// fetchDisplayNames возвращает map[id]display_name для списка пользователей.
func fetchDisplayNames(ctx context.Context, pool *pgxpool.Pool, ids []uuid.UUID) (map[uuid.UUID]string, error) {
	out := make(map[uuid.UUID]string, len(ids))
	rows, err := pool.Query(ctx, `
		SELECT id, COALESCE(display_name, '') FROM users WHERE id = ANY($1)
	`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id uuid.UUID
		var name string
		if err := rows.Scan(&id, &name); err != nil {
			return nil, err
		}
		out[id] = name
	}
	return out, rows.Err()
}

// sortOpponents — простой сортировщик-замыкание, чтобы не тянуть sort как зависимость в сигнатуру.
func sortOpponents(s []OpponentStat, less func(a, b OpponentStat) bool) {
	for i := 1; i < len(s); i++ {
		for j := i; j > 0 && less(s[j], s[j-1]); j-- {
			s[j], s[j-1] = s[j-1], s[j]
		}
	}
}
