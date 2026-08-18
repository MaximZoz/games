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

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type ChatsHandler struct {
	Pool *pgxpool.Pool
	Rdb  *redis.Client
	Hub  *RealtimeHub
	Push *WebPushSender
}

type ChatUserItem struct {
	ID                string  `json:"id"`
	DisplayName       *string `json:"display_name,omitempty"`
	AvatarKind        string  `json:"avatar_kind,omitempty"`
	AvatarValue       *string `json:"avatar_value,omitempty"`
	Age               *int    `json:"age,omitempty"`
	Gender            *string `json:"gender,omitempty"`
	About             *string `json:"about,omitempty"`
	FrameColor        string  `json:"frame_color,omitempty"`
	FrameCode         string  `json:"frame_code,omitempty"`
	IsSupport         bool    `json:"is_support,omitempty"`
	PreferredLanguage string  `json:"preferred_language,omitempty"`
}

type ChatPreviewItem struct {
	ChatID      string           `json:"chat_id"`
	User        ChatUserItem     `json:"user"`
	LastMessage *ChatMessageItem `json:"last_message,omitempty"`
	UnreadCount int              `json:"unread_count"`
	CreatedAt   string           `json:"created_at"`
	UpdatedAt   string           `json:"updated_at"`
	Kind        string           `json:"kind,omitempty"`
	Title       string           `json:"title,omitempty"`
	LobbyID     string           `json:"lobby_id,omitempty"`
	GameType    string           `json:"game_type,omitempty"`
	Members     []ChatUserItem   `json:"members,omitempty"`
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

// resolveChatActor — JWT-участник или админ от имени поддержки.
func (h *ChatsHandler) resolveChatActor(r *http.Request, jwtID, chatID uuid.UUID) (uuid.UUID, error) {
	return store.ActingChatUserID(r.Context(), h.Pool, jwtID, chatID)
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
		ID:                u.ID.String(),
		DisplayName:       u.DisplayName,
		AvatarKind:        u.AvatarKind,
		AvatarValue:       u.AvatarValue,
		Age:               u.Age,
		Gender:            u.Gender,
		About:             u.About,
		IsSupport:         u.IsSupport,
		PreferredLanguage: u.PreferredLanguage,
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

func writeChatError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, store.ErrCannotChatWithYourself):
		WriteErr(w, r, http.StatusBadRequest, "cannot chat with yourself")
	case errors.Is(err, store.ErrChatMessageEmpty):
		WriteErr(w, r, http.StatusBadRequest, "message is empty")
	case errors.Is(err, store.ErrChatMessageTooLong):
		WriteErr(w, r, http.StatusBadRequest, "message is too long")
	case errors.Is(err, store.ErrChatImageTooLarge):
		WriteErr(w, r, http.StatusBadRequest, "image is too large")
	case errors.Is(err, store.ErrChatImageUnsupported):
		WriteErr(w, r, http.StatusBadRequest, "unsupported image type")
	case errors.Is(err, store.ErrChatReplyInvalid):
		WriteErr(w, r, http.StatusBadRequest, "invalid reply target")
	case errors.Is(err, store.ErrCannotBlockYourself):
		WriteErr(w, r, http.StatusBadRequest, "cannot block yourself")
	case errors.Is(err, store.ErrCannotBlockSupport):
		WriteErr(w, r, http.StatusBadRequest, "cannot block support")
	case errors.Is(err, store.ErrChatFriendsOnlyText):
		WriteErr(w, r, http.StatusForbidden, "only friends can send text messages")
	case errors.Is(err, store.ErrChatEditForbidden):
		WriteErr(w, r, http.StatusForbidden, "cannot edit this message")
	case errors.Is(err, store.ErrChatDeleteForbidden):
		WriteErr(w, r, http.StatusForbidden, "cannot delete this message")
	case errors.Is(err, store.ErrChatForbidden):
		WriteErr(w, r, http.StatusForbidden, "forbidden")
	case errors.Is(err, store.ErrUserBlocked):
		WriteErr(w, r, http.StatusForbidden, "user is blocked")
	case errors.Is(err, store.ErrUserNotFound):
		WriteErr(w, r, http.StatusNotFound, "user not found")
	case errors.Is(err, store.ErrChatNotFound):
		WriteErr(w, r, http.StatusNotFound, "not found")
	case errors.Is(err, store.ErrChatMessageNotFound):
		WriteErr(w, r, http.StatusNotFound, "message not found")
	case errors.Is(err, store.ErrChatImageMissing):
		WriteErr(w, r, http.StatusNotFound, "image not found")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

func (h *ChatsHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	limit := 10
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			WriteErr(w, r, http.StatusBadRequest, "invalid limit")
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
			WriteErr(w, r, http.StatusBadRequest, "invalid offset")
			return
		}
		offset = n
	}

	// Сносим групповые чаты завершённых лобби (иначе висят «На троих» и т.п.).
	if offset == 0 {
		h.cleanupOrphanGroupChats(r.Context(), userID)
	}

	chats, err := store.ListChatsForUser(r.Context(), h.Pool, userID, limit, offset)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	// Увидел список чатов (превью) = сообщения доставлены, даже без открытия диалога.
	syncIncomingDelivered(r.Context(), h.Pool, h.Hub, userID)

	items := make([]ChatPreviewItem, 0, len(chats))
	peerIDs := make([]uuid.UUID, 0, len(chats))
	for _, c := range chats {
		if c.Kind != store.ChatKindGroup && c.Peer.ID != uuid.Nil {
			peerIDs = append(peerIDs, c.Peer.ID)
		}
		for _, m := range c.Members {
			peerIDs = append(peerIDs, m.ID)
		}
	}
	frames, _ := store.EquippedFramesMap(r.Context(), h.Pool, peerIDs)
	for _, c := range chats {
		var lastMessage *ChatMessageItem
		if c.LastMessage != nil {
			item := chatMessageToItem(*c.LastMessage)
			lastMessage = &item
		}
		preview := ChatPreviewItem{
			ChatID:      c.ChatID.String(),
			User:        chatUserToItemWithFrame(c.Peer, frames),
			LastMessage: lastMessage,
			UnreadCount: c.UnreadCount,
			CreatedAt:   c.CreatedAt.UTC().Format(time.RFC3339Nano),
			UpdatedAt:   c.UpdatedAt.UTC().Format(time.RFC3339Nano),
			Kind:        c.Kind,
			Title:       c.Title,
			LobbyID:     c.LobbyID,
			GameType:    c.GameType,
		}
		if c.Kind == store.ChatKindGroup {
			preview.Members = make([]ChatUserItem, 0, len(c.Members))
			for _, m := range c.Members {
				preview.Members = append(preview.Members, chatUserToItemWithFrame(m, frames))
			}
			if preview.Title == "" {
				preview.Title = "Игра"
			}
			// Для совместимости UI списка: user = первый участник (не я) или заглушка.
			if len(preview.Members) > 0 {
				preview.User = preview.Members[0]
			}
		}
		items = append(items, preview)
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
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body StartChatBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid target_user_id")
		return
	}

	chatID, err := store.EnsureDirectChat(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeChatError(w, r, err)
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
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("chat_id")))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	actorID, err := h.resolveChatActor(r, userID, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	kind, err := store.ChatKind(r.Context(), h.Pool, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	emojiOnly := false
	if kind != store.ChatKindGroup {
		ids, err := store.ListChatMemberIDs(r.Context(), h.Pool, chatID)
		if err != nil || len(ids) < 2 {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		peerID := ids[0]
		if peerID == actorID {
			peerID = ids[1]
		}
		if !store.UserIsSupport(r.Context(), h.Pool, actorID) &&
			!store.UserIsSupport(r.Context(), h.Pool, peerID) {
			peerSettings, err := store.GetUserSettings(r.Context(), h.Pool, peerID)
			if err != nil {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
			if peerSettings.MessagesFriendsOnly {
				friends, err := store.AreFriends(r.Context(), h.Pool, actorID, peerID)
				if err != nil {
					WriteErr(w, r, http.StatusInternalServerError, "server error")
					return
				}
				emojiOnly = !friends
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"can_send_text": !emojiOnly,
		"emoji_only":    emojiOnly,
		"kind":          kind,
	})
}

func (h *ChatsHandler) Messages(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		h.listMessages(w, r)
	case http.MethodPost:
		h.sendMessage(w, r)
	default:
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *ChatsHandler) listMessages(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	chatIDRaw := strings.TrimSpace(r.URL.Query().Get("chat_id"))
	chatID, err := uuid.Parse(chatIDRaw)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n <= 0 {
			WriteErr(w, r, http.StatusBadRequest, "invalid limit")
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
			WriteErr(w, r, http.StatusBadRequest, "invalid before")
			return
		}
		value := t.UTC()
		before = &value
	}

	actorID, err := h.resolveChatActor(r, userID, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	messages, err := store.ListChatMessages(r.Context(), h.Pool, chatID, actorID, limit, before)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	// Открытие/синхронизация чата = доставка входящих (как в Telegram).
	if ids, deliverErr := store.MarkChatDelivered(r.Context(), h.Pool, chatID, actorID); deliverErr == nil && len(ids) > 0 {
		if members, pairErr := chatMemberIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				members,
				chatID.String(),
				actorID.String(),
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
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body SendChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	opts := store.SendChatOptions{Body: body.Body}
	if raw := strings.TrimSpace(body.ReplyToMessageID); raw != "" {
		rid, err := uuid.Parse(raw)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid reply_to_message_id")
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
			WriteErr(w, r, http.StatusBadRequest, "invalid image_base64")
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
			WriteErr(w, r, http.StatusBadRequest, "invalid image_base64")
			return
		}
		opts.ImageData = img
		opts.ImageMime = body.ImageMime
		if strings.TrimSpace(opts.ImageMime) == "" {
			opts.ImageMime = "image/jpeg"
		}
	}

	actorID, err := h.resolveChatActor(r, userID, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	msg, err := store.SendChatMessageOpts(r.Context(), h.Pool, chatID, actorID, opts)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	item := chatMessageToItem(msg)
	if members, pairErr := chatMemberIDs(r.Context(), h.Pool, chatID); pairErr == nil {
		h.publishChatMessage(members, item)
		h.publishChatListChanged(members...)

		for _, peerID := range members {
			if peerID == actorID {
				continue
			}
			if h.Hub != nil && h.Hub.IsUserOnline(peerID) {
				if ids, err := store.MarkChatDelivered(r.Context(), h.Pool, chatID, peerID); err == nil && len(ids) > 0 {
					h.publishChatDelivered(
						members,
						chatID.String(),
						peerID.String(),
						ids,
					)
					deliveredAt := time.Now().UTC().Format(time.RFC3339Nano)
					item.DeliveredAt = &deliveredAt
				}
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
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body EditChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(body.MessageID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid message_id")
		return
	}
	chatIDForActor, lookupErr := store.ChatIDOfMessage(r.Context(), h.Pool, messageID)
	if lookupErr != nil {
		writeChatError(w, r, lookupErr)
		return
	}
	actorID, err := h.resolveChatActor(r, userID, chatIDForActor)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	msg, err := store.EditChatMessage(r.Context(), h.Pool, messageID, actorID, body.Body)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	item := chatMessageToItem(msg)
	if members, pairErr := chatMemberIDs(r.Context(), h.Pool, msg.ChatID); pairErr == nil {
		h.publishChatMessageUpdated(members, item)
		h.publishChatListChanged(members...)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": item,
	})
}

func (h *ChatsHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body DeleteChatMessageBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(body.MessageID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid message_id")
		return
	}
	chatIDForActor, lookupErr := store.ChatIDOfMessage(r.Context(), h.Pool, messageID)
	if lookupErr != nil {
		writeChatError(w, r, lookupErr)
		return
	}
	actorID, err := h.resolveChatActor(r, userID, chatIDForActor)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	chatID, err := store.DeleteChatMessage(r.Context(), h.Pool, messageID, actorID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	if members, pairErr := chatMemberIDs(r.Context(), h.Pool, chatID); pairErr == nil {
		h.publishChatMessageDeleted(members, chatID.String(), messageID.String())
		h.publishChatListChanged(members...)
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) MessageImage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	messageID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("message_id")))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid message_id")
		return
	}
	index := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("index")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 0 || n >= store.MaxChatImagesPerMessage {
			WriteErr(w, r, http.StatusBadRequest, "invalid index")
			return
		}
		index = n
	}
	chatIDHint, lookupErr := store.ChatIDOfMessage(r.Context(), h.Pool, messageID)
	if lookupErr != nil {
		writeChatError(w, r, lookupErr)
		return
	}
	actorID, err := h.resolveChatActor(r, userID, chatIDHint)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	mime, data, _, err := store.GetChatMessageImage(r.Context(), h.Pool, messageID, actorID, index)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", mime)
	w.Header().Set("Cache-Control", "private, max-age=3600")
	_, _ = w.Write(data)
}

func (h *ChatsHandler) Read(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body MarkChatReadBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	actorID, err := h.resolveChatActor(r, userID, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	updatedIDs, err := store.MarkChatRead(r.Context(), h.Pool, chatID, actorID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	kind, _ := store.ChatKind(r.Context(), h.Pool, chatID)
	if kind == store.ChatKindGroup {
		// Per-user unread: обновляем список только у читателя.
		h.publishChatListChanged(actorID)
	} else if len(updatedIDs) > 0 {
		if members, pairErr := chatMemberIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatRead(
				members,
				chatID.String(),
				actorID.String(),
				updatedIDs,
			)
			h.publishChatListChanged(members...)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": len(updatedIDs)})
}

func (h *ChatsHandler) Delivered(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body MarkChatDeliveredBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	actorID, err := h.resolveChatActor(r, userID, chatID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	updatedIDs, err := store.MarkChatDelivered(r.Context(), h.Pool, chatID, actorID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}

	if len(updatedIDs) > 0 {
		if members, pairErr := chatMemberIDs(r.Context(), h.Pool, chatID); pairErr == nil {
			h.publishChatDelivered(
				members,
				chatID.String(),
				actorID.String(),
				updatedIDs,
			)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"updated": len(updatedIDs)})
}

func (h *ChatsHandler) Clear(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body ClearChatBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	chatID, err := uuid.Parse(strings.TrimSpace(body.ChatID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid chat_id")
		return
	}

	lowID, highID, err := store.ClearChatForUser(r.Context(), h.Pool, chatID, userID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	h.publishChatListChanged(lowID, highID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Block(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body ChatUserActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid target_user_id")
		return
	}

	_, err = store.BlockUser(r.Context(), h.Pool, userID, targetID)
	if err != nil {
		writeChatError(w, r, err)
		return
	}
	h.publishChatListChanged(userID, targetID)
	h.publishFriendsUpdated(userID, targetID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Unblock(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var body ChatUserActionBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	targetID, err := uuid.Parse(strings.TrimSpace(body.TargetUserID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid target_user_id")
		return
	}

	if err := store.UnblockUser(r.Context(), h.Pool, userID, targetID); err != nil {
		writeChatError(w, r, err)
		return
	}
	h.publishChatListChanged(userID, targetID)
	h.publishFriendsUpdated(userID, targetID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *ChatsHandler) Blocked(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := currentChatUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	blocked, err := store.ListBlockedUsers(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
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
	payload := map[string]any{
		"type":    "chat_message",
		"chat_id": item.ChatID,
		"message": item,
	}
	h.Hub.PublishToUsers(userIDs, payload)
	h.mirrorSupportChatToAdmins(userIDs, payload)
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
	lang := i18n.LangRU
	from := pushUserLabel(context.Background(), h.Pool, senderID)
	body := strings.TrimSpace(item.Body)
	photo := i18n.Content(lang, "push.photo")
	if item.HasImage && body == "" {
		if item.ImageCount > 1 {
			body = i18n.Contentf(lang, "push.photo_n", map[string]string{"n": fmt.Sprintf("%d", item.ImageCount)})
		} else {
			body = photo
		}
	} else if item.HasImage {
		if item.ImageCount > 1 {
			body = i18n.Contentf(lang, "push.photo_n", map[string]string{"n": fmt.Sprintf("%d", item.ImageCount)}) + ": " + body
		} else {
			body = photo + ": " + body
		}
	}
	if len([]rune(body)) > 120 {
		runes := []rune(body)
		body = string(runes[:117]) + "…"
	}
	if body == "" {
		body = i18n.Content(lang, "push.new_message")
	}
	h.Push.NotifyUsers(recipients, store.WebPushCategoryChat, PushPayload{
		Title:  from,
		Body:   body,
		URL:    "/chats/" + item.ChatID,
		Tag:    "chat_" + item.ChatID,
		Kind:   "chat",
		ChatID: item.ChatID,
	})
}

func (h *ChatsHandler) publishChatMessageUpdated(userIDs []uuid.UUID, item ChatMessageItem) {
	if h == nil || h.Hub == nil {
		return
	}
	payload := map[string]any{
		"type":    "chat_message_updated",
		"chat_id": item.ChatID,
		"message": item,
	}
	h.Hub.PublishToUsers(userIDs, payload)
	h.mirrorSupportChatToAdmins(userIDs, payload)
}

func (h *ChatsHandler) publishChatMessageDeleted(userIDs []uuid.UUID, chatID, messageID string) {
	if h == nil || h.Hub == nil {
		return
	}
	payload := map[string]any{
		"type":       "chat_message_deleted",
		"chat_id":    chatID,
		"message_id": messageID,
	}
	h.Hub.PublishToUsers(userIDs, payload)
	h.mirrorSupportChatToAdmins(userIDs, payload)
}

// mirrorSupportChatToAdmins дублирует событие чата всем админам,
// чтобы комната поддержки в админке обновлялась как обычный диалог.
func (h *ChatsHandler) mirrorSupportChatToAdmins(memberIDs []uuid.UUID, event map[string]any) {
	if h == nil || h.Hub == nil || h.Pool == nil || len(memberIDs) == 0 {
		return
	}
	ctx := context.Background()
	su, err := store.GetSupportUser(ctx, h.Pool)
	if err != nil || su == nil {
		return
	}
	var peerID uuid.UUID
	foundSupport := false
	for _, id := range memberIDs {
		if id == su.ID {
			foundSupport = true
		} else {
			peerID = id
		}
	}
	if !foundSupport {
		return
	}
	admins, err := store.ListAdminIDs(ctx, h.Pool)
	if err != nil || len(admins) == 0 {
		return
	}
	h.Hub.PublishToUsers(admins, event)
	if event["type"] == "chat_message" {
		h.Hub.PublishToUsers(admins, map[string]any{
			"type":    "support_message",
			"user_id": peerID.String(),
			"chat_id": event["chat_id"],
		})
	}
}

func (h *ChatsHandler) publishChatListChanged(userIDs ...uuid.UUID) {
	if h == nil || h.Hub == nil || len(userIDs) == 0 {
		return
	}
	h.Hub.PublishToUsers(userIDs, map[string]any{
		"type": "chat_list_changed",
	})
}

// cleanupOrphanGroupChats удаляет групповые чаты, чьё лобби уже нет в Redis
// (партия закончилась / лобби истекло).
func (h *ChatsHandler) cleanupOrphanGroupChats(ctx context.Context, userID uuid.UUID) {
	if h == nil || h.Pool == nil || h.Rdb == nil {
		return
	}
	lobbyIDs, err := store.ListUserGroupLobbyIDs(ctx, h.Pool, userID)
	if err != nil || len(lobbyIDs) == 0 {
		return
	}
	removed := 0
	for _, lobbyID := range lobbyIDs {
		n, err := h.Rdb.Exists(ctx, "lobby:"+lobbyID).Result()
		if err != nil {
			continue
		}
		if n > 0 {
			continue
		}
		if err := store.DeleteGameGroupChatByLobby(ctx, h.Pool, lobbyID); err == nil {
			removed++
		}
	}
	if removed > 0 {
		h.publishChatListChanged(userID)
	}
}

func uuidSliceToStrings(ids []uuid.UUID) []string {
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		out = append(out, id.String())
	}
	return out
}

func chatMemberIDs(ctx context.Context, pool *pgxpool.Pool, chatID uuid.UUID) ([]uuid.UUID, error) {
	return store.ChatBroadcastUserIDs(ctx, pool, chatID)
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
		members, pairErr := chatMemberIDs(ctx, pool, batch.ChatID)
		if pairErr != nil {
			continue
		}
		hub.PublishToUsers(members, map[string]any{
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
