package store

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const GameTypeTicTacToe = "tictactoe"

// UserGameSettings — сохранённая конфигурация создания игры.
type UserGameSettings struct {
	GameType             string
	TurnTimeSec          int
	GridSize             int
	Variant              string
	SwapRule             bool
	FirstMoveRestriction bool
	StakeBronze          int
	UpdatedAt            time.Time
}

func DefaultUserGameSettings(gameType string) UserGameSettings {
	if gameType == "" {
		gameType = GameTypeTicTacToe
	}
	return UserGameSettings{
		GameType:             gameType,
		TurnTimeSec:          0,
		GridSize:             3,
		Variant:              "classic",
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          1,
	}
}

// GetUserGameSettings возвращает настройки или дефолты, если строки ещё нет.
func GetUserGameSettings(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, gameType string) (UserGameSettings, error) {
	if gameType == "" {
		gameType = GameTypeTicTacToe
	}
	var s UserGameSettings
	err := pool.QueryRow(ctx, `
		SELECT game_type, turn_time_sec, grid_size, COALESCE(variant, 'classic'),
		       swap_rule, first_move_restriction, stake_bronze, updated_at
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
	err := pool.QueryRow(ctx, `
		INSERT INTO user_game_settings (
			user_id, game_type, turn_time_sec, grid_size, variant,
			swap_rule, first_move_restriction, stake_bronze, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now())
		ON CONFLICT (user_id, game_type) DO UPDATE SET
			turn_time_sec = EXCLUDED.turn_time_sec,
			grid_size = EXCLUDED.grid_size,
			variant = EXCLUDED.variant,
			swap_rule = EXCLUDED.swap_rule,
			first_move_restriction = EXCLUDED.first_move_restriction,
			stake_bronze = EXCLUDED.stake_bronze,
			updated_at = now()
		RETURNING game_type, turn_time_sec, grid_size, COALESCE(variant, 'classic'),
		          swap_rule, first_move_restriction, stake_bronze, updated_at
	`, userID, s.GameType, s.TurnTimeSec, s.GridSize, s.Variant, s.SwapRule, s.FirstMoveRestriction, s.StakeBronze).Scan(
		&s.GameType,
		&s.TurnTimeSec,
		&s.GridSize,
		&s.Variant,
		&s.SwapRule,
		&s.FirstMoveRestriction,
		&s.StakeBronze,
		&s.UpdatedAt,
	)
	return s, err
}
