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
}

type ChatPreviewItem struct {
	ChatID      string           `json:"chat_id"`
	User        FriendUserItem   `json:"user"`
	LastMessage *ChatMessageItem `json:"last_message,omitempty"`
	UnreadCount int              `json:"unread_count"`
	CreatedAt   string           `json:"created_at"`
	UpdatedAt   string           `json:"updated_at"`
}

type ChatMessageItem struct {
	ID           string  `json:"id"`
	ChatID       string  `json:"chat_id"`
	SenderUserID string  `json:"sender_user_id"`
	Body         string  `json:"body"`
	CreatedAt    string  `json:"created_at"`
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

func chatMessageToItem(msg store.ChatMessage) ChatMessageItem {
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
		ReadAt:       readAt,
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
	case errors.Is(err, store.ErrChatFriendRequired):
		http.Error(w, "only friends can chat", http.StatusForbidden)
	case errors.Is(err, store.ErrChatForbidden):
		http.Error(w, "forbidden", http.StatusForbidden)
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

	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
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
			User:        friendUserToItem(c.Peer),
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

	userID, ok := currentUserIDFromContext(r)
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
	userID, ok := currentUserIDFromContext(r)
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
	userID, ok := currentUserIDFromContext(r)
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

	userID, ok := currentUserIDFromContext(r)
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

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": updated})
}
