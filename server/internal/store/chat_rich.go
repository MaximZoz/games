package store

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrChatMessageNotFound   = errors.New("chat message not found")
	ErrChatImageMissing      = errors.New("chat image missing")
	ErrChatImageTooLarge     = errors.New("chat image is too large")
	ErrChatImageUnsupported  = errors.New("unsupported chat image type")
	ErrChatEditForbidden     = errors.New("cannot edit this message")
	ErrChatReplyInvalid      = errors.New("invalid reply target")
)

const MaxChatImageBytes = 3 * 1024 * 1024

// SendChatOptions — текст, опционально ответ и/или фото.
type SendChatOptions struct {
	Body             string
	ReplyToMessageID *uuid.UUID
	ImageMime        string
	ImageData        []byte
}

func normalizeImageMime(mime string) (string, error) {
	m := strings.ToLower(strings.TrimSpace(mime))
	switch m {
	case "image/jpeg", "image/jpg":
		return "image/jpeg", nil
	case "image/png":
		return "image/png", nil
	case "image/webp":
		return "image/webp", nil
	case "image/gif":
		return "image/gif", nil
	default:
		return "", ErrChatImageUnsupported
	}
}

func scanChatMessageRow(
	scan func(dest ...any) error,
) (ChatMessage, error) {
	var msg ChatMessage
	var deliveredAt sql.NullTime
	var readAt sql.NullTime
	var editedAt sql.NullTime
	var replyToID uuid.NullUUID
	var replyBody sql.NullString
	var replyHasImage sql.NullBool
	var replySender uuid.NullUUID
	if err := scan(
		&msg.ID,
		&msg.ChatID,
		&msg.SenderUserID,
		&msg.Body,
		&msg.CreatedAt,
		&deliveredAt,
		&readAt,
		&editedAt,
		&replyToID,
		&msg.HasImage,
		&replyBody,
		&replyHasImage,
		&replySender,
	); err != nil {
		return ChatMessage{}, err
	}
	msg.CreatedAt = msg.CreatedAt.UTC()
	if deliveredAt.Valid {
		v := deliveredAt.Time.UTC()
		msg.DeliveredAt = &v
	}
	if readAt.Valid {
		v := readAt.Time.UTC()
		msg.ReadAt = &v
	}
	if editedAt.Valid {
		v := editedAt.Time.UTC()
		msg.EditedAt = &v
	}
	if replyToID.Valid {
		id := replyToID.UUID
		msg.ReplyToMessageID = &id
		if replyBody.Valid {
			msg.ReplyToBody = replyBody.String
		}
		msg.ReplyToHasImage = replyHasImage.Valid && replyHasImage.Bool
		if replySender.Valid {
			sid := replySender.UUID
			msg.ReplyToSenderID = &sid
		}
	}
	return msg, nil
}

const chatMessageSelectSQL = `
	SELECT
		m.id, m.chat_id, m.sender_user_id, m.body, m.created_at,
		m.delivered_at, m.read_at, m.edited_at, m.reply_to_message_id, m.has_image,
		r.body, r.has_image, r.sender_user_id
	FROM chat_messages m
	LEFT JOIN chat_messages r ON r.id = m.reply_to_message_id
`

// SendChatMessageOpts отправляет сообщение с опциональным фото и reply.
func SendChatMessageOpts(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, senderUserID uuid.UUID,
	opts SendChatOptions,
) (ChatMessage, error) {
	text := strings.TrimSpace(opts.Body)
	hasImage := len(opts.ImageData) > 0
	var mime string
	if hasImage {
		var err error
		mime, err = normalizeImageMime(opts.ImageMime)
		if err != nil {
			return ChatMessage{}, err
		}
		if len(opts.ImageData) > MaxChatImageBytes {
			return ChatMessage{}, ErrChatImageTooLarge
		}
	}
	if !hasImage && text == "" {
		return ChatMessage{}, ErrChatMessageEmpty
	}
	if utf8.RuneCountInString(text) > 2000 {
		return ChatMessage{}, ErrChatMessageTooLong
	}

	if err := ensureChatMembership(ctx, pool, chatID, senderUserID); err != nil {
		return ChatMessage{}, err
	}

	lowID, highID, err := ChatParticipantIDs(ctx, pool, chatID)
	if err != nil {
		return ChatMessage{}, err
	}
	peerID := highID
	if senderUserID == highID {
		peerID = lowID
	}
	blocked, err := IsUsersBlocked(ctx, pool, senderUserID, peerID)
	if err != nil {
		return ChatMessage{}, err
	}
	if blocked {
		return ChatMessage{}, ErrUserBlocked
	}

	peerSettings, err := GetUserSettings(ctx, pool, peerID)
	if err != nil {
		return ChatMessage{}, err
	}
	if peerSettings.MessagesFriendsOnly {
		friends, err := AreFriends(ctx, pool, senderUserID, peerID)
		if err != nil {
			return ChatMessage{}, err
		}
		if !friends {
			// Фото и свободный текст — только друзьям; смайлики/подарки — ок.
			if hasImage || !IsRestrictedChatMessageAllowed(text) {
				return ChatMessage{}, ErrChatFriendsOnlyText
			}
		}
	}

	if opts.ReplyToMessageID != nil {
		var replyChatID uuid.UUID
		err := pool.QueryRow(ctx, `
			SELECT chat_id FROM chat_messages WHERE id = $1
		`, *opts.ReplyToMessageID).Scan(&replyChatID)
		if err == pgx.ErrNoRows {
			return ChatMessage{}, ErrChatReplyInvalid
		}
		if err != nil {
			return ChatMessage{}, err
		}
		if replyChatID != chatID {
			return ChatMessage{}, ErrChatReplyInvalid
		}
	}

	var replyArg any
	if opts.ReplyToMessageID != nil {
		replyArg = *opts.ReplyToMessageID
	}

	var imageData any
	var imageMime any
	if hasImage {
		imageData = opts.ImageData
		imageMime = mime
	}

	var newID uuid.UUID
	err = pool.QueryRow(ctx, `
		INSERT INTO chat_messages (
			chat_id, sender_user_id, body,
			reply_to_message_id, has_image, image_mime, image_data
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id
	`, chatID, senderUserID, text, replyArg, hasImage, imageMime, imageData).Scan(&newID)
	if err != nil {
		return ChatMessage{}, err
	}
	return GetChatMessageByID(ctx, pool, chatID, senderUserID, newID)
}

// GetChatMessageByID возвращает сообщение (без image_data), если пользователь в чате.
func GetChatMessageByID(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID, messageID uuid.UUID,
) (ChatMessage, error) {
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return ChatMessage{}, err
	}
	row := pool.QueryRow(ctx, chatMessageSelectSQL+`
		WHERE m.id = $1 AND m.chat_id = $2
	`, messageID, chatID)
	msg, err := scanChatMessageRow(row.Scan)
	if err == pgx.ErrNoRows {
		return ChatMessage{}, ErrChatMessageNotFound
	}
	return msg, err
}

// GetChatMessageImage отдаёт байты картинки участнику чата.
func GetChatMessageImage(
	ctx context.Context,
	pool *pgxpool.Pool,
	messageID, currentUserID uuid.UUID,
) (mime string, data []byte, chatID uuid.UUID, err error) {
	var hasImage bool
	err = pool.QueryRow(ctx, `
		SELECT m.chat_id, m.image_mime, m.image_data, m.has_image
		FROM chat_messages m
		WHERE m.id = $1
	`, messageID).Scan(&chatID, &mime, &data, &hasImage)
	if err == pgx.ErrNoRows {
		return "", nil, uuid.Nil, ErrChatMessageNotFound
	}
	if err != nil {
		return "", nil, uuid.Nil, err
	}
	if !hasImage || len(data) == 0 {
		return "", nil, uuid.Nil, ErrChatImageMissing
	}
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return "", nil, uuid.Nil, err
	}
	return mime, data, chatID, nil
}

// EditChatMessage меняет текст своего сообщения (фото не трогаем).
func EditChatMessage(
	ctx context.Context,
	pool *pgxpool.Pool,
	messageID, editorUserID uuid.UUID,
	newBody string,
) (ChatMessage, error) {
	text := strings.TrimSpace(newBody)
	if utf8.RuneCountInString(text) > 2000 {
		return ChatMessage{}, ErrChatMessageTooLong
	}

	var chatID uuid.UUID
	var senderID uuid.UUID
	var hasImage bool
	err := pool.QueryRow(ctx, `
		SELECT chat_id, sender_user_id, has_image
		FROM chat_messages WHERE id = $1
	`, messageID).Scan(&chatID, &senderID, &hasImage)
	if err == pgx.ErrNoRows {
		return ChatMessage{}, ErrChatMessageNotFound
	}
	if err != nil {
		return ChatMessage{}, err
	}
	if senderID != editorUserID {
		return ChatMessage{}, ErrChatEditForbidden
	}
	if err := ensureChatMembership(ctx, pool, chatID, editorUserID); err != nil {
		return ChatMessage{}, err
	}
	if !hasImage && text == "" {
		return ChatMessage{}, ErrChatMessageEmpty
	}

	_, err = pool.Exec(ctx, `
		UPDATE chat_messages
		SET body = $2, edited_at = now()
		WHERE id = $1
	`, messageID, text)
	if err != nil {
		return ChatMessage{}, err
	}
	return GetChatMessageByID(ctx, pool, chatID, editorUserID, messageID)
}

// ListChatMessagesRich — список с reply/edited/has_image (без байтов фото).
func ListChatMessagesRich(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID uuid.UUID,
	limit int,
	before *time.Time,
) ([]ChatMessage, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return nil, err
	}

	var (
		rows pgx.Rows
		err  error
	)
	if before != nil {
		rows, err = pool.Query(ctx, chatMessageSelectSQL+`
			WHERE m.chat_id = $1 AND m.created_at < $3
			ORDER BY m.created_at DESC
			LIMIT $2
		`, chatID, limit, before.UTC())
	} else {
		rows, err = pool.Query(ctx, chatMessageSelectSQL+`
			WHERE m.chat_id = $1
			ORDER BY m.created_at DESC
			LIMIT $2
		`, chatID, limit)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := make([]ChatMessage, 0, limit)
	for rows.Next() {
		msg, err := scanChatMessageRow(rows.Scan)
		if err != nil {
			return nil, err
		}
		messages = append(messages, msg)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for left, right := 0, len(messages)-1; left < right; {
		messages[left], messages[right] = messages[right], messages[left]
		left++
		right--
	}
	return messages, nil
}
