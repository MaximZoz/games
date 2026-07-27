package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ShopHandler struct {
	Pool *pgxpool.Pool
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	items, err := store.ListShopItems(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body buyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	code := strings.TrimSpace(body.Code)
	if code == "" {
		http.Error(w, "code required", http.StatusBadRequest)
		return
	}
	result, err := store.BuyShopItem(r.Context(), h.Pool, userID, code)
	if err != nil {
		switch err {
		case store.ErrShopItemUnknown, store.ErrShopItemInactive:
			http.Error(w, err.Error(), http.StatusBadRequest)
		case store.ErrShopAlreadyOwned, store.ErrShopOutOfStock:
			http.Error(w, err.Error(), http.StatusConflict)
		case store.ErrInsufficientFunds:
			http.Error(w, "insufficient balance", http.StatusPaymentRequired)
		default:
			http.Error(w, "server error", http.StatusInternalServerError)
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

// GET /api/inventory
func (h *ShopHandler) Inventory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	items, err := store.ListInventory(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	stakes, err := store.AllowedStakeBronze(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	frameColor, err := store.EquippedFrameColor(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	resp := map[string]any{"allowed_stake_bronze": stakes}
	if frameColor != nil {
		resp["frame_color"] = *frameColor
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(resp)
}
