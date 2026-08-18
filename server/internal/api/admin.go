package api

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/applog"
	"multigames/server/internal/auth"
	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// AdminHandler обрабатывает запросы админки.
type AdminHandler struct {
	Pool        *pgxpool.Pool
	JWTSecret   []byte
	InitSecret  string // секрет для однократного создания первого админа
	LogImporter *applog.Importer
	Hub         *RealtimeHub // для WS-уведомлений админу/пользователю
	Push        *WebPushSender
}

type AdminInitRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AdminUserItem struct {
	ID           string  `json:"id"`
	Email        string  `json:"email"`
	DisplayName  *string `json:"display_name,omitempty"`
	IsAdmin      bool    `json:"is_admin"`
	IsSupport    bool    `json:"is_support"`
	IsFrozen     bool    `json:"is_frozen"`
	FrozenAt     *string `json:"frozen_at,omitempty"`
	CreatedAt    string  `json:"created_at"`
	LastSeenAt   *string `json:"last_seen_at,omitempty"`
	BalanceBronze int    `json:"balance_bronze"`
	Age          *int    `json:"age,omitempty"`
	Gender       *string `json:"gender,omitempty"`
	About        *string `json:"about,omitempty"`
	AvatarKind   string  `json:"avatar_kind,omitempty"`
	AvatarValue  *string `json:"avatar_value,omitempty"`
}

func adminUserItemFromUser(u *store.User) AdminUserItem {
	var frozenAt *string
	if u.FrozenAt != nil {
		s := u.FrozenAt.Format(time.RFC3339Nano)
		frozenAt = &s
	}
	var lastSeen *string
	if u.LastSeenAt != nil {
		s := u.LastSeenAt.Format(time.RFC3339Nano)
		lastSeen = &s
	}
	return AdminUserItem{
		ID:            u.ID.String(),
		Email:         u.Email,
		DisplayName:   u.DisplayName,
		IsAdmin:       u.IsAdmin,
		IsSupport:     u.IsSupport,
		IsFrozen:      u.IsFrozen(),
		FrozenAt:      frozenAt,
		CreatedAt:     u.CreatedAt,
		LastSeenAt:    lastSeen,
		BalanceBronze: u.BalanceBronze,
		Age:           u.Age,
		Gender:        u.Gender,
		About:         u.About,
		AvatarKind:    u.AvatarKind,
		AvatarValue:   u.AvatarValue,
	}
}

type SetAdminRequest struct {
	UserID  string `json:"user_id"`
	IsAdmin bool   `json:"is_admin"`
}

type ResetPasswordRequest struct {
	UserID      string `json:"user_id"`
	NewPassword string `json:"new_password"`
}

type DeleteUserRequest struct {
	UserID string `json:"user_id"`
}

type AdminLogItem struct {
	EventID    string                 `json:"event_id"`
	EventTime  string                 `json:"event_time"`
	Source     string                 `json:"source"`
	MethodName string                 `json:"method_name"`
	HTTPMethod *string                `json:"http_method,omitempty"`
	Path       *string                `json:"path,omitempty"`
	StatusCode *int                   `json:"status_code,omitempty"`
	DurationMS *int64                 `json:"duration_ms,omitempty"`
	UserID     *string                `json:"user_id,omitempty"`
	IP         *string                `json:"ip,omitempty"`
	UserAgent  *string                `json:"user_agent,omitempty"`
	Level      string                 `json:"level"`
	Message    *string                `json:"message,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// Init создаёт первого админа. Заголовок X-Admin-Init-Secret должен совпадать с ADMIN_INIT_SECRET.
func (h *AdminHandler) Init(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.InitSecret == "" {
		WriteErr(w, r, http.StatusForbidden, "admin init disabled")
		return
	}
	secret := r.Header.Get("X-Admin-Init-Secret")
	if secret != h.InitSecret {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	var req AdminInitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || len(req.Password) < 6 {
		WriteErr(w, r, http.StatusBadRequest, "email and password (min 6 chars) required")
		return
	}
	n, err := store.CountAdmins(r.Context(), h.Pool)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if n > 0 {
		WriteErr(w, r, http.StatusConflict, "admin already exists")
		return
	}
	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	u, err := store.CreateUser(r.Context(), h.Pool, req.Email, hash, "", nil)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique") {
			WriteErr(w, r, http.StatusConflict, "email already registered")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if err := store.SetUserAdmin(r.Context(), h.Pool, u.ID, true); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(AdminUserItem{
		ID: u.ID.String(), Email: u.Email, IsAdmin: true, CreatedAt: u.CreatedAt,
	})
}

// ListUsers возвращает постраничный список пользователей с поиском/сортировкой.
func (h *AdminHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	q := r.URL.Query()
	limit := 20
	if raw := strings.TrimSpace(q.Get("limit")); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 && n <= 200 {
			limit = n
		}
	}
	offset := 0
	if raw := strings.TrimSpace(q.Get("offset")); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n >= 0 {
			offset = n
		}
	}
	result, err := store.ListUsersPaged(r.Context(), h.Pool, store.ListUsersParams{
		Query:        strings.TrimSpace(q.Get("q")),
		Sort:         strings.TrimSpace(q.Get("sort")),
		Order:        strings.TrimSpace(q.Get("order")),
		AdminFilter:  strings.TrimSpace(q.Get("admin")),
		FrozenFilter: strings.TrimSpace(q.Get("frozen")),
		Limit:        limit,
		Offset:       offset,
	})
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	items := make([]AdminUserItem, 0, len(result.Users))
	for _, u := range result.Users {
		items = append(items, adminUserItemFromUser(u))
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"users":  items,
		"total":  result.Total,
		"limit":  limit,
		"offset": offset,
	})
}

// SetAdmin выставляет или снимает флаг админа у пользователя.
func (h *AdminHandler) SetAdmin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req SetAdminRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	if h.isSupportID(r.Context(), id) {
		WriteErr(w, r, http.StatusBadRequest, "cannot modify support account")
		return
	}
	if err := store.SetUserAdmin(r.Context(), h.Pool, id, req.IsAdmin); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// isSupportID проверяет, является ли пользователь системным support-аккаунтом.
func (h *AdminHandler) isSupportID(ctx context.Context, id uuid.UUID) bool {
	su, err := store.GetSupportUser(ctx, h.Pool)
	if err != nil || su == nil {
		return false
	}
	return su.ID == id
}

// ResetPassword сбрасывает пароль пользователю.
func (h *AdminHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if len(req.NewPassword) < 6 {
		WriteErr(w, r, http.StatusBadRequest, "new_password must be at least 6 characters")
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	hash, err := auth.HashPassword(req.NewPassword)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if err := store.SetUserPassword(r.Context(), h.Pool, id, hash); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DeleteUser отключён: удаление пользователей из админки запрещено
// (защита системного аккаунта поддержки и чужих данных).
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	WriteErr(w, r, http.StatusForbidden, "user deletion disabled")
}

// ListLogs возвращает логи, загруженные в БД из файла.
func (h *AdminHandler) ListLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			WriteErr(w, r, http.StatusBadRequest, "invalid limit")
			return
		}
		if n > 2000 {
			n = 2000
		}
		limit = n
	}

	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 0 {
			WriteErr(w, r, http.StatusBadRequest, "invalid offset")
			return
		}
		offset = n
	}

	var userID *uuid.UUID
	if raw := strings.TrimSpace(r.URL.Query().Get("user_id")); raw != "" {
		id, err := uuid.Parse(raw)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
			return
		}
		userID = &id
	}

	var source *string
	if raw := strings.TrimSpace(strings.ToLower(r.URL.Query().Get("source"))); raw != "" {
		if raw != "frontend" && raw != "backend" {
			WriteErr(w, r, http.StatusBadRequest, "invalid source")
			return
		}
		source = &raw
	}

	var methodName *string
	if raw := strings.TrimSpace(r.URL.Query().Get("method_name")); raw != "" {
		methodName = &raw
	}

	var from *time.Time
	if raw := strings.TrimSpace(r.URL.Query().Get("from")); raw != "" {
		t, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid from")
			return
		}
		utc := t.UTC()
		from = &utc
	}

	var to *time.Time
	if raw := strings.TrimSpace(r.URL.Query().Get("to")); raw != "" {
		t, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid to")
			return
		}
		utc := t.UTC()
		to = &utc
	}

	if h.LogImporter != nil {
		_ = h.LogImporter.SyncNow(r.Context())
	}

	logs, err := store.ListAppLogs(r.Context(), h.Pool, store.ListAppLogsParams{
		Limit:      limit,
		Offset:     offset,
		UserID:     userID,
		Source:     source,
		MethodName: methodName,
		From:       from,
		To:         to,
	})
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	items := make([]AdminLogItem, 0, len(logs))
	for _, item := range logs {
		var metadata map[string]interface{}
		if len(item.Metadata) > 0 {
			_ = json.Unmarshal(item.Metadata, &metadata)
		}

		items = append(items, AdminLogItem{
			EventID:    item.EventID,
			EventTime:  item.EventTime,
			Source:     item.Source,
			MethodName: item.MethodName,
			HTTPMethod: item.HTTPMethod,
			Path:       item.Path,
			StatusCode: item.StatusCode,
			DurationMS: item.DurationMS,
			UserID:     item.UserID,
			IP:         item.IP,
			UserAgent:  item.UserAgent,
			Level:      item.Level,
			Message:    item.Message,
			Metadata:   metadata,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"logs":   items,
		"limit":  limit,
		"offset": offset,
	})
}

// ClearLogs очищает таблицу app_logs. POST /api/admin/logs/clear
func (h *AdminHandler) ClearLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if err := store.TruncateAppLogs(r.Context(), h.Pool); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// FreezeUserRequest — тело запроса заморозки/разморозки.
type FreezeUserRequest struct {
	UserID  string `json:"user_id"`
	Frozen  bool   `json:"frozen"`
}

// FreezeUser замораживает/размораживает пользователя.
func (h *AdminHandler) FreezeUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req FreezeUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	currentID, _ := GetUserID(r.Context())
	if id == currentID {
		WriteErr(w, r, http.StatusBadRequest, "cannot freeze yourself")
		return
	}
	if h.isSupportID(r.Context(), id) {
		WriteErr(w, r, http.StatusBadRequest, "cannot freeze support account")
		return
	}
	if err := store.SetUserFrozen(r.Context(), h.Pool, id, req.Frozen); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	// WS-уведомление пользователю об изменении статуса.
	if h.Hub != nil {
		h.Hub.PublishToUsers([]uuid.UUID{id}, map[string]any{
			"type":   "account_frozen",
			"frozen": req.Frozen,
		})
	}
	w.WriteHeader(http.StatusNoContent)
}

// GrantCoinsRequest — тело запроса начисления/списания монет.
type GrantCoinsRequest struct {
	UserID       string `json:"user_id"`
	AmountBronze int    `json:"amount_bronze"`
	Reason       string `json:"reason"`
}

// GrantCoins начисляет (amount>0 → карточка в чате поддержки) или списывает (amount<0 сразу).
func (h *AdminHandler) GrantCoins(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req GrantCoinsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if req.AmountBronze == 0 {
		WriteErr(w, r, http.StatusBadRequest, "amount_bronze must not be 0")
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	ctx := r.Context()
	adminID, _ := GetUserID(ctx)
	reason := strings.TrimSpace(req.Reason)

	// Списание — сразу на баланс (без карточки).
	if req.AmountBronze < 0 {
		if err := store.AddCoinsSigned(ctx, h.Pool, id, req.AmountBronze); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if _, err := store.RecordAdminCoinGrant(ctx, h.Pool, id, adminID, req.AmountBronze, reason); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		balance, _ := store.GetBalance(ctx, h.Pool, id)
		if h.Hub != nil {
			h.Hub.PublishToUsers([]uuid.UUID{id}, map[string]any{
				"type": "coins_granted", "amount": req.AmountBronze, "balance": balance, "reason": reason,
			})
		}
		writeJSON(w, http.StatusOK, map[string]any{"balance_bronze": balance, "deferred": false})
		return
	}

	// Начисление — отложенное: сообщение от поддержки с кнопкой «Забрать».
	suID, ok := h.supportUserID(ctx)
	if !ok {
		WriteErr(w, r, http.StatusInternalServerError, "support user not found")
		return
	}
	grantID, err := store.RecordAdminCoinGrant(ctx, h.Pool, id, adminID, req.AmountBronze, reason)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	chatID, err := store.EnsureDirectChat(ctx, h.Pool, suID, id)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	body := store.EncodeCoinsCreditMessage(grantID, req.AmountBronze, reason)
	msg, err := store.SendChatMessageOpts(ctx, h.Pool, chatID, suID, store.SendChatOptions{Body: body})
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	_ = store.AttachAdminCoinGrantMessage(ctx, h.Pool, grantID, msg.ID)

	item := chatMessageToItem(msg)
	if h.Hub != nil {
		h.Hub.PublishToUsers([]uuid.UUID{id, suID}, map[string]any{
			"type": "chat_message", "chat_id": chatID.String(), "message": item,
		})
		h.Hub.PublishToUsers([]uuid.UUID{id, suID}, map[string]any{
			"type": "chat_list_changed",
		})
		h.broadcastToAdmins(ctx, map[string]any{
			"type": "support_message", "user_id": id.String(), "chat_id": chatID.String(),
		})
	}
	if h.Push != nil {
		lang := i18n.LangRU
		pushBody := reason
		if pushBody == "" {
			pushBody = i18n.Content(lang, "push.coins_granted_body")
		}
		h.Push.NotifyUsers([]uuid.UUID{id}, store.WebPushCategoryChat, PushPayload{
			Title: i18n.Content(lang, "label.support"),
			Body:  pushBody,
			URL:   "/chats/" + chatID.String(),
			Tag:   "chat_" + chatID.String(),
		})
	}
	balance, _ := store.GetBalance(ctx, h.Pool, id)
	writeJSON(w, http.StatusOK, map[string]any{
		"balance_bronze": balance,
		"deferred":       true,
		"grant_id":       grantID.String(),
		"chat_id":        chatID.String(),
	})
}

// supportUserID возвращает ID системного аккаунта поддержки.
func (h *AdminHandler) supportUserID(ctx context.Context) (uuid.UUID, bool) {
	su, err := store.GetSupportUser(ctx, h.Pool)
	if err != nil || su == nil {
		return uuid.Nil, false
	}
	return su.ID, true
}

// SupportChats возвращает список диалогов support-аккаунта.
// Формат — плоский snake_case под клиент админки (не сырой store.ChatPreview).
func (h *AdminHandler) SupportChats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	ctx := r.Context()
	suID, ok := h.supportUserID(ctx)
	if !ok {
		writeJSON(w, http.StatusOK, map[string]any{"chats": []any{}})
		return
	}
	chats, err := store.ListChatsForUser(ctx, h.Pool, suID, 100, 0)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	items := make([]map[string]any, 0, len(chats))
	for _, c := range chats {
		peerName := ""
		if c.Peer.DisplayName != nil {
			peerName = strings.TrimSpace(*c.Peer.DisplayName)
		}
		if peerName == "" {
			peerName = c.Peer.Email
		}
		item := map[string]any{
			"id":           c.ChatID.String(),
			"peer_id":      c.Peer.ID.String(),
			"peer_name":    peerName,
			"unread_count": c.UnreadCount,
			"avatar_kind":  c.Peer.AvatarKind,
		}
		if c.Peer.AvatarValue != nil {
			item["avatar_value"] = *c.Peer.AvatarValue
		}
		if c.LastMessage != nil {
			preview := strings.TrimSpace(c.LastMessage.Body)
			if preview == "" && c.LastMessage.HasImage {
				preview = "📷"
			}
			item["last_message"] = preview
			item["last_message_at"] = c.LastMessage.CreatedAt.UTC().Format(time.RFC3339Nano)
		}
		items = append(items, item)
	}
	writeJSON(w, http.StatusOK, map[string]any{"chats": items})
}

// SupportMessages обслуживает чтение (GET) и отправку (POST) сообщений
// в диалоге support↔пользователь. :userId — ID пользователя (peer).
func (h *AdminHandler) SupportMessages(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	suID, ok := h.supportUserID(ctx)
	if !ok {
		WriteErr(w, r, http.StatusInternalServerError, "support user not found")
		return
	}
	// /api/admin/support/chats/:userId[ /messages ]
	path := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/admin/support/chats/"), "/")
	parts := strings.Split(path, "/")
	if len(parts) == 0 || parts[0] == "" {
		WriteErr(w, r, http.StatusNotFound, "not found")
		return
	}
	peerID, err := uuid.Parse(parts[0])
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
		return
	}
	chatID, err := store.EnsureDirectChat(ctx, h.Pool, suID, peerID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if len(parts) == 1 {
		if r.Method != http.MethodGet {
			WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"chat_id":         chatID.String(),
			"support_user_id": suID.String(),
			"peer_id":         peerID.String(),
		})
		return
	}
	if parts[1] != "messages" {
		WriteErr(w, r, http.StatusNotFound, "not found")
		return
	}
	switch r.Method {
	case http.MethodGet:
		limit := 20
		if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
			n, convErr := strconv.Atoi(raw)
			if convErr == nil && n > 0 {
				limit = n
				if limit > 200 {
					limit = 200
				}
			}
		}
		var before *time.Time
		if raw := strings.TrimSpace(r.URL.Query().Get("before")); raw != "" {
			t, parseErr := time.Parse(time.RFC3339Nano, raw)
			if parseErr == nil {
				value := t.UTC()
				before = &value
			}
		}
		msgs, err := store.ListChatMessages(ctx, h.Pool, chatID, suID, limit, before)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		// Прочтение от имени support — сбрасывает unread в inbox админки.
		if _, err := store.MarkChatRead(ctx, h.Pool, chatID, suID); err == nil && h.Hub != nil {
			h.broadcastToAdmins(ctx, map[string]any{
				"type": "support_message", "user_id": peerID.String(), "chat_id": chatID.String(),
			})
		}
		items := make([]ChatMessageItem, 0, len(msgs))
		for _, m := range msgs {
			items = append(items, chatMessageToItem(m))
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"messages":        items,
			"chat_id":         chatID.String(),
			"support_user_id": suID.String(),
		})
	case http.MethodPost:
		var body struct {
			Body string `json:"body"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
			return
		}
		msg, err := store.SendChatMessageOpts(ctx, h.Pool, chatID, suID, store.SendChatOptions{Body: body.Body})
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		item := chatMessageToItem(msg)
		// WS-уведомление пользователю + админам (badge).
		if h.Hub != nil {
			h.Hub.PublishToUsers([]uuid.UUID{peerID}, map[string]any{
				"type": "chat_message", "chat_id": chatID.String(), "message": item,
			})
			h.broadcastToAdmins(ctx, map[string]any{
				"type": "support_message", "user_id": peerID.String(), "chat_id": chatID.String(),
			})
		}
		writeJSON(w, http.StatusOK, map[string]any{"message": item})
	default:
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// broadcastToAdmins шлёт payload всем онлайн-админам (для badge поддержки).
func (h *AdminHandler) broadcastToAdmins(ctx context.Context, payload map[string]any) {
	if h.Hub == nil {
		return
	}
	admins, err := store.ListAdminIDs(ctx, h.Pool)
	if err != nil || len(admins) == 0 {
		return
	}
	h.Hub.PublishToUsers(admins, payload)
}

// SupportUserInfo возвращает контакт системного аккаунта поддержки
// (id, display_name), чтобы пользователь мог начать диалог. GET /api/support-user.
func (h *AdminHandler) SupportUserInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	su, err := store.GetSupportUser(r.Context(), h.Pool)
	if err != nil || su == nil {
		writeJSON(w, http.StatusOK, map[string]any{})
		return
	}
	lang := i18n.LangFromRequest(r)
	writeJSON(w, http.StatusOK, map[string]any{
		"id":           su.ID.String(),
		"display_name": i18n.Content(lang, "label.support"),
		"email":        su.Email,
		"is_support":   true,
	})
}
