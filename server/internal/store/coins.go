package store

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const dailyRewardBronze = 20

// ErrInsufficientFunds returned when user doesn't have enough balance.
var ErrInsufficientFunds = fmt.Errorf("insufficient funds")

// GetBalance returns user's balance in bronze coins.
func GetBalance(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	var balance int
	err := pool.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance)
	if err != nil {
		return 0, err
	}
	return balance, nil
}

// DeductCoins subtracts amount from user's balance. Returns ErrInsufficientFunds if not enough.
// Uses row lock to prevent races.
func DeductCoins(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, amountBronze int) error {
	if amountBronze <= 0 {
		return nil
	}
	result, err := pool.Exec(ctx,
		`UPDATE users SET balance_bronze = balance_bronze - $2, updated_at = now()
		 WHERE id = $1 AND balance_bronze >= $2`,
		userID, amountBronze,
	)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrInsufficientFunds
	}
	return nil
}

// AddCoins adds amount to user's balance.
func AddCoins(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, amountBronze int) error {
	if amountBronze <= 0 {
		return nil
	}
	_, err := pool.Exec(ctx,
		`UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now()
		 WHERE id = $1`,
		userID, amountBronze,
	)
	return err
}

// DeductCoinsTwo deducts from both users in one transaction. Returns on first failure.
func DeductCoinsTwo(ctx context.Context, pool *pgxpool.Pool, user1, user2 uuid.UUID, amountBronze int) error {
	if amountBronze <= 0 {
		return nil
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	for _, uid := range []uuid.UUID{user1, user2} {
		r, e := tx.Exec(ctx,
			`UPDATE users SET balance_bronze = balance_bronze - $2, updated_at = now()
			 WHERE id = $1 AND balance_bronze >= $2`,
			uid, amountBronze,
		)
		if e != nil {
			return e
		}
		if r.RowsAffected() == 0 {
			return ErrInsufficientFunds
		}
	}
	return tx.Commit(ctx)
}

// CanClaimDailyReward returns true if user has not claimed today (by UTC date).
func CanClaimDailyReward(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (bool, error) {
	var claimedAt *time.Time
	err := pool.QueryRow(ctx,
		`SELECT daily_reward_claimed_at FROM users WHERE id = $1`,
		userID,
	).Scan(&claimedAt)
	if err != nil {
		return false, err
	}
	if claimedAt == nil {
		return true, nil
	}
	now := time.Now().UTC()
	claimed := claimedAt.UTC()
	return now.Year() != claimed.Year() || now.YearDay() != claimed.YearDay(), nil
}

// ClaimDailyReward adds 20 bronze and sets daily_reward_claimed_at. Returns ErrAlreadyClaimed if already claimed today.
var ErrAlreadyClaimed = fmt.Errorf("daily reward already claimed today")

func ClaimDailyReward(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (newBalance int, err error) {
	can, err := CanClaimDailyReward(ctx, pool, userID)
	if err != nil {
		return 0, err
	}
	if !can {
		return 0, ErrAlreadyClaimed
	}
	row := pool.QueryRow(ctx,
		`UPDATE users SET
			balance_bronze = balance_bronze + $2,
			daily_reward_claimed_at = now(),
			updated_at = now()
		 WHERE id = $1
		 RETURNING balance_bronze`,
		userID, dailyRewardBronze,
	)
	if err := row.Scan(&newBalance); err != nil {
		return 0, err
	}
	return newBalance, nil
}

// SettleGameCoins: winner gets 2*stake, loser gets 0. On draw both get stake back.
func SettleGameCoins(ctx context.Context, pool *pgxpool.Pool, xUserID, oUserID uuid.UUID, stakeBronze int, winner string) error {
	if stakeBronze <= 0 {
		return nil
	}
	if pool == nil {
		return nil
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	switch winner {
	case "x":
		if _, e := tx.Exec(ctx, `UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now() WHERE id = $1`, xUserID, stakeBronze*2); e != nil {
			return e
		}
	case "o":
		if _, e := tx.Exec(ctx, `UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now() WHERE id = $1`, oUserID, stakeBronze*2); e != nil {
			return e
		}
	default:
		// draw — возврат обоим
		for _, uid := range []uuid.UUID{xUserID, oUserID} {
			if _, e := tx.Exec(ctx, `UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now() WHERE id = $1`, uid, stakeBronze); e != nil {
				return e
			}
		}
	}
	return tx.Commit(ctx)
}
