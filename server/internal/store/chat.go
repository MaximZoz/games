package store

import (
	"context"
	"database/sql"
	"errors"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrChatNotFound           = errors.New("chat not found")
	ErrChatForbidden          = errors.New("chat action forbidden")
	ErrCannotChatWithYourself = errors.New("cannot chat with yourself")
	ErrChatMessageEmpty       = errors.New("chat message is empty")
	ErrChatMessageTooLong     = errors.New("chat message is too long")
	ErrChatFriendsOnlyText    = errors.New("only friends can send text messages")
	ErrUserBlocked            = errors.New("user is blocked")
	ErrCannotBlockYourself    = errors.New("cannot block yourself")
	ErrUserNotFound           = errors.New("user not found")
)

// Токены, разрешённые не-друзьям при messages_friends_only у получателя.
var (
	animatedEmojiTokenRe  = regexp.MustCompile(`^\[ae:[A-Za-z0-9_]+\]$`)
	giftCollectionTokenRe = regexp.MustCompile(
		`^\[gift_coll:[^|\]]+\|[^|\]]*\|[^|\]]*\|[^\]]*\]$`,
	)
)

// IsRestrictedChatMessageAllowed — смайлик или подарок коллекции (не свободный текст).
func IsRestrictedChatMessageAllowed(body string) bool {
	text := strings.TrimSpace(body)
	return animatedEmojiTokenRe.MatchString(text) || giftCollectionTokenRe.MatchString(text)
}

type ChatMessage struct {
	ID           uuid.UUID
	ChatID       uuid.UUID
	SenderUserID uuid.UUID
	Body         string
	CreatedAt    time.Time
	DeliveredAt  *time.Time
	ReadAt       *time.Time
}

type ChatUser struct {
	ID          uuid.UUID
	Email       string
	DisplayName *string
	AvatarKind  string
	AvatarValue *string
	Age         *int
	Gender      *string
	About       *string
}

type ChatPreview struct {
	ChatID      uuid.UUID
	Peer        ChatUser
	CreatedAt   time.Time
	LastMessage *ChatMessage
	UnreadCount int
	UpdatedAt   time.Time
}

type ChatBlockedUser struct {
	User      ChatUser
	BlockedAt time.Time
}

func orderedChatPair(a, b uuid.UUID) (uuid.UUID, uuid.UUID) {
	if strings.Compare(a.String(), b.String()) < 0 {
		return a, b
	}
	return b, a
}

func EnsureDirectChat(
	ctx context.Context,
	pool *pgxpool.Pool,
	currentUserID, targetUserID uuid.UUID,
) (uuid.UUID, error) {
	if currentUserID == targetUserID {
		return uuid.Nil, ErrCannotChatWithYourself
	}

	targetExists, err := userExists(ctx, pool, targetUserID)
	if err != nil {
		return uuid.Nil, err
	}
	if !targetExists {
		return uuid.Nil, ErrChatNotFound
	}

	blocked, err := IsUsersBlocked(ctx, pool, currentUserID, targetUserID)
	if err != nil {
		return uuid.Nil, err
	}
	if blocked {
		return uuid.Nil, ErrUserBlocked
	}

	low, high := orderedChatPair(currentUserID, targetUserID)
	_, err = pool.Exec(ctx, `
		INSERT INTO chats (user_low, user_high)
		VALUES ($1, $2)
		ON CONFLICT (user_low, user_high) DO NOTHING
	`, low, high)
	if err != nil {
		return uuid.Nil, err
	}

	var chatID uuid.UUID
	err = pool.QueryRow(ctx, `
		SELECT id
		FROM chats
		WHERE user_low = $1 AND user_high = $2
	`, low, high).Scan(&chatID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return uuid.Nil, ErrChatNotFound
		}
		return uuid.Nil, err
	}
	return chatID, nil
}

func ListChatsForUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	limit, offset int,
) ([]ChatPreview, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}
	if offset < 0 {
		offset = 0
	}

	rows, err := pool.Query(ctx, `
		WITH my_chats AS (
			SELECT
				c.id,
				c.created_at,
				CASE
					WHEN c.user_low = $1 THEN c.user_high
					ELSE c.user_low
				END AS peer_id
			FROM chats c
			WHERE c.user_low = $1 OR c.user_high = $1
		),
		last_msg AS (
			SELECT DISTINCT ON (m.chat_id)
				m.chat_id,
				m.id,
				m.sender_user_id,
				m.body,
				m.created_at,
				m.delivered_at,
				m.read_at
			FROM chat_messages m
			JOIN my_chats mc ON mc.id = m.chat_id
			ORDER BY m.chat_id, m.created_at DESC
		),
		unread AS (
			SELECT
				m.chat_id,
				COUNT(*)::int AS unread_count
			FROM chat_messages m
			JOIN my_chats mc ON mc.id = m.chat_id
			WHERE m.sender_user_id <> $1 AND m.read_at IS NULL
			GROUP BY m.chat_id
		)
		SELECT
			mc.id,
			mc.created_at,
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about,
			lm.id::text, lm.sender_user_id::text, lm.body, lm.created_at, lm.delivered_at, lm.read_at,
			COALESCE(un.unread_count, 0),
			COALESCE(lm.created_at, mc.created_at) AS updated_at
		FROM my_chats mc
		JOIN users u ON u.id = mc.peer_id
		LEFT JOIN last_msg lm ON lm.chat_id = mc.id
		LEFT JOIN unread un ON un.chat_id = mc.id
		ORDER BY
			CASE WHEN COALESCE(un.unread_count, 0) > 0 THEN 0 ELSE 1 END ASC,
			updated_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]ChatPreview, 0, limit)
	for rows.Next() {
		var item ChatPreview
		var lastMessageIDRaw sql.NullString
		var lastSenderIDRaw sql.NullString
		var lastBody sql.NullString
		var lastCreatedAt sql.NullTime
		var lastDeliveredAt sql.NullTime
		var lastReadAt sql.NullTime

		if err := rows.Scan(
			&item.ChatID,
			&item.CreatedAt,
			&item.Peer.ID,
			&item.Peer.Email,
			&item.Peer.DisplayName,
			&item.Peer.AvatarKind,
			&item.Peer.AvatarValue,
			&item.Peer.Age,
			&item.Peer.Gender,
			&item.Peer.About,
			&lastMessageIDRaw,
			&lastSenderIDRaw,
			&lastBody,
			&lastCreatedAt,
			&lastDeliveredAt,
			&lastReadAt,
			&item.UnreadCount,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}

		item.CreatedAt = item.CreatedAt.UTC()
		item.UpdatedAt = item.UpdatedAt.UTC()
		if lastMessageIDRaw.Valid && lastSenderIDRaw.Valid && lastCreatedAt.Valid {
			messageID, errID := uuid.Parse(lastMessageIDRaw.String)
			senderID, errSender := uuid.Parse(lastSenderIDRaw.String)
			if errID == nil && errSender == nil {
				msg := ChatMessage{
					ID:           messageID,
					ChatID:       item.ChatID,
					SenderUserID: senderID,
					Body:         strings.TrimSpace(lastBody.String),
					CreatedAt:    lastCreatedAt.Time.UTC(),
				}
				if lastDeliveredAt.Valid {
					deliveredAt := lastDeliveredAt.Time.UTC()
					msg.DeliveredAt = &deliveredAt
				}
				if lastReadAt.Valid {
					readAt := lastReadAt.Time.UTC()
					msg.ReadAt = &readAt
				}
				item.LastMessage = &msg
			}
		}

		result = append(result, item)
	}

	return result, rows.Err()
}

func ListChatMessages(
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
		rows, err = pool.Query(ctx, `
			SELECT id, chat_id, sender_user_id, body, created_at, delivered_at, read_at
			FROM chat_messages
			WHERE chat_id = $1 AND created_at < $3
			ORDER BY created_at DESC
			LIMIT $2
		`, chatID, limit, before.UTC())
	} else {
		rows, err = pool.Query(ctx, `
			SELECT id, chat_id, sender_user_id, body, created_at, delivered_at, read_at
			FROM chat_messages
			WHERE chat_id = $1
			ORDER BY created_at DESC
			LIMIT $2
		`, chatID, limit)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := make([]ChatMessage, 0, limit)
	for rows.Next() {
		var msg ChatMessage
		var deliveredAt sql.NullTime
		var readAt sql.NullTime
		if err := rows.Scan(
			&msg.ID,
			&msg.ChatID,
			&msg.SenderUserID,
			&msg.Body,
			&msg.CreatedAt,
			&deliveredAt,
			&readAt,
		); err != nil {
			return nil, err
		}
		msg.CreatedAt = msg.CreatedAt.UTC()
		if deliveredAt.Valid {
			value := deliveredAt.Time.UTC()
			msg.DeliveredAt = &value
		}
		if readAt.Valid {
			value := readAt.Time.UTC()
			msg.ReadAt = &value
		}
		messages = append(messages, msg)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Возвращаем в хронологическом порядке (старые -> новые).
	for left, right := 0, len(messages)-1; left < right; {
		messages[left], messages[right] = messages[right], messages[left]
		left++
		right--
	}
	return messages, nil
}

func SendChatMessage(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, senderUserID uuid.UUID,
	body string,
) (ChatMessage, error) {
	text := strings.TrimSpace(body)
	if text == "" {
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
		if !friends && !IsRestrictedChatMessageAllowed(text) {
			return ChatMessage{}, ErrChatFriendsOnlyText
		}
	}

	var msg ChatMessage
	var deliveredAt sql.NullTime
	var readAt sql.NullTime
	err = pool.QueryRow(ctx, `
		INSERT INTO chat_messages (chat_id, sender_user_id, body)
		VALUES ($1, $2, $3)
		RETURNING id, chat_id, sender_user_id, body, created_at, delivered_at, read_at
	`, chatID, senderUserID, text).Scan(
		&msg.ID,
		&msg.ChatID,
		&msg.SenderUserID,
		&msg.Body,
		&msg.CreatedAt,
		&deliveredAt,
		&readAt,
	)
	if err != nil {
		return ChatMessage{}, err
	}
	msg.CreatedAt = msg.CreatedAt.UTC()
	if deliveredAt.Valid {
		value := deliveredAt.Time.UTC()
		msg.DeliveredAt = &value
	}
	if readAt.Valid {
		value := readAt.Time.UTC()
		msg.ReadAt = &value
	}
	return msg, nil
}

type ChatDeliveryBatch struct {
	ChatID     uuid.UUID
	MessageIDs []uuid.UUID
}

func MarkChatDelivered(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID uuid.UUID,
) ([]uuid.UUID, error) {
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return nil, err
	}

	rows, err := pool.Query(ctx, `
		UPDATE chat_messages
		SET delivered_at = now()
		WHERE chat_id = $1
		  AND sender_user_id <> $2
		  AND delivered_at IS NULL
		RETURNING id
	`, chatID, currentUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	ids := make([]uuid.UUID, 0)
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

// MarkIncomingDeliveredForUser отмечает доставку всех входящих сообщений пользователя
// (увидел превью в списке чатов / подключился онлайн — как в Telegram).
func MarkIncomingDeliveredForUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
) ([]ChatDeliveryBatch, error) {
	rows, err := pool.Query(ctx, `
		UPDATE chat_messages AS m
		SET delivered_at = now()
		FROM chats AS c
		WHERE m.chat_id = c.id
		  AND (c.user_low = $1 OR c.user_high = $1)
		  AND m.sender_user_id <> $1
		  AND m.delivered_at IS NULL
		RETURNING m.chat_id, m.id
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	byChat := make(map[uuid.UUID][]uuid.UUID)
	order := make([]uuid.UUID, 0)
	for rows.Next() {
		var chatID, messageID uuid.UUID
		if err := rows.Scan(&chatID, &messageID); err != nil {
			return nil, err
		}
		if _, ok := byChat[chatID]; !ok {
			order = append(order, chatID)
		}
		byChat[chatID] = append(byChat[chatID], messageID)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	batches := make([]ChatDeliveryBatch, 0, len(order))
	for _, chatID := range order {
		batches = append(batches, ChatDeliveryBatch{
			ChatID:     chatID,
			MessageIDs: byChat[chatID],
		})
	}
	return batches, nil
}

func MarkChatRead(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID uuid.UUID,
) ([]uuid.UUID, error) {
	if err := ensureChatMembership(ctx, pool, chatID, currentUserID); err != nil {
		return nil, err
	}

	rows, err := pool.Query(ctx, `
		UPDATE chat_messages
		SET read_at = now(),
		    delivered_at = COALESCE(delivered_at, now())
		WHERE chat_id = $1
		  AND sender_user_id <> $2
		  AND read_at IS NULL
		RETURNING id
	`, chatID, currentUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	ids := make([]uuid.UUID, 0)
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func IsUsersBlocked(
	ctx context.Context,
	pool *pgxpool.Pool,
	userA, userB uuid.UUID,
) (bool, error) {
	var exists int
	err := pool.QueryRow(ctx, `
		SELECT 1
		FROM user_blocks ub
		WHERE
			(ub.blocker_user_id = $1 AND ub.blocked_user_id = $2)
			OR
			(ub.blocker_user_id = $2 AND ub.blocked_user_id = $1)
		LIMIT 1
	`, userA, userB).Scan(&exists)
	if err != nil {
		if err == pgx.ErrNoRows {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func ClearChatForUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID uuid.UUID,
) (uuid.UUID, uuid.UUID, error) {
	lowID, highID, err := ChatParticipantIDs(ctx, pool, chatID)
	if err != nil {
		return uuid.Nil, uuid.Nil, err
	}
	if currentUserID != lowID && currentUserID != highID {
		return uuid.Nil, uuid.Nil, ErrChatForbidden
	}

	tag, err := pool.Exec(ctx, `
		DELETE FROM chats
		WHERE id = $1
	`, chatID)
	if err != nil {
		return uuid.Nil, uuid.Nil, err
	}
	if tag.RowsAffected() == 0 {
		return uuid.Nil, uuid.Nil, ErrChatNotFound
	}
	return lowID, highID, nil
}

func BlockUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	blockerUserID, blockedUserID uuid.UUID,
) (bool, error) {
	if blockerUserID == blockedUserID {
		return false, ErrCannotBlockYourself
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)

	var exists int
	err = tx.QueryRow(ctx, `
		SELECT 1
		FROM users
		WHERE id = $1
	`, blockedUserID).Scan(&exists)
	if err != nil {
		if err == pgx.ErrNoRows {
			return false, ErrUserNotFound
		}
		return false, err
	}

	insertTag, err := tx.Exec(ctx, `
		INSERT INTO user_blocks (blocker_user_id, blocked_user_id)
		VALUES ($1, $2)
		ON CONFLICT (blocker_user_id, blocked_user_id) DO NOTHING
	`, blockerUserID, blockedUserID)
	if err != nil {
		return false, err
	}
	created := insertTag.RowsAffected() > 0

	_, err = tx.Exec(ctx, `
		DELETE FROM friend_requests
		WHERE
			(sender_user_id = $1 AND receiver_user_id = $2)
			OR
			(sender_user_id = $2 AND receiver_user_id = $1)
	`, blockerUserID, blockedUserID)
	if err != nil {
		return false, err
	}

	friendLow, friendHigh := orderedUserPair(blockerUserID, blockedUserID)
	_, err = tx.Exec(ctx, `
		DELETE FROM friendships
		WHERE user_low = $1 AND user_high = $2
	`, friendLow, friendHigh)
	if err != nil {
		return false, err
	}

	chatLow, chatHigh := orderedChatPair(blockerUserID, blockedUserID)
	_, err = tx.Exec(ctx, `
		DELETE FROM chats
		WHERE user_low = $1 AND user_high = $2
	`, chatLow, chatHigh)
	if err != nil {
		return false, err
	}

	if err := tx.Commit(ctx); err != nil {
		return false, err
	}
	return created, nil
}

func UnblockUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	blockerUserID, blockedUserID uuid.UUID,
) error {
	if blockerUserID == blockedUserID {
		return ErrCannotBlockYourself
	}

	_, err := pool.Exec(ctx, `
		DELETE FROM user_blocks
		WHERE blocker_user_id = $1 AND blocked_user_id = $2
	`, blockerUserID, blockedUserID)
	return err
}

func ListBlockedUsers(
	ctx context.Context,
	pool *pgxpool.Pool,
	blockerUserID uuid.UUID,
) ([]ChatBlockedUser, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about,
			ub.created_at
		FROM user_blocks ub
		JOIN users u ON u.id = ub.blocked_user_id
		WHERE ub.blocker_user_id = $1
		ORDER BY
			CASE WHEN u.display_name IS NULL OR u.display_name = '' THEN 1 ELSE 0 END ASC,
			COALESCE(u.display_name, u.email) ASC
	`, blockerUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]ChatBlockedUser, 0)
	for rows.Next() {
		var item ChatBlockedUser
		if err := rows.Scan(
			&item.User.ID,
			&item.User.Email,
			&item.User.DisplayName,
			&item.User.AvatarKind,
			&item.User.AvatarValue,
			&item.User.Age,
			&item.User.Gender,
			&item.User.About,
			&item.BlockedAt,
		); err != nil {
			return nil, err
		}
		item.BlockedAt = item.BlockedAt.UTC()
		result = append(result, item)
	}
	return result, rows.Err()
}

func ChatParticipantIDs(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID uuid.UUID,
) (uuid.UUID, uuid.UUID, error) {
	var low uuid.UUID
	var high uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT user_low, user_high
		FROM chats
		WHERE id = $1
	`, chatID).Scan(&low, &high)
	if err != nil {
		if err == pgx.ErrNoRows {
			return uuid.Nil, uuid.Nil, ErrChatNotFound
		}
		return uuid.Nil, uuid.Nil, err
	}
	return low, high, nil
}

func ensureChatMembership(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, userID uuid.UUID,
) error {
	low, high, err := ChatParticipantIDs(ctx, pool, chatID)
	if err != nil {
		return err
	}
	if userID != low && userID != high {
		return ErrChatForbidden
	}
	return nil
}

func userExists(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (bool, error) {
	var exists int
	err := pool.QueryRow(ctx, `SELECT 1 FROM users WHERE id = $1`, userID).Scan(&exists)
	if err != nil {
		if err == pgx.ErrNoRows {
			return false, nil
		}
		return false, err
	}
	return true, nil
}
