package store

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

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

// AddCoinsSigned меняет баланс на amountBronze (может быть отрицательным — списание).
// Не даёт балансу уйти ниже нуля при списании. Для админского начисления/списания.
func AddCoinsSigned(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, amountBronze int) error {
	if amountBronze == 0 {
		return nil
	}
	if amountBronze > 0 {
		return AddCoins(ctx, pool, userID, amountBronze)
	}
	// Списание: не ниже нуля.
	_, err := pool.Exec(ctx,
		`UPDATE users SET balance_bronze = GREATEST(0, balance_bronze + $2), updated_at = now()
		 WHERE id = $1`,
		userID, amountBronze,
	)
	return err
}

// RecordAdminCoinGrant фиксирует операцию начисления/списания монет админом (аудит).
func RecordAdminCoinGrant(ctx context.Context, pool *pgxpool.Pool, userID, adminID uuid.UUID, amountBronze int, reason string) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO admin_coin_grants (user_id, admin_id, amount_bronze, reason)
		VALUES ($1, $2, $3, $4)
	`, userID, adminID, amountBronze, reason)
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
