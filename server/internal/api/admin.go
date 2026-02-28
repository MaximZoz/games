package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/applog"
	"multigames/server/internal/auth"
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
}

type AdminInitRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AdminUserItem struct {
	ID          string  `json:"id"`
	Email       string  `json:"email"`
	DisplayName *string `json:"display_name,omitempty"`
	IsAdmin     bool    `json:"is_admin"`
	CreatedAt   string  `json:"created_at"`
	Age         *int    `json:"age,omitempty"`
	Gender      *string `json:"gender,omitempty"`
	About       *string `json:"about,omitempty"`
	AvatarKind  string  `json:"avatar_kind,omitempty"`
	AvatarValue *string `json:"avatar_value,omitempty"`
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if h.InitSecret == "" {
		http.Error(w, "admin init disabled", http.StatusForbidden)
		return
	}
	secret := r.Header.Get("X-Admin-Init-Secret")
	if secret != h.InitSecret {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req AdminInitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || len(req.Password) < 6 {
		http.Error(w, "email and password (min 6 chars) required", http.StatusBadRequest)
		return
	}
	n, err := store.CountAdmins(r.Context(), h.Pool)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if n > 0 {
		http.Error(w, "admin already exists", http.StatusConflict)
		return
	}
	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	u, err := store.CreateUser(r.Context(), h.Pool, req.Email, hash, "")
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "email already registered", http.StatusConflict)
			return
		}
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if err := store.SetUserAdmin(r.Context(), h.Pool, u.ID, true); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(AdminUserItem{
		ID: u.ID.String(), Email: u.Email, IsAdmin: true, CreatedAt: u.CreatedAt,
	})
}

// ListUsers возвращает список всех пользователей.
func (h *AdminHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	list, err := store.ListUsers(r.Context(), h.Pool)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	items := make([]AdminUserItem, 0, len(list))
	for _, u := range list {
		items = append(items, AdminUserItem{
			ID:          u.ID.String(),
			Email:       u.Email,
			DisplayName: u.DisplayName,
			IsAdmin:     u.IsAdmin,
			CreatedAt:   u.CreatedAt,
			Age:         u.Age,
			Gender:      u.Gender,
			About:       u.About,
			AvatarKind:  u.AvatarKind,
			AvatarValue: u.AvatarValue,
		})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"users": items})
}

// SetAdmin выставляет или снимает флаг админа у пользователя.
func (h *AdminHandler) SetAdmin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req SetAdminRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		http.Error(w, "invalid user_id", http.StatusBadRequest)
		return
	}
	if err := store.SetUserAdmin(r.Context(), h.Pool, id, req.IsAdmin); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ResetPassword сбрасывает пароль пользователю.
func (h *AdminHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	if len(req.NewPassword) < 6 {
		http.Error(w, "new_password must be at least 6 characters", http.StatusBadRequest)
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		http.Error(w, "invalid user_id", http.StatusBadRequest)
		return
	}
	hash, err := auth.HashPassword(req.NewPassword)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if err := store.SetUserPassword(r.Context(), h.Pool, id, hash); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DeleteUser удаляет пользователя.
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req DeleteUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	id, err := uuid.Parse(req.UserID)
	if err != nil {
		http.Error(w, "invalid user_id", http.StatusBadRequest)
		return
	}
	currentID, _ := GetUserID(r.Context())
	if id == currentID {
		http.Error(w, "cannot delete yourself", http.StatusBadRequest)
		return
	}
	if err := store.DeleteUser(r.Context(), h.Pool, id); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListLogs возвращает логи, загруженные в БД из файла.
func (h *AdminHandler) ListLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			http.Error(w, "invalid limit", http.StatusBadRequest)
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
			http.Error(w, "invalid offset", http.StatusBadRequest)
			return
		}
		offset = n
	}

	var userID *uuid.UUID
	if raw := strings.TrimSpace(r.URL.Query().Get("user_id")); raw != "" {
		id, err := uuid.Parse(raw)
		if err != nil {
			http.Error(w, "invalid user_id", http.StatusBadRequest)
			return
		}
		userID = &id
	}

	var source *string
	if raw := strings.TrimSpace(strings.ToLower(r.URL.Query().Get("source"))); raw != "" {
		if raw != "frontend" && raw != "backend" {
			http.Error(w, "invalid source", http.StatusBadRequest)
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
			http.Error(w, "invalid from", http.StatusBadRequest)
			return
		}
		utc := t.UTC()
		from = &utc
	}

	var to *time.Time
	if raw := strings.TrimSpace(r.URL.Query().Get("to")); raw != "" {
		t, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			http.Error(w, "invalid to", http.StatusBadRequest)
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
		http.Error(w, "server error", http.StatusInternalServerError)
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if err := store.TruncateAppLogs(r.Context(), h.Pool); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
