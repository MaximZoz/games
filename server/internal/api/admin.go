package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/auth"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// AdminHandler обрабатывает запросы админки.
type AdminHandler struct {
	Pool         *pgxpool.Pool
	JWTSecret    []byte
	InitSecret   string // секрет для однократного создания первого админа
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
			ID: u.ID.String(), Email: u.Email, DisplayName: u.DisplayName,
			IsAdmin: u.IsAdmin, CreatedAt: u.CreatedAt,
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
