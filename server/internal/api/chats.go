package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
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
	Push *WebPushSender
}

type ChatUserItem struct {
	ID          string  `json:"id"`
	DisplayName *string `json:"display_name,omitempty"`
	AvatarKind  string  `json:"avatar_kind,omitempty"`
	AvatarValue *string `json:"avatar_value,omitempty"`
	Age         *int    `json:"age,omitempty"`
	Gender      *string `json:"gender,omitempty"`
	About       *string `json:"about,omitempty"`
	FrameColor  string  `json:"frame_color,omitempty"`
	FrameCode   string  `json:"frame_code,omitempty"`
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
	EditedAt     *string `json:"edited_at,omitempty"`
	ReplyToMessageID *string `json:"reply_to_message_id,omitempty"`
	HasImage     bool    `json:"has_image,omitempty"`
	ImageCount   int     `json:"image_count,omitempty"`
	ReplyToBody  *string `json:"reply_to_body,omitempty"`
	ReplyToHasImage bool `json:"reply_to_has_image,omitempty"`
	ReplyToSenderID *string `json:"reply_to_sender_id,omitempty"`
}

type StartChatBody struct {
	TargetUserID string `json:"target_user_id"`
}

type SendChatImageBody struct {
	ImageBase64 string `json:"image_base64"`
	ImageMime   string `json:"image_mime,omitempty"`
}

type SendChatMessageBody struct {
	ChatID           string `json:"chat_id"`
	Body             string `json:"body"`
	ReplyToMessageID string `json:"reply_to_message_id,omitempty"`
	// image_base64 — устаревший одиночный вариант; images — до 3 фото.
	ImageBase64 string             `json:"image_base64,omitempty"`
	ImageMime   string             `json:"image_mime,omitempty"`
	Images      []SendChatImageBody `json:"images,omitempty"`
}

type EditChatMessageBody struct {
	MessageID string `json:"message_id"`
	Body      string `json:"body"`
}

type DeleteChatMessageBody struct {
	MessageID string `json:"message_id"`
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
	var editedAt *string
	if msg.EditedAt != nil {
		value := msg.EditedAt.UTC().Format(time.RFC3339Nano)
		editedAt = &value
	}
	var replyToID *string
	if msg.ReplyToMessageID != nil {
		s := msg.ReplyToMessageID.String()
		replyToID = &s
	}
	var replyToBody *string
	if msg.ReplyToMessageID != nil {
		b := msg.ReplyToBody
		replyToBody = &b
	}
	var replyToSender *string
	if msg.ReplyToSenderID != nil {
		s := msg.ReplyToSenderID.String()
		replyToSender = &s
	}
	return ChatMessageItem{
		ID:               msg.ID.String(),
		ChatID:           msg.ChatID.String(),
		SenderUserID:     msg.SenderUserID.String(),
		Body:             msg.Body,
		CreatedAt:        msg.CreatedAt.UTC().Format(time.RFC3339Nano),
		DeliveredAt:      deliveredAt,
		ReadAt:           readAt,
		EditedAt:         editedAt,
		ReplyToMessageID: replyToID,
		HasImage:         msg.HasImage,
		ImageCount:       msg.ImageCount,
		ReplyToBody:      replyToBody,
		ReplyToHasImage:  msg.ReplyToHasImage,
		ReplyToSenderID:  replyToSender,
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

func chatUserToItemWithFrame(u store.ChatUser, frames map[uuid.UUID]store.EquippedFrame) ChatUserItem {
	item := chatUserToItem(u)
	if f, ok := frames[u.ID]; ok {
		item.FrameColor = f.Color
		item.FrameCode = f.Code
	}
	return item
}

func writeChatError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, store.ErrCannotChatWithYourself):
		http.Error(w, "cannot chat with yourself", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatMessageEmpty):
		http.Error(w, "message is empty", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatMessageTooLong):
		http.Error(w, "message is too long", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatImageTooLarge):
		http.Error(w, "image is too large", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatImageUnsupported):
		http.Error(w, "unsupported image type", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatReplyInvalid):
		http.Error(w, "invalid reply target", http.StatusBadRequest)
	case errors.Is(err, store.ErrCannotBlockYourself):
		http.Error(w, "cannot block yourself", http.StatusBadRequest)
	case errors.Is(err, store.ErrChatFriendsOnlyText):
		http.Error(w, "only friends can send text messages", http.StatusForbidden)
	case errors.Is(err, store.ErrChatEditForbidden):
		http.Error(w, "cannot edit this message", http.StatusForbidden)
	case errors.Is(err, store.ErrChatDeleteForbidden):
		http.Error(w, "cannot delete this message", http.StatusForbidden)
	case errors.Is(err, store.ErrChatForbidden):
		http.Error(w, "forbidden", http.StatusForbidden)
	case errors.Is(err, store.ErrUserBlocked):
		http.Error(w, "user is blocked", http.StatusForbidden)
	case errors.Is(err, store.ErrUserNotFound):
		http.Error(w, "user not found", http.StatusNotFound)
	case errors.Is(err, store.ErrChatNotFound):
		http.Error(w, "not found", http.StatusNotFound)
	case errors.Is(err, store.ErrChatMessageNotFound):
		http.Error(w, "message not found", http.StatusNotFound)
	case errors.Is(err, store.ErrChatImageMissing):
		http.Error(w, "image not found", http.StatusNotFound)
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

	// Увидел список чатов (превью) = сообщения доставлены, даже без открытия диалога.
	syncIncomingDelivered(r.Context(), h.Pool, h.Hub, userID)

	items := make([]ChatPreviewItem, 0, len(chats))
	peerIDs := make([]uuid.UUID, 0, len(chats))
	for _, c := range chats {
		peerIDs = append(peerIDs, c.Peer.ID)
	}
	frames, _ := store.EquippedFramesMap(r.Context(), h.Pool, peerIDs)
	for _, c := range chats {
		var lastMessage *ChatMessageItem
		if c.LastMessage != nil {
			item := chatMessageToItem(*c.LastMessage)
			lastMessage = &item
		}
		items = append(items, ChatPreviewItem{
			ChatID:      c.ChatID.String(),
			User:        chatUserToItemWithFrame(c.Peer, frames),
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

// Capabilities — GET /api/chats/capabilities?chat_id=…
// can_send_text / emoji_only с учётом messages_friends_only у собеседника.
func (h *ChatsHandler) Capabilities(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("chat_id")))
	if err != nil {
		http.Error(w, "invalid chat_id", http.StatusBadRequest)
		return
	}

	lowID, highID, err := store.ChatParticipantIDs(r.Context(), h.Pool, chatID)
	if err != nil {
		writeChatError(w, err)
		return
	}
	if userID != lowID && userID != highID {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	peerID := highID
	if userID == highID {
		peerID = lowID
	}

	emojiOnly := false
	peerSettings, err := store.GetUserSettings(r.Context(), h.Pool, peerID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if peerSettings.MessagesFriendsOnly {
		friends, err := store.AreFriends(r.Context(), h.Pool, userID, peerID)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}
		emojiOnly = !friends
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"can_send_text": !emojiOnly,
		"emoji_only":    emojiOnly,
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
	if ids, deliverErr := store.MarkChatDelivered(r.Context(), h.Pool, chatID, userID); deliverErr == nil && len(ids) > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				ids,
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

func decodeChatImageBase64(raw string) ([]byte, error) {
	s := strings.TrimSpace(raw)
	if s == "" {
		return nil, nil
	}
	if i := strings.Index(s, ","); i >= 0 && strings.Contains(strings.ToLower(s[:i]), "base64") {
		s = s[i+1:]
	}
	data, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		data, err = base64.RawStdEncoding.DecodeString(s)
		if err != nil {
			return nil, err
		}
	}
	return data, nil
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

	opts := store.SendChatOptions{Body: body.Body}
	if raw := strings.TrimSpace(body.ReplyToMessageID); raw != "" {
		rid, err := uuid.Parse(raw)
		if err != nil {
			http.Error(w, "invalid reply_to_message_id", http.StatusBadRequest)
			return
		}
		opts.ReplyToMessageID = &rid
	}
	for _, imgBody := range body.Images {
		if strings.TrimSpace(imgBody.ImageBase64) == "" {
			continue
		}
		img, err := decodeChatImageBase64(imgBody.ImageBase64)
		if err != nil {
			http.Error(w, "invalid image_base64", http.StatusBadRequest)
			return
		}
		mime := imgBody.ImageMime
		if strings.TrimSpace(mime) == "" {
			mime = "image/jpeg"
		}
		opts.Images = append(opts.Images, store.ChatImageInput{
			Mime: mime,
			Data: img,
		})
		if len(opts.Images) >= store.MaxChatImagesPerMessage {
			break
		}
	}
	if len(opts.Images) == 0 && strings.TrimSpace(body.ImageBase64) != "" {
		img, err := decodeChatImageBase64(body.ImageBase64)
		if err != nil {
			http.Error(w, "invalid image_base64", http.StatusBadRequest)
			return
		}
		opts.ImageData = img
		opts.ImageMime = body.ImageMime
		if strings.TrimSpace(opts.ImageMime) == "" {
			opts.ImageMime = "image/jpeg"
		}
	}

	msg, err := store.SendChatMessageOpts(r.Context(), h.Pool, chatID, userID, opts)
	if err != nil {
		writeChatError(w, err)
		return
	}

	item := chatMessageToItem(msg)
	if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
		h.publishChatMessage([]uuid.UUID{lowID, highID}, item)
		h.publishChatListChanged(lowID, highID)

		peerID := highID
		if userID == highID {
			peerID = lowID
		}
		if h.Hub != nil && h.Hub.IsUserOnline(peerID) {
			if ids, err := store.MarkChatDelivered(r.Context(), h.Pool, chatID, peerID); err == nil && len(ids) > 0 {
				h.publishChatDelivered(
					[]uuid.UUID{lowID, highID},
					chatID.String(),
					peerID.String(),
					ids,
				)
				deliveredAt := time.Now().UTC().Format(time.RFC3339Nano)
				item.DeliveredAt = &deliveredAt
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": item,
	})
}

func (h *ChatsHandler) EditMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body EditChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(body.MessageID))
	if err != nil {
		http.Error(w, "invalid message_id", http.StatusBadRequest)
		return
	}
	msg, err := store.EditChatMessage(r.Context(), h.Pool, messageID, userID, body.Body)
	if err != nil {
		writeChatError(w, err)
		return
	}
	item := chatMessageToItem(msg)
	if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, msg.ChatID); pairErr == nil {
		h.publishChatMessageUpdated([]uuid.UUID{lowID, highID}, item)
		h.publishChatListChanged(lowID, highID)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": item,
	})
}

func (h *ChatsHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body DeleteChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(body.MessageID))
	if err != nil {
		http.Error(w, "invalid message_id", http.StatusBadRequest)
		return
	}
	chatID, err := store.DeleteChatMessage(r.Context(), h.Pool, messageID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}
	if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
		h.publishChatMessageDeleted([]uuid.UUID{lowID, highID}, chatID.String(), messageID.String())
		h.publishChatListChanged(lowID, highID)
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) MessageImage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("message_id")))
	if err != nil {
		http.Error(w, "invalid message_id", http.StatusBadRequest)
		return
	}
	index := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("index")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 0 || n >= store.MaxChatImagesPerMessage {
			http.Error(w, "invalid index", http.StatusBadRequest)
			return
		}
		index = n
	}
	mime, data, _, err := store.GetChatMessageImage(r.Context(), h.Pool, messageID, userID, index)
	if err != nil {
		writeChatError(w, err)
		return
	}
	w.Header().Set("Content-Type", mime)
	w.Header().Set("Cache-Control", "private, max-age=3600")
	_, _ = w.Write(data)
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

	updatedIDs, err := store.MarkChatRead(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}

	if len(updatedIDs) > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatRead(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				updatedIDs,
			)
			h.publishChatListChanged(lowID, highID)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": len(updatedIDs)})
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

	updatedIDs, err := store.MarkChatDelivered(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, err)
		return
	}

	if len(updatedIDs) > 0 {
		if lowID, highID, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				[]uuid.UUID{lowID, highID},
				chatID.String(),
				userID.String(),
				updatedIDs,
			)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": len(updatedIDs)})
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
	if h.Push == nil {
		return
	}
	senderID, err := uuid.Parse(item.SenderUserID)
	if err != nil {
		return
	}
	recipients := make([]uuid.UUID, 0, len(userIDs))
	for _, id := range userIDs {
		if id != senderID {
			recipients = append(recipients, id)
		}
	}
	if len(recipients) == 0 {
		return
	}
	from := pushUserLabel(context.Background(), h.Pool, senderID)
	body := strings.TrimSpace(item.Body)
	if item.HasImage && body == "" {
		if item.ImageCount > 1 {
			body = fmt.Sprintf("Фото (%d)", item.ImageCount)
		} else {
			body = "Фото"
		}
	} else if item.HasImage {
		if item.ImageCount > 1 {
			body = fmt.Sprintf("Фото (%d): %s", item.ImageCount, body)
		} else {
			body = "Фото: " + body
		}
	}
	if len([]rune(body)) > 120 {
		runes := []rune(body)
		body = string(runes[:117]) + "…"
	}
	if body == "" {
		body = "Новое сообщение"
	}
	h.Push.NotifyUsers(recipients, store.WebPushCategoryChat, PushPayload{
		Title: from,
		Body:  body,
		URL:   "/chats/" + item.ChatID,
		Tag:   "chat_" + item.ChatID,
	})
}

func (h *ChatsHandler) publishChatMessageUpdated(userIDs []uuid.UUID, item ChatMessageItem) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":    "chat_message_updated",
		"chat_id": item.ChatID,
		"message": item,
	})
}

func (h *ChatsHandler) publishChatMessageDeleted(userIDs []uuid.UUID, chatID, messageID string) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":       "chat_message_deleted",
		"chat_id":    chatID,
		"message_id": messageID,
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

func uuidSliceToStrings(ids []uuid.UUID) []string {
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		out = append(out, id.String())
	}
	return out
}

// syncIncomingDelivered отмечает доставку входящих и шлёт chat_delivered отправителям.
func syncIncomingDelivered(
	ctx context.Context,
	pool *pgxpool.Pool,
	hub *RealtimeHub,
	delivererUserID uuid.UUID,
) {
	if pool == nil || hub == nil {
		return
	}
	batches, err := store.MarkIncomingDeliveredForUser(ctx, pool, delivererUserID)
	if err != nil || len(batches) == 0 {
		return
	}
	deliverer := delivererUserID.String()
	deliveredAt := time.Now().UTC().Format(time.RFC3339Nano)
	for _, batch := range batches {
		lowID, highID, pairErr := store.ChatParticipantIDs(ctx, pool, batch.ChatID)
		if pairErr != nil {
			continue
		}
		hub.PublishToUsers([]uuid.UUID{lowID, highID}, map[string]any{
			"type":              "chat_delivered",
			"chat_id":           batch.ChatID.String(),
			"deliverer_user_id": deliverer,
			"updated":           len(batch.MessageIDs),
			"message_ids":       uuidSliceToStrings(batch.MessageIDs),
			"delivered_at":      deliveredAt,
		})
	}
}

func (h *ChatsHandler) publishChatRead(
	userIDs []uuid.UUID,
	chatID string,
	readerUserID string,
	messageIDs []uuid.UUID,
) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":           "chat_read",
		"chat_id":        chatID,
		"reader_user_id": readerUserID,
		"updated":        len(messageIDs),
		"message_ids":    uuidSliceToStrings(messageIDs),
		"read_at":        time.Now().UTC().Format(time.RFC3339Nano),
	})
}

func (h *ChatsHandler) publishChatDelivered(
	userIDs []uuid.UUID,
	chatID string,
	delivererUserID string,
	messageIDs []uuid.UUID,
) {
	if h == nil || h.Hub == nil {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type":              "chat_delivered",
		"chat_id":           chatID,
		"deliverer_user_id": delivererUserID,
		"updated":           len(messageIDs),
		"message_ids":       uuidSliceToStrings(messageIDs),
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
