package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type FriendsHandler struct {
	Pool *pgxpool.Pool
}

type FriendUserItem struct {
	ID          string  `json:"id"`
	Email       string  `json:"email,omitempty"`
	DisplayName *string `json:"display_name,omitempty"`
	AvatarKind  string  `json:"avatar_kind,omitempty"`
	AvatarValue *string `json:"avatar_value,omitempty"`
	Age         *int    `json:"age,omitempty"`
	Gender      *string `json:"gender,omitempty"`
	About       *string `json:"about,omitempty"`
}

type FriendItem struct {
	User      FriendUserItem `json:"user"`
	CreatedAt string         `json:"created_at"`
}

type FriendRequestItem struct {
	RequestID string         `json:"request_id"`
	User      FriendUserItem `json:"user"`
	CreatedAt string         `json:"created_at"`
}

type FriendSearchItem struct {
	User           FriendUserItem `json:"user"`
	RelationStatus string         `json:"relation_status"`
	RequestID      *string        `json:"request_id,omitempty"`
}

type SendFriendRequestBody struct {
	TargetUserID string `json:"target_user_id"`
}

type FriendRequestActionBody struct {
	RequestID string `json:"request_id"`
}

type RemoveFriendBody struct {
	FriendUserID string `json:"friend_user_id"`
}

func friendUserToItem(u store.FriendUser) FriendUserItem {
	return FriendUserItem{
		ID:          u.ID.String(),
		DisplayName: u.DisplayName,
		AvatarKind:  u.AvatarKind,
		AvatarValue: u.AvatarValue,
		Age:         u.Age,
		Gender:      u.Gender,
		About:       u.About,
	}
}

func currentUserIDFromContext(r *http.Request) (uuid.UUID, bool) {
	userID, ok := GetUserID(r.Context())
	return userID, ok
}

func writeFriendError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, store.ErrCannotFriendYourself):
		http.Error(w, "cannot friend yourself", http.StatusBadRequest)
	case errors.Is(err, store.ErrAlreadyFriends):
		http.Error(w, "already friends", http.StatusConflict)
	case errors.Is(err, store.ErrFriendRequestAlreadySent):
		http.Error(w, "friend request already sent", http.StatusConflict)
	case errors.Is(err, store.ErrFriendRequestAlreadyPending):
		http.Error(w, "incoming friend request is pending", http.StatusConflict)
	case errors.Is(err, store.ErrFriendForbidden):
		http.Error(w, "forbidden", http.StatusForbidden)
	case errors.Is(err, store.ErrFriendNotFound):
		http.Error(w, "not found", http.StatusNotFound)
	default:
		http.Error(w, "server error", http.StatusInternalServerError)
	}
}

func (h *FriendsHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	friends, err := store.ListFriendships(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	incoming, err := store.ListIncomingFriendRequests(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	outgoing, err := store.ListOutgoingFriendRequests(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	friendItems := make([]FriendItem, 0, len(friends))
	for _, item := range friends {
		friendItems = append(friendItems, FriendItem{
			User:      friendUserToItem(item.User),
			CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	incomingItems := make([]FriendRequestItem, 0, len(incoming))
	for _, item := range incoming {
		incomingItems = append(incomingItems, FriendRequestItem{
			RequestID: item.ID.String(),
			User:      friendUserToItem(item.User),
			CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	outgoingItems := make([]FriendRequestItem, 0, len(outgoing))
	for _, item := range outgoing {
		outgoingItems = append(outgoingItems, FriendRequestItem{
			RequestID: item.ID.String(),
			User:      friendUserToItem(item.User),
			CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"friends":  friendItems,
		"incoming": incomingItems,
		"outgoing": outgoingItems,
	})
}

func (h *FriendsHandler) Search(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	query := strings.TrimSpace(r.URL.Query().Get("q"))
	limit := 20
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			http.Error(w, "invalid limit", http.StatusBadRequest)
			return
		}
		if n > 50 {
			n = 50
		}
		limit = n
	}

	users, err := store.SearchUsersWithFriendRelation(r.Context(), h.Pool, userID, query, limit)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	items := make([]FriendSearchItem, 0, len(users))
	for _, u := range users {
		var requestID *string
		if u.RequestID != nil {
			s := u.RequestID.String()
			requestID = &s
		}
		items = append(items, FriendSearchItem{
			User:           friendUserToItem(u.User),
			RelationStatus: u.RelationStatus,
			RequestID:      requestID,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"users": items,
	})
}

func (h *FriendsHandler) SendRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body SendFriendRequestBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		http.Error(w, "invalid target_user_id", http.StatusBadRequest)
		return
	}

	requestID, err := store.CreateFriendRequest(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeFriendError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"request_id": requestID.String(),
	})
}

func (h *FriendsHandler) AcceptRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		http.Error(w, "invalid request_id", http.StatusBadRequest)
		return
	}

	if err := store.AcceptFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) RejectRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		http.Error(w, "invalid request_id", http.StatusBadRequest)
		return
	}

	if err := store.RejectFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) CancelRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		http.Error(w, "invalid request_id", http.StatusBadRequest)
		return
	}

	if err := store.CancelOutgoingFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) RemoveFriend(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body RemoveFriendBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	friendID, err := uuid.Parse(strings.TrimSpace(body.FriendUserID))
	if err != nil {
		http.Error(w, "invalid friend_user_id", http.StatusBadRequest)
		return
	}

	if err := store.RemoveFriendship(r.Context(), h.Pool, userID, friendID); err != nil {
		writeFriendError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
