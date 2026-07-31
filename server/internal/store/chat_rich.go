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
	ErrChatDeleteForbidden   = errors.New("cannot delete this message")
	ErrChatReplyInvalid      = errors.New("invalid reply target")
)

// MaxChatImageBytes — жёсткий лимит после клиентского сжатия (~200 КБ цель).
const MaxChatImageBytes = 256 * 1024

// MaxChatImagesPerMessage — сколько фото в одном сообщении.
const MaxChatImagesPerMessage = 3

// ChatImageInput — одно сжатое фото для отправки.
type ChatImageInput struct {
	Mime string
	Data []byte
}

// SendChatOptions — текст, опционально ответ и/или фото.
type SendChatOptions struct {
	Body             string
	ReplyToMessageID *uuid.UUID
	// Images — 1..3 фото; ImageData/ImageMime — устаревший одиночный вариант.
	Images    []ChatImageInput
	ImageMime string
	ImageData []byte
}

func collectSendImages(opts SendChatOptions) ([]ChatImageInput, error) {
	out := make([]ChatImageInput, 0, MaxChatImagesPerMessage)
	for _, img := range opts.Images {
		if len(img.Data) == 0 {
			continue
		}
		mime, err := normalizeImageMime(img.Mime)
		if err != nil {
			return nil, err
		}
		if len(img.Data) > MaxChatImageBytes {
			return nil, ErrChatImageTooLarge
		}
		out = append(out, ChatImageInput{Mime: mime, Data: img.Data})
		if len(out) >= MaxChatImagesPerMessage {
			break
		}
	}
	if len(out) == 0 && len(opts.ImageData) > 0 {
		mime, err := normalizeImageMime(opts.ImageMime)
		if err != nil {
			return nil, err
		}
		if len(opts.ImageData) > MaxChatImageBytes {
			return nil, ErrChatImageTooLarge
		}
		out = append(out, ChatImageInput{Mime: mime, Data: opts.ImageData})
	}
	return out, nil
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
		&msg.ImageCount,
		&replyBody,
		&replyHasImage,
		&replySender,
	); err != nil {
		return ChatMessage{}, err
	}
	msg.CreatedAt = msg.CreatedAt.UTC()
	if msg.HasImage && msg.ImageCount <= 0 {
		msg.ImageCount = 1
	}
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
		COALESCE(m.image_count, 0),
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
	images, err := collectSendImages(opts)
	if err != nil {
		return ChatMessage{}, err
	}
	hasImage := len(images) > 0
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
	imageCount := 0
	if hasImage {
		imageCount = len(images)
		imageData = images[0].Data
		imageMime = images[0].Mime
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return ChatMessage{}, err
	}
	defer tx.Rollback(ctx)

	var newID uuid.UUID
	err = tx.QueryRow(ctx, `
		INSERT INTO chat_messages (
			chat_id, sender_user_id, body,
			reply_to_message_id, has_image, image_count, image_mime, image_data
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, chatID, senderUserID, text, replyArg, hasImage, imageCount, imageMime, imageData).Scan(&newID)
	if err != nil {
		return ChatMessage{}, err
	}
	for i, img := range images {
		_, err = tx.Exec(ctx, `
			INSERT INTO chat_message_images (message_id, idx, image_mime, image_data)
			VALUES ($1, $2, $3, $4)
		`, newID, i, img.Mime, img.Data)
		if err != nil {
			return ChatMessage{}, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
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

// GetChatMessageImage отдаёт байты картинки участнику чата (index 0..2).
func GetChatMessageImage(
	ctx context.Context,
	pool *pgxpool.Pool,
	messageID, currentUserID uuid.UUID,
	index int,
) (mime string, data []byte, chatID uuid.UUID, err error) {
	if index < 0 {
		index = 0
	}
	var hasImage bool
	err = pool.QueryRow(ctx, `
		SELECT m.chat_id, m.has_image
		FROM chat_messages m
		WHERE m.id = $1
	`, messageID).Scan(&chatID, &hasImage)
	if err == pgx.ErrNoRows {
		return "", nil, uuid.Nil, ErrChatMessageNotFound
	}
	if err != nil {
		return "", nil, uuid.Nil, err
	}
	if !hasImage {
		return "", nil, uuid.Nil, ErrChatImageMissing
	}
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return "", nil, uuid.Nil, err
	}

	err = pool.QueryRow(ctx, `
		SELECT image_mime, image_data
		FROM chat_message_images
		WHERE message_id = $1 AND idx = $2
	`, messageID, index).Scan(&mime, &data)
	if err == nil && len(data) > 0 {
		return mime, data, chatID, nil
	}
	if err != nil && err != pgx.ErrNoRows {
		return "", nil, uuid.Nil, err
	}

	if index == 0 {
		err = pool.QueryRow(ctx, `
			SELECT image_mime, image_data
			FROM chat_messages
			WHERE id = $1 AND has_image = TRUE
		`, messageID).Scan(&mime, &data)
		if err == pgx.ErrNoRows || len(data) == 0 {
			return "", nil, uuid.Nil, ErrChatImageMissing
		}
		if err != nil {
			return "", nil, uuid.Nil, err
		}
		return mime, data, chatID, nil
	}
	return "", nil, uuid.Nil, ErrChatImageMissing
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

// DeleteChatMessage удаляет сообщение для всех участников чата.
// Свои сообщения — всегда; чужие — только invite-ссылки на «Свою игру»
// (чтобы приглашённый мог убрать карточку после входа в матч).
func DeleteChatMessage(
	ctx context.Context,
	pool *pgxpool.Pool,
	messageID, actorUserID uuid.UUID,
) (chatID uuid.UUID, err error) {
	var senderID uuid.UUID
	var body string
	err = pool.QueryRow(ctx, `
		SELECT chat_id, sender_user_id, body
		FROM chat_messages WHERE id = $1
	`, messageID).Scan(&chatID, &senderID, &body)
	if err == pgx.ErrNoRows {
		return uuid.Nil, ErrChatMessageNotFound
	}
	if err != nil {
		return uuid.Nil, err
	}
	if senderID != actorUserID && !IsInviteLobbyShareBody(body) {
		return uuid.Nil, ErrChatDeleteForbidden
	}
	if err := ensureChatMembership(ctx, pool, chatID, actorUserID); err != nil {
		return uuid.Nil, err
	}
	ct, err := pool.Exec(ctx, `DELETE FROM chat_messages WHERE id = $1`, messageID)
	if err != nil {
		return uuid.Nil, err
	}
	if ct.RowsAffected() == 0 {
		return uuid.Nil, ErrChatMessageNotFound
	}
	return chatID, nil
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
