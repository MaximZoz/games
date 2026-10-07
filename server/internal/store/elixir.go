package store

import (
	"context"
	"encoding/json"
	"errors"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// errInventoryMissing — строки предмета нет. Вызывающий различает эликсир и коллекцию.
var errInventoryMissing = errors.New("inventory item missing")

// ElixirApplyResult — коллекция после эликсира и остаток флакона.
type ElixirApplyResult struct {
	ConditionShift int
	VintageAt      *time.Time
	ElixirQuantity int
}

type lockedItem struct {
	code     string
	kind     string
	payload  []byte
	acquired time.Time
	shift    int
	vintage  *time.Time
	quantity int
}

// ApplyElixir тратит один эликсир на коллекцию того же набора.
func ApplyElixir(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, elixirCode, collectionCode string) (*ElixirApplyResult, error) {
	if elixirCode == "" || collectionCode == "" || elixirCode == collectionCode {
		return nil, ErrElixirNotApplicable
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Один и тот же порядок блокировок, чтобы два применения не встали в тупик.
	order := []string{elixirCode, collectionCode}
	sort.Strings(order)
	locked := map[string]lockedItem{}
	for _, code := range order {
		item, err := lockInventoryItem(ctx, tx, userID, code)
		if err != nil {
			if errors.Is(err, errInventoryMissing) {
				if code == elixirCode {
					return nil, ErrElixirNotOwned
				}
				return nil, ErrNotCollection
			}
			return nil, err
		}
		locked[code] = item
	}
	elixir := locked[elixirCode]
	collection := locked[collectionCode]
	if elixir.kind != "elixir" || elixir.quantity <= 0 {
		return nil, ErrElixirNotOwned
	}
	if collection.kind != "collection" {
		return nil, ErrNotCollection
	}
	elixirSet := payloadString(elixir.payload, "set")
	elixirEffect := payloadString(elixir.payload, "effect")
	collectionSet := payloadString(collection.payload, "set")
	if elixirSet == "" || elixirSet != collectionSet {
		return nil, ErrElixirWrongSet
	}

	now := time.Now().UTC()
	shift, vintageAt, err := PlanElixirApply(elixirEffect, collection.acquired, now, collection.shift, collection.vintage)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE user_inventory
		SET condition_shift = $3, vintage_at = $4
		WHERE user_id = $1 AND item_code = $2`,
		userID, collectionCode, shift, vintageAt); err != nil {
		return nil, err
	}

	qty := elixir.quantity - 1
	if qty == 0 {
		if _, err := tx.Exec(ctx, `
			DELETE FROM user_inventory WHERE user_id = $1 AND item_code = $2`,
			userID, elixirCode); err != nil {
			return nil, err
		}
	} else {
		if _, err := tx.Exec(ctx, `
			UPDATE user_inventory SET quantity = $3
			WHERE user_id = $1 AND item_code = $2`,
			userID, elixirCode, qty); err != nil {
			return nil, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &ElixirApplyResult{
		ConditionShift: shift,
		VintageAt:      vintageAt,
		ElixirQuantity: qty,
	}, nil
}

func lockInventoryItem(ctx context.Context, tx pgx.Tx, userID uuid.UUID, code string) (lockedItem, error) {
	var item lockedItem
	err := tx.QueryRow(ctx, `
		SELECT s.kind, s.payload, u.acquired_at, u.condition_shift, u.vintage_at, u.quantity
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND u.item_code = $2
		FOR UPDATE OF u`, userID, code).Scan(
		&item.kind, &item.payload, &item.acquired, &item.shift, &item.vintage, &item.quantity,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return lockedItem{}, errInventoryMissing
		}
		return lockedItem{}, err
	}
	item.code = code
	return item, nil
}

func payloadString(raw []byte, key string) string {
	if len(raw) == 0 {
		return ""
	}
	var m map[string]any
	if json.Unmarshal(raw, &m) != nil || m == nil {
		return ""
	}
	v, _ := m[key].(string)
	return v
}
