package store

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	GameTypeTicTacToe  = "tictactoe"
	GameTypeDurak      = "durak"
	GameTypeBattleship = "battleship"
	GameTypePoker      = "poker"
	GameTypeUno        = "uno"
	GameTypeNardy      = "nardy"
	GameTypeCheckers   = "checkers"
	GameTypeChess      = "chess"
)

// UserGameSettings — сохранённая конфигурация создания игры (на game_type).
type UserGameSettings struct {
	GameType             string
	TurnTimeSec          int
	GridSize             int
	Variant              string
	SwapRule             bool
	FirstMoveRestriction bool
	StakeBronze          int
	// Дурак (для tictactoe — дефолты, клиент игнорит).
	DeckSize   int
	MaxPlayers int
	GameMode   string
	UpdatedAt  time.Time
}

func DefaultUserGameSettings(gameType string) UserGameSettings {
	if gameType == "" {
		gameType = GameTypeTicTacToe
	}
	s := UserGameSettings{
		GameType:             gameType,
		TurnTimeSec:          0,
		GridSize:             3,
		Variant:              "classic",
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          2,
		DeckSize:             36,
		MaxPlayers:           2,
		GameMode:             "podkidnoi",
	}
	if gameType == GameTypeDurak {
		s.TurnTimeSec = 60
		s.Variant = "podkidnoi"
		s.GameMode = "podkidnoi"
	}
	if gameType == GameTypeBattleship {
		s.TurnTimeSec = 60
		s.GridSize = 10
		s.Variant = "classic"
		s.FirstMoveRestriction = false
	}
	if gameType == GameTypePoker {
		s.TurnTimeSec = 60
		s.MaxPlayers = 2
		s.GameMode = "holdem"
		s.Variant = "holdem"
	}
	if gameType == GameTypeUno {
		s.TurnTimeSec = 60
		s.MaxPlayers = 2
		s.GameMode = "classic"
		s.Variant = "classic"
	}
	if gameType == GameTypeNardy {
		s.TurnTimeSec = 60
		s.MaxPlayers = 2
		s.GameMode = "short"
		s.Variant = "short"
	}
	if gameType == GameTypeCheckers {
		s.TurnTimeSec = 60
		s.MaxPlayers = 2
		s.GameMode = "russian"
		s.Variant = "russian"
	}
	if gameType == GameTypeChess {
		s.TurnTimeSec = 60
		s.MaxPlayers = 2
		s.GameMode = "classic"
		s.Variant = "classic"
		s.GridSize = 8
	}
	return s
}

// GetUserGameSettings возвращает настройки или дефолты, если строки ещё нет.
func GetUserGameSettings(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, gameType string) (UserGameSettings, error) {
	if gameType == "" {
		gameType = GameTypeTicTacToe
	}
	var s UserGameSettings
	err := pool.QueryRow(ctx, `
		SELECT game_type, turn_time_sec, grid_size, COALESCE(variant, 'classic'),
		       swap_rule, first_move_restriction, stake_bronze,
		       COALESCE(deck_size, 36), COALESCE(max_players, 2),
		       COALESCE(NULLIF(game_mode, ''), 'podkidnoi'),
		       updated_at
		FROM user_game_settings
		WHERE user_id = $1 AND game_type = $2
	`, userID, gameType).Scan(
		&s.GameType,
		&s.TurnTimeSec,
		&s.GridSize,
		&s.Variant,
		&s.SwapRule,
		&s.FirstMoveRestriction,
		&s.StakeBronze,
		&s.DeckSize,
		&s.MaxPlayers,
		&s.GameMode,
		&s.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return DefaultUserGameSettings(gameType), nil
	}
	if err != nil {
		return UserGameSettings{}, err
	}
	if s.Variant == "" {
		s.Variant = "classic"
	}
	if s.DeckSize <= 0 {
		s.DeckSize = 36
	}
	if s.MaxPlayers <= 0 {
		s.MaxPlayers = 2
	}
	if s.GameMode == "" {
		s.GameMode = "podkidnoi"
	}
	return s, nil
}

// UpsertUserGameSettings сохраняет конфигурацию игры.
func UpsertUserGameSettings(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, s UserGameSettings) (UserGameSettings, error) {
	if s.GameType == "" {
		s.GameType = GameTypeTicTacToe
	}
	if s.Variant == "" {
		s.Variant = "classic"
	}
	if s.DeckSize <= 0 {
		s.DeckSize = 36
	}
	if s.MaxPlayers <= 0 {
		s.MaxPlayers = 2
	}
	if s.GameMode == "" {
		s.GameMode = "podkidnoi"
	}
	err := pool.QueryRow(ctx, `
		INSERT INTO user_game_settings (
			user_id, game_type, turn_time_sec, grid_size, variant,
			swap_rule, first_move_restriction, stake_bronze,
			deck_size, max_players, game_mode, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now())
		ON CONFLICT (user_id, game_type) DO UPDATE SET
			turn_time_sec = EXCLUDED.turn_time_sec,
			grid_size = EXCLUDED.grid_size,
			variant = EXCLUDED.variant,
			swap_rule = EXCLUDED.swap_rule,
			first_move_restriction = EXCLUDED.first_move_restriction,
			stake_bronze = EXCLUDED.stake_bronze,
			deck_size = EXCLUDED.deck_size,
			max_players = EXCLUDED.max_players,
			game_mode = EXCLUDED.game_mode,
			updated_at = now()
		RETURNING game_type, turn_time_sec, grid_size, COALESCE(variant, 'classic'),
		          swap_rule, first_move_restriction, stake_bronze,
		          COALESCE(deck_size, 36), COALESCE(max_players, 2),
		          COALESCE(NULLIF(game_mode, ''), 'podkidnoi'),
		          updated_at
	`, userID, s.GameType, s.TurnTimeSec, s.GridSize, s.Variant, s.SwapRule, s.FirstMoveRestriction, s.StakeBronze,
		s.DeckSize, s.MaxPlayers, s.GameMode).Scan(
		&s.GameType,
		&s.TurnTimeSec,
		&s.GridSize,
		&s.Variant,
		&s.SwapRule,
		&s.FirstMoveRestriction,
		&s.StakeBronze,
		&s.DeckSize,
		&s.MaxPlayers,
		&s.GameMode,
		&s.UpdatedAt,
	)
	return s, err
}
