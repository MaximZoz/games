package store

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrInsufficientFunds returned when user doesn't have enough balance.
var ErrInsufficientFunds = fmt.Errorf("insufficient funds")

// Ошибки админского начисления с «Забрать».
var (
	ErrAdminGrantNotFound = errors.New("admin coin grant not found")
	ErrAdminGrantClaimed  = errors.New("admin coin grant already claimed")
	ErrAdminGrantInvalid  = errors.New("admin coin grant invalid")
)

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
// Для мгновенного списания (amount < 0) сразу ставит claimed_at = now().
func RecordAdminCoinGrant(ctx context.Context, pool *pgxpool.Pool, userID, adminID uuid.UUID, amountBronze int, reason string) (uuid.UUID, error) {
	var id uuid.UUID
	err := pool.QueryRow(ctx, `
		INSERT INTO admin_coin_grants (user_id, admin_id, amount_bronze, reason, claimed_at)
		VALUES (
			$1, $2, $3, $4,
			CASE WHEN $3 < 0 THEN now() ELSE NULL END
		)
		RETURNING id
	`, userID, adminID, amountBronze, reason).Scan(&id)
	return id, err
}

// AttachAdminCoinGrantMessage привязывает сообщение чата к отложенному начислению.
func AttachAdminCoinGrantMessage(ctx context.Context, pool *pgxpool.Pool, grantID, messageID uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		UPDATE admin_coin_grants
		SET chat_message_id = $2
		WHERE id = $1
	`, grantID, messageID)
	return err
}

// ClaimAdminCoinGrantResult — итог «Забрать» по карточке поддержки.
type ClaimAdminCoinGrantResult struct {
	AmountBronze  int
	BalanceBronze int
	MessageID     *uuid.UUID
	MessageBody   string
	ChatID        *uuid.UUID
}

// ClaimAdminCoinGrant зачисляет отложенные монеты и помечает карточку claimed.
func ClaimAdminCoinGrant(ctx context.Context, pool *pgxpool.Pool, userID, grantID uuid.UUID) (ClaimAdminCoinGrantResult, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}
	defer tx.Rollback(ctx)

	var amount int
	var reason string
	var claimedAt *string
	var messageID *uuid.UUID
	err = tx.QueryRow(ctx, `
		SELECT amount_bronze, reason, claimed_at::text, chat_message_id
		FROM admin_coin_grants
		WHERE id = $1 AND user_id = $2
		FOR UPDATE
	`, grantID, userID).Scan(&amount, &reason, &claimedAt, &messageID)
	if err == pgx.ErrNoRows {
		return ClaimAdminCoinGrantResult{}, ErrAdminGrantNotFound
	}
	if err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}
	if amount <= 0 {
		return ClaimAdminCoinGrantResult{}, ErrAdminGrantInvalid
	}
	if claimedAt != nil && *claimedAt != "" {
		return ClaimAdminCoinGrantResult{}, ErrAdminGrantClaimed
	}

	if _, err := tx.Exec(ctx, `
		UPDATE users
		SET balance_bronze = balance_bronze + $2, updated_at = now()
		WHERE id = $1
	`, userID, amount); err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE admin_coin_grants
		SET claimed_at = now()
		WHERE id = $1
	`, grantID); err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}

	newBody := EncodeCoinsCreditMessageClaimed(grantID, amount, reason)
	var chatID *uuid.UUID
	if messageID != nil {
		if _, err := tx.Exec(ctx, `
			UPDATE chat_messages
			SET body = $2, edited_at = now()
			WHERE id = $1
		`, *messageID, newBody); err != nil {
			return ClaimAdminCoinGrantResult{}, err
		}
		var cid uuid.UUID
		if err := tx.QueryRow(ctx, `
			SELECT chat_id FROM chat_messages WHERE id = $1
		`, *messageID).Scan(&cid); err == nil {
			chatID = &cid
		}
	}

	var balance int
	if err := tx.QueryRow(ctx, `
		SELECT balance_bronze FROM users WHERE id = $1
	`, userID).Scan(&balance); err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return ClaimAdminCoinGrantResult{}, err
	}
	return ClaimAdminCoinGrantResult{
		AmountBronze:  amount,
		BalanceBronze: balance,
		MessageID:     messageID,
		MessageBody:   newBody,
		ChatID:        chatID,
	}, nil
}

// DeductCoinsTwo deducts from both users in one transaction. Returns on first failure.
func DeductCoinsTwo(ctx context.Context, pool *pgxpool.Pool, user1, user2 uuid.UUID, amountBronze int) error {
	return DeductCoinsMany(ctx, pool, []uuid.UUID{user1, user2}, amountBronze)
}

// DeductCoinsMany атомарно списывает ставку у N игроков.
func DeductCoinsMany(ctx context.Context, pool *pgxpool.Pool, userIDs []uuid.UUID, amountBronze int) error {
	if amountBronze <= 0 || len(userIDs) == 0 {
		return nil
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	for _, uid := range userIDs {
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

// SettleStakePot — общий банк stake×N игроков (крестики / дурак multi).
// Ничья или пустой список победителей при isDraw: возврат stake каждому человеку.
// Иначе весь банк делится между winnerIDs (1 победитель → stake×N).
func SettleStakePot(
	ctx context.Context,
	pool *pgxpool.Pool,
	stakeBronze int,
	playerIDs []string,
	winnerIDs []string,
	isDraw bool,
	isBotFn func(string) bool,
) error {
	if stakeBronze <= 0 || pool == nil || len(playerIDs) == 0 {
		return nil
	}
	if isBotFn == nil {
		isBotFn = func(string) bool { return false }
	}
	if isDraw || len(winnerIDs) == 0 {
		for _, pid := range playerIDs {
			if isBotFn(pid) {
				continue
			}
			if u, e := uuid.Parse(pid); e == nil {
				if err := AddCoins(ctx, pool, u, stakeBronze); err != nil {
					return err
				}
			}
		}
		return nil
	}
	humans := make([]uuid.UUID, 0, len(winnerIDs))
	for _, pid := range winnerIDs {
		if isBotFn(pid) {
			continue
		}
		if u, e := uuid.Parse(pid); e == nil {
			humans = append(humans, u)
		}
	}
	if len(humans) == 0 {
		return nil
	}
	pot := stakeBronze * len(playerIDs)
	share := pot / len(humans)
	rem := pot % len(humans)
	for i, u := range humans {
		extra := share
		if i < rem {
			extra++
		}
		if err := AddCoins(ctx, pool, u, extra); err != nil {
			return err
		}
	}
	return nil
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
