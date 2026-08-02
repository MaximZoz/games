package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type FriendsHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
	Push *WebPushSender
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
	FrameColor  string  `json:"frame_color,omitempty"`
	FrameCode   string  `json:"frame_code,omitempty"`
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

func friendUserToItemWithFrame(u store.FriendUser, frames map[uuid.UUID]store.EquippedFrame) FriendUserItem {
	item := friendUserToItem(u)
	if f, ok := frames[u.ID]; ok {
		item.FrameColor = f.Color
		item.FrameCode = f.Code
	}
	return item
}

func loadFriendFrames(ctx context.Context, pool *pgxpool.Pool, users ...store.FriendUser) map[uuid.UUID]store.EquippedFrame {
	ids := make([]uuid.UUID, 0, len(users))
	for _, u := range users {
		ids = append(ids, u.ID)
	}
	frames, err := store.EquippedFramesMap(ctx, pool, ids)
	if err != nil {
		return map[uuid.UUID]store.EquippedFrame{}
	}
	return frames
}

func currentUserIDFromContext(r *http.Request) (uuid.UUID, bool) {
	userID, ok := GetUserID(r.Context())
	return userID, ok
}

func writeFriendError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, store.ErrCannotFriendYourself):
		WriteErr(w, r, http.StatusBadRequest, "cannot friend yourself")
	case errors.Is(err, store.ErrCannotFriendSupport):
		WriteErr(w, r, http.StatusBadRequest, "cannot friend support")
	case errors.Is(err, store.ErrAlreadyFriends):
		WriteErr(w, r, http.StatusConflict, "already friends")
	case errors.Is(err, store.ErrFriendRequestAlreadySent):
		WriteErr(w, r, http.StatusConflict, "friend request already sent")
	case errors.Is(err, store.ErrFriendRequestAlreadyPending):
		WriteErr(w, r, http.StatusConflict, "incoming friend request is pending")
	case errors.Is(err, store.ErrUserBlocked):
		WriteErr(w, r, http.StatusForbidden, "user is blocked")
	case errors.Is(err, store.ErrFriendForbidden):
		WriteErr(w, r, http.StatusForbidden, "forbidden")
	case errors.Is(err, store.ErrFriendNotFound):
		WriteErr(w, r, http.StatusNotFound, "not found")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

func (h *FriendsHandler) publishFriendsUpdated(userIDs ...uuid.UUID) {
	if h == nil || h.Hub == nil || len(userIDs) == 0 {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type": "friends_updated",
	})
}

func (h *FriendsHandler) requestParticipants(
	r *http.Request,
	requestID uuid.UUID,
) (uuid.UUID, uuid.UUID, error) {
	var senderID uuid.UUID
	var receiverID uuid.UUID
	err := h.Pool.QueryRow(
		r.Context(),
		`SELECT sender_user_id, receiver_user_id FROM friend_requests WHERE id = $1`,
		requestID,
	).Scan(&senderID, &receiverID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return uuid.Nil, uuid.Nil, store.ErrFriendNotFound
		}
		return uuid.Nil, uuid.Nil, err
	}
	return senderID, receiverID, nil
}

func (h *FriendsHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	friends, err := store.ListFriendships(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	incoming, err := store.ListIncomingFriendRequests(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	outgoing, err := store.ListOutgoingFriendRequests(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	friendUsers := make([]store.FriendUser, 0, len(friends)+len(incoming)+len(outgoing))
	for _, item := range friends {
		friendUsers = append(friendUsers, item.User)
	}
	for _, item := range incoming {
		friendUsers = append(friendUsers, item.User)
	}
	for _, item := range outgoing {
		friendUsers = append(friendUsers, item.User)
	}
	frames := loadFriendFrames(r.Context(), h.Pool, friendUsers...)

	friendItems := make([]FriendItem, 0, len(friends))
	for _, item := range friends {
		friendItems = append(friendItems, FriendItem{
			User:      friendUserToItemWithFrame(item.User, frames),
			CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	incomingItems := make([]FriendRequestItem, 0, len(incoming))
	for _, item := range incoming {
		incomingItems = append(incomingItems, FriendRequestItem{
			RequestID: item.ID.String(),
			User:      friendUserToItemWithFrame(item.User, frames),
			CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	outgoingItems := make([]FriendRequestItem, 0, len(outgoing))
	for _, item := range outgoing {
		outgoingItems = append(outgoingItems, FriendRequestItem{
			RequestID: item.ID.String(),
			User:      friendUserToItemWithFrame(item.User, frames),
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

func (h *FriendsHandler) UsersCount(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	_, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	n, err := store.CountUsers(r.Context(), h.Pool)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"count": n})
}

func (h *FriendsHandler) Search(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	query := strings.TrimSpace(r.URL.Query().Get("q"))
	limit := 10
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			WriteErr(w, r, http.StatusBadRequest, "invalid limit")
			return
		}
		if n > 50 {
			n = 50
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

	users, hasMore, err := store.SearchUsersWithFriendRelation(
		r.Context(),
		h.Pool,
		userID,
		query,
		limit,
		offset,
	)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	searchUsers := make([]store.FriendUser, 0, len(users))
	for _, u := range users {
		searchUsers = append(searchUsers, u.User)
	}
	frames := loadFriendFrames(r.Context(), h.Pool, searchUsers...)

	items := make([]FriendSearchItem, 0, len(users))
	for _, u := range users {
		var requestID *string
		if u.RequestID != nil {
			s := u.RequestID.String()
			requestID = &s
		}
		items = append(items, FriendSearchItem{
			User:           friendUserToItemWithFrame(u.User, frames),
			RelationStatus: u.RelationStatus,
			RequestID:      requestID,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"users":    items,
		"limit":    limit,
		"offset":   offset,
		"has_more": hasMore,
	})
}

func (h *FriendsHandler) SendRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body SendFriendRequestBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid target_user_id")
		return
	}

	requestID, err := store.CreateFriendRequest(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeFriendError(w, r, err)
		return
	}
	h.publishFriendsUpdated(userID, targetID)
	if h.Push != nil {
		from := pushUserLabel(r.Context(), h.Pool, userID)
		lang := i18n.LangRU
		h.Push.NotifyUsers([]uuid.UUID{targetID}, store.WebPushCategoryFriends, PushPayload{
			Title: i18n.Content(lang, "push.friend_request_title"),
			Body:  i18n.Contentf(lang, "push.friend_request_body", map[string]string{"name": from}),
			URL:   "/friends?tab=incoming",
			Tag:   "friend_request",
		})
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"request_id": requestID.String(),
	})
}

func (h *FriendsHandler) AcceptRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid request_id")
		return
	}

	senderID, receiverID, err := h.requestParticipants(r, requestID)
	if err != nil {
		writeFriendError(w, r, err)
		return
	}

	if err := store.AcceptFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, r, err)
		return
	}
	unlockedSender, _ := store.EvaluateAndUnlock(r.Context(), h.Pool, senderID)
	unlockedReceiver, _ := store.EvaluateAndUnlock(r.Context(), h.Pool, receiverID)
	notifyAchievementUnlocks(h.Push, senderID, unlockedSender)
	notifyAchievementUnlocks(h.Push, receiverID, unlockedReceiver)
	h.publishFriendsUpdated(senderID, receiverID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) RejectRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid request_id")
		return
	}

	senderID, receiverID, err := h.requestParticipants(r, requestID)
	if err != nil {
		writeFriendError(w, r, err)
		return
	}

	if err := store.RejectFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, r, err)
		return
	}
	h.publishFriendsUpdated(senderID, receiverID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) CancelRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body FriendRequestActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	requestID, err := uuid.Parse(strings.TrimSpace(body.RequestID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid request_id")
		return
	}

	senderID, receiverID, err := h.requestParticipants(r, requestID)
	if err != nil {
		writeFriendError(w, r, err)
		return
	}

	if err := store.CancelOutgoingFriendRequest(r.Context(), h.Pool, requestID, userID); err != nil {
		writeFriendError(w, r, err)
		return
	}
	h.publishFriendsUpdated(senderID, receiverID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) RemoveFriend(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body RemoveFriendBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	friendID, err := uuid.Parse(strings.TrimSpace(body.FriendUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid friend_user_id")
		return
	}

	if err := store.RemoveFriendship(r.Context(), h.Pool, userID, friendID); err != nil {
		writeFriendError(w, r, err)
		return
	}
	h.publishFriendsUpdated(userID, friendID)
	w.WriteHeader(http.StatusNoContent)
}
