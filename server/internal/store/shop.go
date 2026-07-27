package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrShopItemUnknown   = errors.New("unknown shop item")
	ErrShopItemInactive  = errors.New("shop item inactive")
	ErrShopOutOfStock    = errors.New("out of stock")
	ErrShopAlreadyOwned  = errors.New("already owned")
	ErrStakeNotAllowed   = errors.New("stake not allowed")
)

// FreeStakeBronze — бронзовые ставки без покупки в магазине.
var FreeStakeBronze = []int{1, 10, 50}

type ShopItemView struct {
	Code           string
	Kind           string
	Title          string
	Description    string
	PriceBronze    int
	Payload        json.RawMessage
	StockRemaining *int
	Owned          bool
	SortOrder      int
}

type InventoryItemView struct {
	Code        string
	Kind        string
	Title       string
	Description string
	Payload     json.RawMessage
	AcquiredAt  string
}

type BuyResult struct {
	BalanceBronze  int
	StockRemaining *int
}

// ListShopItems returns catalog with owned flag for user.
func ListShopItems(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]ShopItemView, error) {
	rows, err := pool.Query(ctx, `
		SELECT s.code, s.kind, s.title, s.description, s.price_bronze, s.payload,
		       s.stock_remaining, s.sort_order,
		       EXISTS (
		         SELECT 1 FROM user_inventory u
		         WHERE u.user_id = $1 AND u.item_code = s.code
		       ) AS owned
		FROM shop_items s
		WHERE s.active = TRUE
		ORDER BY s.sort_order, s.code`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []ShopItemView
	for rows.Next() {
		var it ShopItemView
		var payload []byte
		if err := rows.Scan(
			&it.Code, &it.Kind, &it.Title, &it.Description, &it.PriceBronze, &payload,
			&it.StockRemaining, &it.SortOrder, &it.Owned,
		); err != nil {
			return nil, err
		}
		it.Payload = json.RawMessage(payload)
		out = append(out, it)
	}
	return out, rows.Err()
}

// ListInventory returns owned items.
func ListInventory(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]InventoryItemView, error) {
	rows, err := pool.Query(ctx, `
		SELECT s.code, s.kind, s.title, s.description, s.payload,
		       to_char(u.acquired_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1
		ORDER BY s.sort_order, u.acquired_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []InventoryItemView
	for rows.Next() {
		var it InventoryItemView
		var payload []byte
		if err := rows.Scan(&it.Code, &it.Kind, &it.Title, &it.Description, &payload, &it.AcquiredAt); err != nil {
			return nil, err
		}
		it.Payload = json.RawMessage(payload)
		out = append(out, it)
	}
	return out, rows.Err()
}

// AllowedStakeBronze returns free stakes + purchased stake_unlock values.
func AllowedStakeBronze(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]int, error) {
	rows, err := pool.Query(ctx, `
		SELECT s.payload->>'stake_bronze'
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'stake_unlock' AND s.active = TRUE`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	allowed := append([]int{}, FreeStakeBronze...)
	seen := map[int]bool{1: true, 10: true, 50: true}
	for rows.Next() {
		var raw *string
		if err := rows.Scan(&raw); err != nil {
			return nil, err
		}
		if raw == nil || *raw == "" {
			continue
		}
		var n int
		if _, err := fmt.Sscanf(*raw, "%d", &n); err != nil || n < 1 {
			continue
		}
		if !seen[n] {
			seen[n] = true
			allowed = append(allowed, n)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	// sort ascending
	for i := 0; i < len(allowed); i++ {
		for j := i + 1; j < len(allowed); j++ {
			if allowed[j] < allowed[i] {
				allowed[i], allowed[j] = allowed[j], allowed[i]
			}
		}
	}
	return allowed, nil
}

// UserMayStake reports whether stakeBronze is allowed for user.
func UserMayStake(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, stakeBronze int) (bool, error) {
	if stakeBronze < 1 {
		return false, nil
	}
	for _, s := range FreeStakeBronze {
		if s == stakeBronze {
			return true, nil
		}
	}
	var ok bool
	err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM user_inventory u
			JOIN shop_items s ON s.code = u.item_code
			WHERE u.user_id = $1
			  AND s.kind = 'stake_unlock'
			  AND s.active = TRUE
			  AND (s.payload->>'stake_bronze')::int = $2
		)`, userID, stakeBronze).Scan(&ok)
	return ok, err
}

// BuyShopItem purchases an item: deduct coins, decrease stock, add inventory.
func BuyShopItem(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (*BuyResult, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var price int
	var stock *int
	var active bool
	err = tx.QueryRow(ctx, `
		SELECT price_bronze, stock_remaining, active
		FROM shop_items
		WHERE code = $1
		FOR UPDATE`, code).Scan(&price, &stock, &active)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrShopItemUnknown
		}
		return nil, err
	}
	if !active {
		return nil, ErrShopItemInactive
	}
	if stock != nil && *stock <= 0 {
		return nil, ErrShopOutOfStock
	}

	var owned bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM user_inventory WHERE user_id = $1 AND item_code = $2
		)`, userID, code).Scan(&owned); err != nil {
		return nil, err
	}
	if owned {
		return nil, ErrShopAlreadyOwned
	}

	r, err := tx.Exec(ctx, `
		UPDATE users SET balance_bronze = balance_bronze - $2, updated_at = now()
		WHERE id = $1 AND balance_bronze >= $2`, userID, price)
	if err != nil {
		return nil, err
	}
	if r.RowsAffected() == 0 {
		return nil, ErrInsufficientFunds
	}

	if stock != nil {
		ur, err := tx.Exec(ctx, `
			UPDATE shop_items
			SET stock_remaining = stock_remaining - 1
			WHERE code = $1 AND stock_remaining > 0`, code)
		if err != nil {
			return nil, err
		}
		if ur.RowsAffected() == 0 {
			return nil, ErrShopOutOfStock
		}
		n := *stock - 1
		stock = &n
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO user_inventory (user_id, item_code) VALUES ($1, $2)`, userID, code); err != nil {
		return nil, err
	}

	var balance int
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &BuyResult{BalanceBronze: balance, StockRemaining: stock}, nil
}

// EquippedFrameColor returns payload color of the latest owned frame, if any.
func EquippedFrameColor(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (*string, error) {
	var color *string
	err := pool.QueryRow(ctx, `
		SELECT s.payload->>'color'
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'frame' AND s.active = TRUE
		ORDER BY u.acquired_at DESC
		LIMIT 1`, userID).Scan(&color)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	if color == nil || *color == "" {
		return nil, nil
	}
	return color, nil
}
