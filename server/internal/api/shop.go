package api

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ShopHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
	Push *WebPushSender
}

type buyBody struct {
	Code string `json:"code"`
}

func shopItemJSON(it store.ShopItemView) map[string]any {
	m := map[string]any{
		"code":         it.Code,
		"kind":         it.Kind,
		"title":        it.Title,
		"description":  it.Description,
		"price_bronze": it.PriceBronze,
		"owned":        it.Owned,
		"sort_order":   it.SortOrder,
	}
	if it.AcquiredAt != "" {
		m["acquired_at"] = it.AcquiredAt
	}
	if len(it.Payload) > 0 {
		var payload any
		if json.Unmarshal(it.Payload, &payload) == nil {
			m["payload"] = payload
		}
	}
	return m
}

// GET /api/shop
func (h *ShopHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := store.ListShopItems(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	out := make([]map[string]any, 0, len(items))
	for _, it := range items {
		out = append(out, shopItemJSON(it))
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{"items": out})
}

// POST /api/shop/buy
func (h *ShopHandler) Buy(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body buyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	code := strings.TrimSpace(body.Code)
	if code == "" {
		WriteErr(w, r, http.StatusBadRequest, "code required")
		return
	}
	result, err := store.BuyShopItem(r.Context(), h.Pool, userID, code)
	if err != nil {
		switch err {
		case store.ErrShopItemUnknown, store.ErrShopItemInactive:
			WriteErr(w, r, http.StatusBadRequest, err.Error())
		case store.ErrShopAlreadyOwned, store.ErrShopOutOfStock:
			WriteErr(w, r, http.StatusConflict, err.Error())
		case store.ErrInsufficientFunds:
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	resp := map[string]any{
		"balance_bronze": result.BalanceBronze,
		"quantity":       result.Quantity,
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

// POST /api/inventory/consume  {"code":"emoji_fire"}
func (h *ShopHandler) Consume(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body buyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	code := strings.TrimSpace(body.Code)
	if code == "" {
		WriteErr(w, r, http.StatusBadRequest, "code required")
		return
	}
	remaining, err := store.ConsumeEmoji(r.Context(), h.Pool, userID, code)
	if err != nil {
		switch err {
		case store.ErrEmojiNotOwned, store.ErrEmojiDepleted, store.ErrShopItemUnknown:
			WriteErr(w, r, http.StatusConflict, err.Error())
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"quantity": remaining})
}

// GET /api/inventory
func (h *ShopHandler) Inventory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := store.ListInventory(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	out := make([]map[string]any, 0, len(items))
	for _, it := range items {
		m := map[string]any{
			"code":        it.Code,
			"kind":        it.Kind,
			"title":       it.Title,
			"description": it.Description,
			"acquired_at": it.AcquiredAt,
			"quantity":    it.Quantity,
		}
		if len(it.Payload) > 0 {
			var payload any
			if json.Unmarshal(it.Payload, &payload) == nil {
				m["payload"] = payload
			}
		}
		out = append(out, m)
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{"items": out})
}

// GET /api/inventory/capabilities
func (h *ShopHandler) Capabilities(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	stakes, err := store.AllowedStakeBronze(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	frame, err := store.EquippedFrameForUser(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	resp := map[string]any{"allowed_stake_bronze": stakes}
	if frame != nil {
		resp["frame_color"] = frame.Color
		resp["frame_code"] = frame.Code
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(resp)
}

type giftBody struct {
	Code     string `json:"code"`
	ToUserID string `json:"to_user_id"`
}

// POST /api/inventory/sell  {"code":"coll_unicorn"}
func (h *ShopHandler) Sell(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body buyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	code := strings.TrimSpace(body.Code)
	if code == "" {
		WriteErr(w, r, http.StatusBadRequest, "code required")
		return
	}
	balance, refund, err := store.SellCollection(r.Context(), h.Pool, userID, code)
	if err != nil {
		switch err {
		case store.ErrEmojiNotOwned, store.ErrNotCollection:
			WriteErr(w, r, http.StatusConflict, err.Error())
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"balance_bronze": balance,
		"refund_bronze":  refund,
	})
}

// POST /api/inventory/gift  {"code":"coll_unicorn","to_user_id":"..."}
func (h *ShopHandler) Gift(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body giftBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	code := strings.TrimSpace(body.Code)
	toRaw := strings.TrimSpace(body.ToUserID)
	if code == "" || toRaw == "" {
		WriteErr(w, r, http.StatusBadRequest, "code and to_user_id required")
		return
	}
	toID, err := uuid.Parse(toRaw)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid to_user_id")
		return
	}
	if err := store.GiftCollection(r.Context(), h.Pool, userID, toID, code); err != nil {
		switch err {
		case store.ErrEmojiNotOwned, store.ErrNotCollection, store.ErrGiftSelf, store.ErrGiftTargetOwned:
			WriteErr(w, r, http.StatusConflict, err.Error())
		default:
			if strings.Contains(err.Error(), "not found") {
				WriteErr(w, r, http.StatusNotFound, err.Error())
				return
			}
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}

	// Сообщение получателю о подарке коллекции.
	title, emoji, animatedName, metaErr := store.GetCollectionGiftMeta(r.Context(), h.Pool, code)
	if metaErr == nil {
		chatID, chatErr := store.EnsureDirectChat(r.Context(), h.Pool, userID, toID)
		if chatErr == nil {
			body := store.EncodeGiftCollectionMessage(code, title, emoji, animatedName)
			if msg, msgErr := store.SendChatMessage(r.Context(), h.Pool, chatID, userID, body); msgErr == nil {
				if h.Hub != nil {
					item := ChatMessageItem{
						ID:           msg.ID.String(),
						ChatID:       msg.ChatID.String(),
						SenderUserID: msg.SenderUserID.String(),
						Body:         msg.Body,
						CreatedAt:    msg.CreatedAt.UTC().Format(time.RFC3339Nano),
					}
					h.Hub.PublishToUsers([]uuid.UUID{userID, toID}, map[string]any{
						"type":    "chat_message",
						"chat_id": item.ChatID,
						"message": item,
					})
					h.Hub.PublishToUsers([]uuid.UUID{userID, toID}, map[string]any{
						"type": "chat_list_changed",
					})
					// Отдельное событие получателю — бейдж на Главной/Предметах
					// даже если клиент пропустил разбор тела chat_message.
					h.Hub.PublishToUsers([]uuid.UUID{toID}, map[string]any{
						"type":          "collection_gifted",
						"code":          code,
						"title":         title,
						"emoji":         emoji,
						"animated_name": animatedName,
						"from_user_id":  userID.String(),
						"chat_id":       item.ChatID,
						"message_id":    item.ID,
					})
				}
				if h.Push != nil {
					from := pushUserLabel(r.Context(), h.Pool, userID)
					lang := i18n.LangRU
					body := i18n.Content(lang, "push.gift_collection")
					if strings.TrimSpace(title) != "" {
						body = i18n.Contentf(lang, "push.gift_collection_named", map[string]string{"title": strings.TrimSpace(title)})
					}
					h.Push.NotifyUsers([]uuid.UUID{toID}, store.WebPushCategoryRewards, PushPayload{
						Title: from,
						Body:  body,
						URL:   "/inventory",
						Tag:   "reward_gift_" + code,
					})
				}
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

// GET /api/inventory/collections?user_id=
func (h *ShopHandler) CollectionsShowcase(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	_, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	raw := strings.TrimSpace(r.URL.Query().Get("user_id"))
	if raw == "" {
		WriteErr(w, r, http.StatusBadRequest, "user_id required")
		return
	}
	targetID, err := uuid.Parse(raw)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	items, err := store.ListCollections(r.Context(), h.Pool, targetID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	out := make([]map[string]any, 0, len(items))
	for _, it := range items {
		m := map[string]any{
			"code":        it.Code,
			"kind":        it.Kind,
			"title":       it.Title,
			"description": it.Description,
			"acquired_at": it.AcquiredAt,
			"quantity":    it.Quantity,
		}
		if len(it.Payload) > 0 {
			var payload any
			if json.Unmarshal(it.Payload, &payload) == nil {
				m["payload"] = payload
			}
		}
		out = append(out, m)
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{"items": out})
}

// GET /api/inventory/collection-income
func (h *ShopHandler) CollectionIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	info, err := store.GetCollectionIncomeInfo(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	resp := map[string]any{
		"available":        info.Available,
		"amount_bronze":    info.AmountBronze,
		"items_bronze":     info.ItemsBronze,
		"set_bonus_bronze": info.SetBonusBronze,
		"completed_sets":   info.CompletedSets,
		"owned_count":      info.OwnedCount,
	}
	if info.NextClaimAt != nil {
		resp["next_claim_at"] = *info.NextClaimAt
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(resp)
}

// POST /api/inventory/claim-collection-income
func (h *ShopHandler) ClaimCollectionIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	balance, amount, err := store.ClaimCollectionIncome(r.Context(), h.Pool, userID)
	if err != nil {
		switch err {
		case store.ErrIncomeNotReady, store.ErrNoCollections:
			WriteErr(w, r, http.StatusConflict, err.Error())
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"balance_bronze": balance,
		"amount_bronze":  amount,
	})
}
