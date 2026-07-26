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

type ChatsHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
}

type ChatUserItem struct {
	ID          string  `json:"id"`
	DisplayName *string `json:"display_name,omitempty"`
	AvatarKind  string  `json:"avatar_kind,omitempty"`
	AvatarValue *string `json:"avatar_value,omitempty"`
	Age         *int    `json:"age,omitempty"`
	Gender      *string `json:"gender,omitempty"`
	About       *string `json:"about,omitempty"`
}

type ChatPreviewItem struct {
	ChatID      string           `json:"chat_id"`
	User        ChatUserItem     `json:"user"`
	LastMessage *ChatMessageItem `json:"last_message,omitempty"`
	UnreadCount int              `json:"unread_count"`
	CreatedAt   string           `json:"created_at"`
	UpdatedAt   string           `json:"updated_at"`
}

type BlockedChatUserItem struct {
	User      ChatUserItem `json:"user"`
	BlockedAt string       `json:"blocked_at"`
}

type ChatMessageItem struct {
	ID           string  `json:"id"`
	ChatID       string  `json:"chat_id"`
	SenderUserID string  `json:"sender_user_id"`
	Body         string  `json:"body"`
	CreatedAt    string  `json:"created_at"`
	DeliveredAt  *string `json:"delivered_at,omitempty"`
	ReadAt       *string `json:"read_at,omitempty"`
}

type StartChatBody struct {
	TargetUserID string `json:"target_user_id"`
}

type SendChatMessageBody struct {
	ChatID string `json:"chat_id"`
	Body   string `json:"body"`
}

type MarkChatReadBody struct {
	ChatID string `json:"chat_id"`
}

type MarkChatDeliveredBody struct {
	ChatID string `json:"chat_id"`
}

type ClearChatBody struct {
	ChatID string `json:"chat_id"`
}

type ChatUserActionBody struct {
	TargetUserID string `json:"target_user_id"`
}

func currentChatUserIDFromContext(r *http.Request) (uuid.UUID, bool) {
	userID, ok := GetUserID(r.Context())
	return userID, ok
}

func chatMessageToItem(msg store.ChatMessage) ChatMessageItem {
	var deliveredAt *string
	if msg.DeliveredAt != nil {
		value := msg.DeliveredAt.UTC().Format(time.RFC3339Nano)
		deliveredAt = &value
	}
	var readAt *string
	if msg.ReadAt != nil {
		value := msg.ReadAt.UTC().Format(time.RFC3339Nano)
		readAt = &value
	}
	return ChatMessageItem{
		ID:           msg.ID.String(),
		ChatID:       msg.ChatID.String(),
		SenderUserID: msg.SenderUserID.String(),
		Body:         msg.Body,
		CreatedAt:    msg.CreatedAt.UTC().Format(time.RFC3339Nano),
		DeliveredAt:  deliveredAt,
		ReadAt:       readAt,
	}
}

func chatUserToItem(u store.ChatUser) ChatUserItem {
	return ChatUserItem{
		ID:          u.ID.String(),
		DisplayName: u.DisplayName,
		AvatarKind:  u.AvatarKind,
		AvatarValue: u.AvatarValue,
		Age:         u.Age,
		Gender:      u.Gender,
		About:       u.About,
	}
}

func writeChatError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, store.ErrCannotChatWithYourself):
		http.Error(w, "cannot chat with yourself", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatMessageEmpty):
		http.Error(w, "message is empty", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatMessageTooLong):
		http.Error(w, "message is too long", http.StatusBadRequest)
	case errors.Is(err, store.ErrCannotBlockYourself):
		http.Error(w, "cannot block yourself", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatForbidden):
		http.Error(w, "forbidden", http.StatusForbidden)
	case errors.Is(err, store.ErrUserBlocked):
		http.Error(w, "user is blocked", http.StatusForbidden)
	case errors.Is(err, store.ErrUserNotFound):
		http.Error(w, "user not found", http.StatusNotFound)
	case errors.Is(err, store.ErrChatNotFound):
		http.Error(w, "not found", http.StatusNotFound)
	default:
		http.Error(w, "server error", http.StatusInternalServerError)
	}
}

func (h *ChatsHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	limit := 10
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			http.Error(w, "invalid limit", http.StatusBadRequest)
			return
		}
		if n > 200 {
			n = 200
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

	chats, err := store.ListChatsForUser(r.Context(), h.Pool, userID, limit, offset)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	items := make([]ChatPreviewItem, 0, len(chats))
	for _, c := range chats {
		var lastMessage *ChatMessageItem
		if c.LastMessage != nil {
			item := chatMessageToItem(*c.LastMessage)
			lastMessage = &item
		}
		items = append(items, ChatPreviewItem{
			ChatID:      c.ChatID.String(),
			User:        chatUserToItem(c.Peer),
			LastMessage: lastMessage,
			UnreadCount: c.UnreadCount,
			CreatedAt:   c.CreatedAt.UTC().Format(time.RFC3339Nano),
			UpdatedAt:   c.UpdatedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"chats":  items,
		"limit":  limit,
		"offset": offset,
	})
}

func (h *ChatsHandler) Start(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body StartChatBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		http.Error(w, "invalid target_user_id", http.StatusBadRequest)
		return
	}

	chatID, err := store.EnsureDirectChat(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeChatError(w, err)
		return
	}

	h.publishChatListChanged(userID, targetID)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"chat_id": chatID.String(),
	})
}

func (h *ChatsHandler) Messages(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		h.listMessages(w, r)
	case http.MethodPost:
		h.sendMessage(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (h *ChatsHandler) listMessages(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	chatIDRaw := strings.TrimSpace(r.URL.Query().Get("chat_id"))
	chatID, err := uuid.Parse(chatIDRaw)
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			http.Error(w, "invalid limit", http.StatusBadRequest)
			return
		}
		if n > 200 {
			n = 200
		}
		limit = n
	}

	var before *time.Time
	if raw := strings.TrimSpace(r.URL.Query().Get("before")); raw != "" {
		t, err := time.Parse(time.RFC3339Nano, raw)
		if err != nil {
			http.Error(w, "invalid before", http.StatusBadRequest)
			return
		}
		value := t.UTC()
		before = &value
	}

	messages, err := store.ListChatMessages(r.Context(), h.Pool, chatID, userID, limit, before)
	if err != nil {
		writeChatError(w, err)
		return
	}

	// Открытие/синхронизация чата = доставка входящих (как в Telegram).
	if updated, deliverErr := store.MarkChatDelivered(r.Context(), h.Pool, chatID, userID); deliverErr == nil && updated > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				updated,
			)
		}
	}

	items := make([]ChatMessageItem, 0, len(messages))
	for _, msg := range messages {
		items = append(items, chatMessageToItem(msg))
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"messages": items,
		"limit":    limit,
	})
}

func (h *ChatsHandler) sendMessage(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body SendChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	msg, err := store.SendChatMessage(r.Context(), h.Pool, chatID, userID, body.Body)
	if err != nil {
		writeChatError(w, err)
		return
	}

	item := chatMessageToItem(msg)
	if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
		h.publishChatMessage([]uuid.UUID{lowID, highID}, item)
		h.publishChatListChanged(lowID, highID)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": item,
	})
}

func (h *ChatsHandler) Read(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body MarkChatReadBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	updated, err := store.MarkChatRead(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}

	if updated > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatRead(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				updated,
			)
			h.publishChatListChanged(lowID, highID)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": updated})
}

func (h *ChatsHandler) Delivered(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body MarkChatDeliveredBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	updated, err := store.MarkChatDelivered(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}

	if updated > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				updated,
			)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": updated})
}

func (h *ChatsHandler) Clear(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body ClearChatBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	lowID, highID, err := store.ClearChatForUser(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}
	h.publishChatListChanged(lowID, highID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Block(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body ChatUserActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		http.Error(w, "invalid target_user_id", http.StatusBadRequest)
		return
	}

	_, err = store.BlockUser(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeChatError(w, err)
		return
	}
	h.publishChatListChanged(userID, targetID)
	h.publishFriendsUpdated(userID, targetID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Unblock(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var body ChatUserActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		http.Error(w, "invalid target_user_id", http.StatusBadRequest)
		return
	}

	if err := store.UnblockUser(r.Context(), h.Pool, userID, targetID); err != nil {
		writeChatError(w, err)
		return
	}
	h.publishChatListChanged(userID, targetID)
	h.publishFriendsUpdated(userID, targetID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Blocked(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	blocked, err := store.ListBlockedUsers(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	items := make([]BlockedChatUserItem, 0, len(blocked))
	for _, u := range blocked {
		items = append(items, BlockedChatUserItem{
			User:      chatUserToItem(u.User),
			BlockedAt: u.BlockedAt.UTC().Format(time.RFC3339Nano),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"blocked": items,
	})
}

func (h *ChatsHandler) publishChatMessage(userIDs []uuid.UUID, item ChatMessageItem) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":    "chat_message",
		"chat_id": item.ChatID,
		"message": item,
	})
}

func (h *ChatsHandler) publishChatListChanged(userIDs ...uuid.UUID) {
	if h == nil || h.Hub == nil || len(userIDs) == 0 {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type": "chat_list_changed",
	})
}

func (h *ChatsHandler) publishChatRead(
	userIDs []uuid.UUID,
	chatID string,
	readerUserID string,
	updated int,
) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":           "chat_read",
		"chat_id":        chatID,
		"reader_user_id": readerUserID,
		"updated":        updated,
		"read_at":        time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (h *ChatsHandler) publishChatDelivered(
	userIDs []uuid.UUID,
	chatID string,
	delivererUserID string,
	updated int,
) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":              "chat_delivered",
		"chat_id":           chatID,
		"deliverer_user_id": delivererUserID,
		"updated":           updated,
		"delivered_at":      time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (h *ChatsHandler) publishFriendsUpdated(userIDs ...uuid.UUID) {
	if h == nil || h.Hub == nil || len(userIDs) == 0 {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type": "friends_updated",
	})
}
