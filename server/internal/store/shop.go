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
	ErrShopItemUnknown       = errors.New("unknown shop item")
	ErrShopItemInactive      = errors.New("shop item inactive")
	ErrShopOutOfStock        = errors.New("out of stock")
	ErrShopAlreadyOwned      = errors.New("already owned")
	ErrStakeNotAllowed       = errors.New("stake not allowed")
	ErrEmojiNotOwned         = errors.New("emoji not owned")
	ErrEmojiDepleted         = errors.New("emoji depleted")
	ErrNotCollection         = errors.New("not a collection item")
	ErrGiftSelf              = errors.New("cannot gift to self")
	ErrGiftTargetOwned       = errors.New("target already owns item")
	ErrIncomeNotReady        = errors.New("collection income not ready")
	ErrNoCollections         = errors.New("no collections")
	ErrElixirNotOwned        = errors.New("elixir not owned")
	ErrElixirNotApplicable   = errors.New("elixir not applicable")
	ErrElixirWrongSet        = errors.New("elixir wrong set")
	ErrCollectionNotSellable = errors.New("collection not sellable")
)

// FreeStakeBronze — бронзовые ставки без покупки в магазине.
var FreeStakeBronze = []int{2, 10, 50}

// MinStakeBronze — минимальная ставка в играх.
const MinStakeBronze = 2

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
	// AcquiredAt — момент появления в инвентаре, если предмет уже куплен.
	AcquiredAt string
	// ConditionShift и VintageAt — эликсиры на коллекции (0 и пусто у остальных).
	ConditionShift int
	VintageAt      string
}

type InventoryItemView struct {
	Code           string
	Kind           string
	Title          string
	Description    string
	Payload        json.RawMessage
	AcquiredAt     string
	Quantity       int
	ConditionShift int
	VintageAt      string
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
		       ) AS owned,
		       COALESCE((
		         SELECT to_char(u.acquired_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
		         FROM user_inventory u
		         WHERE u.user_id = $1 AND u.item_code = s.code
		       ), ''),
		       COALESCE((
		         SELECT u.condition_shift
		         FROM user_inventory u
		         WHERE u.user_id = $1 AND u.item_code = s.code
		       ), 0),
		       COALESCE((
		         SELECT to_char(u.vintage_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
		         FROM user_inventory u
		         WHERE u.user_id = $1 AND u.item_code = s.code
		       ), '')
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
			&it.StockRemaining, &it.SortOrder, &it.Owned, &it.AcquiredAt,
			&it.ConditionShift, &it.VintageAt,
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
		       u.quantity,
		       u.condition_shift,
		       COALESCE(to_char(u.vintage_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), '')
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
		if err := rows.Scan(&it.Code, &it.Kind, &it.Title, &it.Description, &payload, &it.AcquiredAt, &it.Quantity, &it.ConditionShift, &it.VintageAt); err != nil {
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
	seen := map[int]bool{2: true, 10: true, 50: true}
	for rows.Next() {
		var raw *string
		if err := rows.Scan(&raw); err != nil {
			return nil, err
		}
		if raw == nil || *raw == "" {
			continue
		}
		var n int
		if _, err := fmt.Sscanf(*raw, "%d", &n); err != nil || n < MinStakeBronze {
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
	if stakeBronze < MinStakeBronze {
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
	if owned && kind != "emoji" && kind != "elixir" {
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
	case "elixir":
		if _, err := tx.Exec(ctx, `
			INSERT INTO user_inventory (user_id, item_code, quantity)
			VALUES ($1, $2, 1)
			ON CONFLICT (user_id, item_code) DO UPDATE
			SET quantity = user_inventory.quantity + 1`,
			userID, code); err != nil {
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

// EquippedFrame — активная рамка пользователя (лучшая из имеющихся).
type EquippedFrame struct {
	Code  string
	Color string
}

func frameRank(code string) int {
	switch code {
	case FrameGoldCode:
		return 3
	case FrameSilverCode:
		return 2
	case FrameBronzeCode:
		return 1
	default:
		return 0
	}
}

// EquippedFrameForUser returns the best owned frame (gold > silver > bronze).
// Frames may be inactive in the shop (achievement rewards) and still apply.
func EquippedFrameForUser(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (*EquippedFrame, error) {
	var code string
	var color *string
	err := pool.QueryRow(ctx, `
		SELECT s.code, s.payload->>'color'
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'frame'
		ORDER BY
			CASE s.code
				WHEN 'frame_gold' THEN 3
				WHEN 'frame_silver' THEN 2
				WHEN 'frame_bronze' THEN 1
				ELSE 0
			END DESC,
			u.acquired_at DESC
		LIMIT 1`, userID).Scan(&code, &color)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	if color == nil || *color == "" {
		return nil, nil
	}
	return &EquippedFrame{Code: code, Color: *color}, nil
}

// EquippedFrameColor returns payload color of the best owned frame, if any.
func EquippedFrameColor(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (*string, error) {
	f, err := EquippedFrameForUser(ctx, pool, userID)
	if err != nil || f == nil {
		return nil, err
	}
	c := f.Color
	return &c, nil
}

// EquippedFramesMap returns best frame per user id.
func EquippedFramesMap(ctx context.Context, pool *pgxpool.Pool, userIDs []uuid.UUID) (map[uuid.UUID]EquippedFrame, error) {
	out := make(map[uuid.UUID]EquippedFrame)
	if len(userIDs) == 0 {
		return out, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT DISTINCT ON (u.user_id)
			u.user_id, s.code, s.payload->>'color'
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = ANY($1) AND s.kind = 'frame'
		ORDER BY
			u.user_id,
			CASE s.code
				WHEN 'frame_gold' THEN 3
				WHEN 'frame_silver' THEN 2
				WHEN 'frame_bronze' THEN 1
				ELSE 0
			END DESC,
			u.acquired_at DESC
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var uid uuid.UUID
		var code string
		var color *string
		if err := rows.Scan(&uid, &code, &color); err != nil {
			return nil, err
		}
		if color == nil || *color == "" {
			continue
		}
		out[uid] = EquippedFrame{Code: code, Color: *color}
	}
	return out, rows.Err()
}

// ListCollections returns owned collection items for a user (public showcase).
func ListCollections(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]InventoryItemView, error) {
	rows, err := pool.Query(ctx, `
		SELECT s.code, s.kind, s.title, s.description, s.payload,
		       to_char(u.acquired_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
		       u.quantity,
		       u.condition_shift,
		       COALESCE(to_char(u.vintage_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), '')
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
			&it.AcquiredAt, &it.Quantity, &it.ConditionShift, &it.VintageAt,
		); err != nil {
			return nil, err
		}
		it.Payload = json.RawMessage(payload)
		out = append(out, it)
	}
	return out, rows.Err()
}

// SellCollection возвращает долю цены каталога и удаляет предмет.
// Продать можно только новое (80%) или винтаж (300%).
func SellCollection(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (balance int, refund int, err error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, 0, err
	}
	defer tx.Rollback(ctx)

	var kind string
	var price int
	var acquiredAt time.Time
	var shift int
	var vintageAt *time.Time
	err = tx.QueryRow(ctx, `
		SELECT s.kind, s.price_bronze, u.acquired_at, u.condition_shift, u.vintage_at
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND u.item_code = $2
		FOR UPDATE OF u`, userID, code).Scan(&kind, &price, &acquiredAt, &shift, &vintageAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, 0, ErrEmojiNotOwned
		}
		return 0, 0, err
	}
	if kind != "collection" {
		return 0, 0, ErrNotCollection
	}
	now := time.Now().UTC()
	cond := CollectionConditionEffective(acquiredAt, now, shift, vintageAt)
	if !CollectionCanSell(cond) {
		return 0, 0, ErrCollectionNotSellable
	}
	refund = CollectionRefundAged(price, acquiredAt, now, shift, vintageAt)
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

// GetCollectionGiftMeta returns title/emoji/animated_name for a collection item.
func GetCollectionGiftMeta(ctx context.Context, pool *pgxpool.Pool, code string) (title, emoji, animatedName string, err error) {
	var payload []byte
	err = pool.QueryRow(ctx, `
		SELECT title, payload
		FROM shop_items
		WHERE code = $1 AND kind = 'collection'`, code).Scan(&title, &payload)
	if err != nil {
		return "", "", "", err
	}
	var m map[string]any
	if len(payload) > 0 {
		_ = json.Unmarshal(payload, &m)
	}
	if m != nil {
		if v, ok := m["emoji"].(string); ok {
			emoji = v
		}
		if v, ok := m["animated_name"].(string); ok {
			animatedName = v
		}
	}
	if animatedName == "" {
		animatedName = "sparkles"
	}
	if emoji == "" {
		emoji = "🎁"
	}
	return title, emoji, animatedName, nil
}

// EncodeGiftCollectionMessage builds a chat body token for a gifted collection.
func EncodeGiftCollectionMessage(code, title, emoji, animatedName string) string {
	safe := func(s string) string {
		s = strings.ReplaceAll(s, "|", "/")
		s = strings.ReplaceAll(s, "]", "")
		return strings.TrimSpace(s)
	}
	return fmt.Sprintf("[gift_coll:%s|%s|%s|%s]",
		safe(code), safe(title), safe(emoji), safe(animatedName))
}

type CollectionIncomeInfo struct {
	Available      bool
	AmountBronze   int
	ItemsBronze    int
	SetBonusBronze int
	CompletedSets  int
	NextClaimAt    *string // RFC3339 UTC, if not available
	OwnedCount     int
}

type collectionCatalogRow struct {
	Code         string
	Set          string
	WeeklyBronze int
}

// CollectionSetBonusBronze — дневной бонус за полностью собранную группу.
func CollectionSetBonusBronze(set string) int {
	switch set {
	case "celebration", "nature":
		return 50
	case "cosmic":
		return 100
	case "adventure":
		return 200
	case "legends":
		return 500
	case "jewels":
		return 5000
	default:
		return 0
	}
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

type ownedCollectionState struct {
	Acquired time.Time
	Shift    int
	Vintage  *time.Time
}

func ownedCollectionStates(ctx context.Context, q interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}, userID uuid.UUID) (map[string]ownedCollectionState, error) {
	rows, err := q.Query(ctx, `
		SELECT u.item_code, u.acquired_at, u.condition_shift, u.vintage_at
		FROM user_inventory u
		JOIN shop_items s ON s.code = u.item_code
		WHERE u.user_id = $1 AND s.kind = 'collection' AND s.active = TRUE`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	owned := map[string]ownedCollectionState{}
	for rows.Next() {
		var code string
		var st ownedCollectionState
		if err := rows.Scan(&code, &st.Acquired, &st.Shift, &st.Vintage); err != nil {
			return nil, err
		}
		owned[code] = st
	}
	return owned, rows.Err()
}

// calcCollectionWeeklyIncome: дневной доход предметов с учётом состояния
// плюс бонус полного набора. Винтажный набор (каждый предмет винтажный)
// получает 300% бонуса. Поле payload остаётся weekly_bronze.
func calcCollectionWeeklyIncome(catalog []collectionCatalogRow, owned map[string]ownedCollectionState, now time.Time) (items, setBonus, ownedCount, completedSets int) {
	now = now.UTC()
	bySet := map[string][]collectionCatalogRow{}
	for _, r := range catalog {
		bySet[r.Set] = append(bySet[r.Set], r)
		st, ok := owned[r.Code]
		if !ok {
			continue
		}
		ownedCount++
		if r.WeeklyBronze > 0 {
			items += CollectionDailyIncomeBronze(r.WeeklyBronze, st.Acquired, now, st.Shift, st.Vintage)
		}
	}
	for set, group := range bySet {
		if len(group) == 0 {
			continue
		}
		complete := true
		allVintage := true
		for _, r := range group {
			st, ok := owned[r.Code]
			if !ok {
				complete = false
				allVintage = false
				break
			}
			if CollectionConditionEffective(st.Acquired, now, st.Shift, st.Vintage) != CollectionCondVintage {
				allVintage = false
			}
		}
		if complete {
			completedSets++
			if bonus := CollectionSetBonusAged(CollectionSetBonusBronze(set), allVintage); bonus > 0 {
				setBonus += bonus
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
	owned, err := ownedCollectionStates(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	items, setBonus, ownedCount, completedSets := calcCollectionWeeklyIncome(catalog, owned, now)
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
	owned, err := ownedCollectionStates(ctx, tx, userID)
	if err != nil {
		return 0, 0, err
	}
	items, setBonus, _, _ := calcCollectionWeeklyIncome(catalog, owned, now)
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
