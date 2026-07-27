package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrShopItemUnknown  = errors.New("unknown shop item")
	ErrShopItemInactive = errors.New("shop item inactive")
	ErrShopOutOfStock   = errors.New("out of stock")
	ErrShopAlreadyOwned = errors.New("already owned")
	ErrStakeNotAllowed  = errors.New("stake not allowed")
	ErrEmojiNotOwned    = errors.New("emoji not owned")
	ErrEmojiDepleted    = errors.New("emoji depleted")
	ErrNotCollection    = errors.New("not a collection item")
	ErrGiftSelf         = errors.New("cannot gift to self")
	ErrGiftTargetOwned  = errors.New("target already owns item")
	ErrIncomeNotReady   = errors.New("collection income not ready")
	ErrNoCollections    = errors.New("no collections")
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
	Quantity    int
}

type BuyResult struct {
	BalanceBronze int
	Quantity      int
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
		       to_char(u.acquired_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
		       u.quantity
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
		if err := rows.Scan(&it.Code, &it.Kind, &it.Title, &it.Description, &payload, &it.AcquiredAt, &it.Quantity); err != nil {
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

// BuyShopItem purchases an item: deduct coins and add inventory.
// emoji_pack: выдаёт все смайлики пака по uses_each (по умолчанию 10).
func BuyShopItem(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (*BuyResult, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var price int
	var kind string
	var payload []byte
	var active bool
	err = tx.QueryRow(ctx, `
		SELECT price_bronze, kind, payload, active
		FROM shop_items
		WHERE code = $1
		FOR UPDATE`, code).Scan(&price, &kind, &payload, &active)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrShopItemUnknown
		}
		return nil, err
	}
	if !active {
		return nil, ErrShopItemInactive
	}

	var owned bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM user_inventory WHERE user_id = $1 AND item_code = $2
		)`, userID, code).Scan(&owned); err != nil {
		return nil, err
	}
	// Смайлики можно докупать (стекируются по quantity); рамки/ставки — один раз.
	if owned && kind != "emoji" {
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

	qty := 1
	switch kind {
	case "emoji":
		qty = 10
		var meta map[string]any
		if json.Unmarshal(payload, &meta) == nil {
			if u, ok := meta["uses"].(float64); ok && int(u) > 0 {
				qty = int(u)
			}
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_inventory (user_id, item_code, quantity)
			VALUES ($1, $2, $3)
			ON CONFLICT (user_id, item_code) DO UPDATE
			SET quantity = user_inventory.quantity + EXCLUDED.quantity`,
			userID, code, qty); err != nil {
			return nil, err
		}
	case "emoji_pack":
		var pack struct {
			UsesEach int      `json:"uses_each"`
			Emojis   []string `json:"emojis"`
		}
		if err := json.Unmarshal(payload, &pack); err != nil {
			return nil, err
		}
		uses := pack.UsesEach
		if uses <= 0 {
			uses = 10
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_inventory (user_id, item_code, quantity)
			VALUES ($1, $2, 1)`, userID, code); err != nil {
			return nil, err
		}
		for _, emojiCode := range pack.Emojis {
			emojiCode = strings.TrimSpace(emojiCode)
			if emojiCode == "" {
				continue
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO user_inventory (user_id, item_code, quantity)
				VALUES ($1, $2, $3)
				ON CONFLICT (user_id, item_code) DO UPDATE
				SET quantity = EXCLUDED.quantity`, userID, emojiCode, uses); err != nil {
				return nil, err
			}
		}
		qty = uses
	default:
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_inventory (user_id, item_code, quantity)
			VALUES ($1, $2, 1)`, userID, code); err != nil {
			return nil, err
		}
	}

	var balance int
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &BuyResult{BalanceBronze: balance, Quantity: qty}, nil
}

// ConsumeEmoji uses one charge of a purchased emoji. Deletes row at 0.
func ConsumeEmoji(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (remaining int, err error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	var kind string
	var qty int
	err = tx.QueryRow(ctx, `
		SELECT s.kind, u.quantity
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND u.item_code = $2
		FOR UPDATE OF u`, userID, code).Scan(&kind, &qty)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrEmojiNotOwned
		}
		return 0, err
	}
	if kind != "emoji" {
		return 0, ErrShopItemUnknown
	}
	if qty <= 0 {
		_, _ = tx.Exec(ctx, `DELETE FROM user_inventory WHERE user_id = $1 AND item_code = $2`, userID, code)
		_ = tx.Commit(ctx)
		return 0, ErrEmojiDepleted
	}

	qty--
	if qty == 0 {
		if _, err := tx.Exec(ctx, `DELETE FROM user_inventory WHERE user_id = $1 AND item_code = $2`, userID, code); err != nil {
			return 0, err
		}
	} else {
		if _, err := tx.Exec(ctx, `
			UPDATE user_inventory SET quantity = $3
			WHERE user_id = $1 AND item_code = $2`, userID, code, qty); err != nil {
			return 0, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return 0, err
	}
	return qty, nil
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

// ListCollections returns owned collection items for a user (public showcase).
func ListCollections(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]InventoryItemView, error) {
	rows, err := pool.Query(ctx, `
		SELECT s.code, s.kind, s.title, s.description, s.payload,
		       to_char(u.acquired_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
		       u.quantity
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'collection' AND s.active = TRUE
		ORDER BY s.sort_order, u.acquired_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []InventoryItemView
	for rows.Next() {
		var it InventoryItemView
		var payload []byte
		if err := rows.Scan(
			&it.Code, &it.Kind, &it.Title, &it.Description, &payload,
			&it.AcquiredAt, &it.Quantity,
		); err != nil {
			return nil, err
		}
		it.Payload = json.RawMessage(payload)
		out = append(out, it)
	}
	return out, rows.Err()
}

// SellCollection refunds 80% of shop price and removes the item.
func SellCollection(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (balance int, refund int, err error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, 0, err
	}
	defer tx.Rollback(ctx)

	var kind string
	var price int
	err = tx.QueryRow(ctx, `
		SELECT s.kind, s.price_bronze
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND u.item_code = $2
		FOR UPDATE OF u`, userID, code).Scan(&kind, &price)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, 0, ErrEmojiNotOwned
		}
		return 0, 0, err
	}
	if kind != "collection" {
		return 0, 0, ErrNotCollection
	}
	refund = (price * 80) / 100
	if refund < 0 {
		refund = 0
	}
	if _, err := tx.Exec(ctx, `
		DELETE FROM user_inventory WHERE user_id = $1 AND item_code = $2`, userID, code); err != nil {
		return 0, 0, err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now()
		WHERE id = $1`, userID, refund); err != nil {
		return 0, 0, err
	}
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return 0, 0, err
	}
	if err := tx.Commit(ctx); err != nil {
		return 0, 0, err
	}
	return balance, refund, nil
}

// GiftCollection transfers a collection item to another user.
func GiftCollection(ctx context.Context, pool *pgxpool.Pool, fromUser, toUser uuid.UUID, code string) error {
	if fromUser == toUser {
		return ErrGiftSelf
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var kind string
	err = tx.QueryRow(ctx, `
		SELECT s.kind
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND u.item_code = $2
		FOR UPDATE OF u`, fromUser, code).Scan(&kind)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrEmojiNotOwned
		}
		return err
	}
	if kind != "collection" {
		return ErrNotCollection
	}

	var targetOwned bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM user_inventory WHERE user_id = $1 AND item_code = $2
		)`, toUser, code).Scan(&targetOwned); err != nil {
		return err
	}
	if targetOwned {
		return ErrGiftTargetOwned
	}

	// Ensure target user exists.
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)`, toUser).Scan(&exists); err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("target user not found")
	}

	if _, err := tx.Exec(ctx, `
		DELETE FROM user_inventory WHERE user_id = $1 AND item_code = $2`, fromUser, code); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO user_inventory (user_id, item_code, quantity)
		VALUES ($1, $2, 1)`, toUser, code); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

type CollectionIncomeInfo struct {
	Available       bool
	AmountBronze    int
	ItemsBronze     int
	SetBonusBronze  int
	CompletedSets   int
	NextClaimAt     *string // RFC3339 UTC, if not available
	OwnedCount      int
}

type collectionCatalogRow struct {
	Code         string
	Set          string
	WeeklyBronze int
}

func loadActiveCollectionCatalog(ctx context.Context, q interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}) ([]collectionCatalogRow, error) {
	rows, err := q.Query(ctx, `
		SELECT code,
		       COALESCE(payload->>'set', 'other'),
		       COALESCE((payload->>'weekly_bronze')::int, 0)
		FROM shop_items
		WHERE kind = 'collection' AND active = TRUE`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []collectionCatalogRow
	for rows.Next() {
		var r collectionCatalogRow
		if err := rows.Scan(&r.Code, &r.Set, &r.WeeklyBronze); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

func ownedCollectionCodes(ctx context.Context, q interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}, userID uuid.UUID) (map[string]struct{}, error) {
	rows, err := q.Query(ctx, `
		SELECT u.item_code
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'collection' AND s.active = TRUE`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	owned := map[string]struct{}{}
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err != nil {
			return nil, err
		}
		owned[code] = struct{}{}
	}
	return owned, rows.Err()
}

// calcCollectionWeeklyIncome: сумма daily по владеемым + бонус за каждую
// полностью собранную группу (= сумма daily всех предметов группы).
// Поле payload остаётся weekly_bronze (историческое имя), смысл — дневной бонус.
func calcCollectionWeeklyIncome(catalog []collectionCatalogRow, owned map[string]struct{}) (items, setBonus, ownedCount, completedSets int) {
	bySet := map[string][]collectionCatalogRow{}
	for _, r := range catalog {
		bySet[r.Set] = append(bySet[r.Set], r)
		if _, ok := owned[r.Code]; ok {
			ownedCount++
			if r.WeeklyBronze > 0 {
				items += r.WeeklyBronze
			}
		}
	}
	for _, group := range bySet {
		if len(group) == 0 {
			continue
		}
		complete := true
		sum := 0
		for _, r := range group {
			sum += r.WeeklyBronze
			if _, ok := owned[r.Code]; !ok {
				complete = false
			}
		}
		if complete {
			completedSets++
			if sum > 0 {
				setBonus += sum
			}
		}
	}
	return items, setBonus, ownedCount, completedSets
}

// GetCollectionIncomeInfo returns weekly income status.
func GetCollectionIncomeInfo(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (*CollectionIncomeInfo, error) {
	catalog, err := loadActiveCollectionCatalog(ctx, pool)
	if err != nil {
		return nil, err
	}
	owned, err := ownedCollectionCodes(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	items, setBonus, ownedCount, completedSets := calcCollectionWeeklyIncome(catalog, owned)
	total := items + setBonus
	info := &CollectionIncomeInfo{
		OwnedCount:     ownedCount,
		AmountBronze:   total,
		ItemsBronze:    items,
		SetBonusBronze: setBonus,
		CompletedSets:  completedSets,
	}
	if ownedCount == 0 || total <= 0 {
		return info, nil
	}

	var claimedAt *time.Time
	if err := pool.QueryRow(ctx, `
		SELECT collection_income_claimed_at FROM users WHERE id = $1`, userID).Scan(&claimedAt); err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	if claimedAt == nil || !utcDate(*claimedAt).Equal(utcDate(now)) {
		info.Available = true
		return info, nil
	}
	nextDay := utcDate(now).AddDate(0, 0, 1)
	next := nextDay.Format(time.RFC3339)
	info.NextClaimAt = &next
	return info, nil
}

// ClaimCollectionIncome credits weekly bronze from owned collections + set bonuses.
func ClaimCollectionIncome(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (balance int, amount int, err error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, 0, err
	}
	defer tx.Rollback(ctx)

	var claimedAt *time.Time
	if err := tx.QueryRow(ctx, `
		SELECT collection_income_claimed_at FROM users WHERE id = $1 FOR UPDATE`, userID).Scan(&claimedAt); err != nil {
		return 0, 0, err
	}
	now := time.Now().UTC()
	if claimedAt != nil && utcDate(*claimedAt).Equal(utcDate(now)) {
		return 0, 0, ErrIncomeNotReady
	}

	catalog, err := loadActiveCollectionCatalog(ctx, tx)
	if err != nil {
		return 0, 0, err
	}
	owned, err := ownedCollectionCodes(ctx, tx, userID)
	if err != nil {
		return 0, 0, err
	}
	items, setBonus, _, _ := calcCollectionWeeklyIncome(catalog, owned)
	amount = items + setBonus
	if amount <= 0 {
		return 0, 0, ErrNoCollections
	}

	if _, err := tx.Exec(ctx, `
		UPDATE users
		SET balance_bronze = balance_bronze + $2,
		    collection_income_claimed_at = $3,
		    updated_at = now()
		WHERE id = $1`, userID, amount, now); err != nil {
		return 0, 0, err
	}
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return 0, 0, err
	}
	if err := tx.Commit(ctx); err != nil {
		return 0, 0, err
	}
	return balance, amount, nil
}
