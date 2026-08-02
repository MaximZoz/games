package store

import (
	"context"
	"database/sql"
	"errors"
	"net/url"
	"regexp"
	"strings"
	"time"

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
	ErrCannotBlockSupport     = errors.New("cannot block support")
	ErrUserNotFound           = errors.New("user not found")
)

// Токены, разрешённые не-друзьям при messages_friends_only у получателя.
var (
	animatedEmojiTokenRe  = regexp.MustCompile(`^\[ae:[A-Za-z0-9_]+\]$`)
	giftCollectionTokenRe = regexp.MustCompile(
		`^\[gift_coll:[^|\]]+\|[^|\]]*\|[^|\]]*\|[^\]]*\]$`,
	)
)

// IsRestrictedChatMessageAllowed — смайлик, подарок или карточка начисления (не свободный текст).
func IsRestrictedChatMessageAllowed(body string) bool {
	text := strings.TrimSpace(body)
	return animatedEmojiTokenRe.MatchString(text) ||
		giftCollectionTokenRe.MatchString(text) ||
		IsCoinsCreditMessage(text)
}

// InviteLobbyIDFromBody — id лобби, если тело целиком ссылка на «Свою игру».
func InviteLobbyIDFromBody(body string) (string, bool) {
	text := strings.TrimSpace(body)
	if text == "" {
		return "", false
	}
	var u *url.URL
	var err error
	if strings.HasPrefix(text, "http://") || strings.HasPrefix(text, "https://") {
		u, err = url.Parse(text)
	} else if strings.HasPrefix(text, "/games/") {
		u, err = url.Parse("https://local.app" + text)
	} else {
		return "", false
	}
	if err != nil || u == nil {
		return "", false
	}
	parts := make([]string, 0, 4)
	for _, p := range strings.Split(strings.Trim(u.Path, "/"), "/") {
		if p != "" {
			parts = append(parts, p)
		}
	}
	if len(parts) < 4 {
		return "", false
	}
	if parts[0] != "games" || parts[1] != "tictactoe" || parts[2] != "lobby" {
		return "", false
	}
	id := strings.TrimSpace(parts[3])
	if id == "" || strings.Contains(id, "/") || strings.Contains(id, " ") {
		return "", false
	}
	return id, true
}

// IsInviteLobbyShareBody — тело сообщения целиком является ссылкой на «Свою игру».
func IsInviteLobbyShareBody(body string) bool {
	_, ok := InviteLobbyIDFromBody(body)
	return ok
}

// DeletedInviteChatMessage — удалённое invite-сообщение и участники чата.
type DeletedInviteChatMessage struct {
	MessageID  uuid.UUID
	ChatID     uuid.UUID
	LowUserID  uuid.UUID
	HighUserID uuid.UUID
}

// DeleteInviteLobbyShareMessages удаляет все сообщения-ссылки на данное лобби
// (у всех, кому отправили «Войти в игру»), когда лобби закрыто или игра началась.
func DeleteInviteLobbyShareMessages(
	ctx context.Context,
	pool *pgxpool.Pool,
	lobbyID string,
) ([]DeletedInviteChatMessage, error) {
	lobbyID = strings.TrimSpace(lobbyID)
	if lobbyID == "" || pool == nil {
		return nil, nil
	}
	// LIKE по фрагменту пути — уже сужает выборку до кандидатов; точная
	// проверка InviteLobbyIDFromBody отсекает ложные совпадения.
	likePat := "%/games/tictactoe/lobby/" + lobbyID + "%"
	rows, err := pool.Query(ctx, `
		SELECT id, chat_id, body
		FROM chat_messages
		WHERE body LIKE $1
	`, likePat)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	type candidate struct {
		id     uuid.UUID
		chatID uuid.UUID
	}
	var toDelete []candidate
	chatSeen := make(map[uuid.UUID]struct{})
	var chatIDs []uuid.UUID
	for rows.Next() {
		var id, chatID uuid.UUID
		var body string
		if err := rows.Scan(&id, &chatID, &body); err != nil {
			return nil, err
		}
		gotID, ok := InviteLobbyIDFromBody(body)
		if !ok || gotID != lobbyID {
			continue
		}
		toDelete = append(toDelete, candidate{id: id, chatID: chatID})
		if _, ok := chatSeen[chatID]; !ok {
			chatSeen[chatID] = struct{}{}
			chatIDs = append(chatIDs, chatID)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(toDelete) == 0 {
		return nil, nil
	}

	participants := make(map[uuid.UUID][2]uuid.UUID, len(chatIDs))
	for _, chatID := range chatIDs {
		lowID, highID, err := ChatParticipantIDs(ctx, pool, chatID)
		if err != nil {
			continue
		}
		participants[chatID] = [2]uuid.UUID{lowID, highID}
	}

	ids := make([]uuid.UUID, len(toDelete))
	for i, c := range toDelete {
		ids[i] = c.id
	}
	ct, err := pool.Exec(ctx, `DELETE FROM chat_messages WHERE id = ANY($1)`, ids)
	if err != nil {
		return nil, err
	}
	if ct.RowsAffected() == 0 {
		return nil, nil
	}

	out := make([]DeletedInviteChatMessage, 0, len(toDelete))
	for _, c := range toDelete {
		pair, ok := participants[c.chatID]
		if !ok {
			continue
		}
		out = append(out, DeletedInviteChatMessage{
			MessageID:  c.id,
			ChatID:     c.chatID,
			LowUserID:  pair[0],
			HighUserID: pair[1],
		})
	}
	return out, nil
}

type ChatMessage struct {
	ID           uuid.UUID
	ChatID       uuid.UUID
	SenderUserID uuid.UUID
	Body         string
	CreatedAt    time.Time
	DeliveredAt  *time.Time
	ReadAt       *time.Time
	EditedAt     *time.Time
	ReplyToMessageID *uuid.UUID
	HasImage     bool
	ImageCount   int
	// Превью ответа (из JOIN), без image_data.
	ReplyToBody     string
	ReplyToHasImage bool
	ReplyToSenderID *uuid.UUID
}

type ChatUser struct {
	ID                uuid.UUID
	Email             string
	DisplayName       *string
	AvatarKind        string
	AvatarValue       *string
	Age               *int
	Gender            *string
	About             *string
	IsSupport         bool
	PreferredLanguage string
}

type ChatPreview struct {
	ChatID      uuid.UUID
	Peer        ChatUser
	CreatedAt   time.Time
	LastMessage *ChatMessage
	UnreadCount int
	UpdatedAt   time.Time
	// Group chat fields (kind=group).
	Kind     string
	Title    string
	LobbyID  string
	GameType string
	Members  []ChatUser
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
		INSERT INTO chats (user_low, user_high, kind)
		VALUES ($1, $2, 'direct')
		ON CONFLICT (user_low, user_high) WHERE kind = 'direct' AND user_low IS NOT NULL AND user_high IS NOT NULL
		DO NOTHING
	`, low, high)
	if err != nil {
		return uuid.Nil, err
	}

	var chatID uuid.UUID
	err = pool.QueryRow(ctx, `
		SELECT id
		FROM chats
		WHERE user_low = $1 AND user_high = $2 AND kind = 'direct'
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
				COALESCE(c.kind, 'direct') AS kind,
				COALESCE(c.title, '') AS title,
				COALESCE(c.lobby_id, '') AS lobby_id,
				COALESCE(c.game_type, '') AS game_type,
				CASE
					WHEN COALESCE(c.kind, 'direct') = 'direct' AND c.user_low = $1 THEN c.user_high
					WHEN COALESCE(c.kind, 'direct') = 'direct' THEN c.user_low
					ELSE NULL
				END AS peer_id
			FROM chats c
			WHERE (COALESCE(c.kind, 'direct') = 'direct' AND (c.user_low = $1 OR c.user_high = $1))
			   OR (c.kind = 'group' AND EXISTS (
			        SELECT 1 FROM chat_members cm WHERE cm.chat_id = c.id AND cm.user_id = $1
			   ))
		),
		last_msg AS (
			SELECT DISTINCT ON (m.chat_id)
				m.chat_id,
				m.id,
				m.sender_user_id,
				m.body,
				m.created_at,
				m.delivered_at,
				m.read_at,
				m.has_image,
				COALESCE(m.image_count, 0) AS image_count
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
			mc.kind,
			mc.title,
			mc.lobby_id,
			mc.game_type,
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about,
			COALESCE(u.is_support, false),
			COALESCE(us.preferred_language, ''),
			lm.id::text, lm.sender_user_id::text, lm.body, lm.created_at, lm.delivered_at, lm.read_at, lm.has_image, lm.image_count,
			COALESCE(un.unread_count, 0),
			COALESCE(lm.created_at, mc.created_at) AS updated_at
		FROM my_chats mc
		LEFT JOIN users u ON u.id = mc.peer_id
		LEFT JOIN user_settings us ON us.user_id = u.id
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
		var peerID uuid.NullUUID
		var peerEmail sql.NullString
		var peerDisplayName sql.NullString
		var peerAvatarKind sql.NullString
		var peerAvatarValue sql.NullString
		var peerAge sql.NullInt32
		var peerGender sql.NullString
		var peerAbout sql.NullString
		var peerIsSupport sql.NullBool
		var peerLang sql.NullString
		var lastMessageIDRaw sql.NullString
		var lastSenderIDRaw sql.NullString
		var lastBody sql.NullString
		var lastCreatedAt sql.NullTime
		var lastDeliveredAt sql.NullTime
		var lastReadAt sql.NullTime
		var lastHasImage sql.NullBool
		var lastImageCount sql.NullInt32

		if err := rows.Scan(
			&item.ChatID,
			&item.CreatedAt,
			&item.Kind,
			&item.Title,
			&item.LobbyID,
			&item.GameType,
			&peerID,
			&peerEmail,
			&peerDisplayName,
			&peerAvatarKind,
			&peerAvatarValue,
			&peerAge,
			&peerGender,
			&peerAbout,
			&peerIsSupport,
			&peerLang,
			&lastMessageIDRaw,
			&lastSenderIDRaw,
			&lastBody,
			&lastCreatedAt,
			&lastDeliveredAt,
			&lastReadAt,
			&lastHasImage,
			&lastImageCount,
			&item.UnreadCount,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}

		if item.Kind == "" {
			item.Kind = ChatKindDirect
		}
		item.CreatedAt = item.CreatedAt.UTC()
		item.UpdatedAt = item.UpdatedAt.UTC()
		if peerID.Valid {
			item.Peer.ID = peerID.UUID
			item.Peer.Email = peerEmail.String
			if peerDisplayName.Valid {
				dn := peerDisplayName.String
				item.Peer.DisplayName = &dn
			}
			item.Peer.AvatarKind = peerAvatarKind.String
			if peerAvatarValue.Valid {
				av := peerAvatarValue.String
				item.Peer.AvatarValue = &av
			}
			if peerAge.Valid {
				age := int(peerAge.Int32)
				item.Peer.Age = &age
			}
			if peerGender.Valid {
				g := peerGender.String
				item.Peer.Gender = &g
			}
			if peerAbout.Valid {
				a := peerAbout.String
				item.Peer.About = &a
			}
			item.Peer.IsSupport = peerIsSupport.Valid && peerIsSupport.Bool
			item.Peer.PreferredLanguage = peerLang.String
		}
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
					HasImage:     lastHasImage.Valid && lastHasImage.Bool,
					ImageCount:   int(lastImageCount.Int32),
				}
				if msg.HasImage && msg.ImageCount <= 0 {
					msg.ImageCount = 1
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
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Участников групповых чатов грузим одним запросом (раньше — N+1 GetGroupChatMeta).
	groupIDs := make([]uuid.UUID, 0)
	for _, item := range result {
		if item.Kind == ChatKindGroup {
			groupIDs = append(groupIDs, item.ChatID)
		}
	}
	if len(groupIDs) > 0 {
		membersByChat, merr := ListGroupChatMembersByChatIDs(ctx, pool, groupIDs)
		if merr == nil {
			for i := range result {
				if result[i].Kind != ChatKindGroup {
					continue
				}
				result[i].Members = membersByChat[result[i].ChatID]
			}
		}
	}

	return result, nil
}

func ListChatMessages(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, currentUserID uuid.UUID,
	limit int,
	before *time.Time,
) ([]ChatMessage, error) {
	return ListChatMessagesRich(ctx, pool, chatID, currentUserID, limit, before)
}

func SendChatMessage(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, senderUserID uuid.UUID,
	body string,
) (ChatMessage, error) {
	return SendChatMessageOpts(ctx, pool, chatID, senderUserID, SendChatOptions{Body: body})
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
		  AND (
		    (COALESCE(c.kind, 'direct') = 'direct' AND (c.user_low = $1 OR c.user_high = $1))
		    OR (c.kind = 'group' AND EXISTS (
		          SELECT 1 FROM chat_members cm WHERE cm.chat_id = c.id AND cm.user_id = $1
		    ))
		  )
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
	kind, err := ChatKind(ctx, pool, chatID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return uuid.Nil, uuid.Nil, ErrChatNotFound
		}
		return uuid.Nil, uuid.Nil, err
	}
	ids, err := ListChatMemberIDs(ctx, pool, chatID)
	if err != nil {
		return uuid.Nil, uuid.Nil, err
	}
	member := false
	for _, id := range ids {
		if id == currentUserID {
			member = true
			break
		}
	}
	if !member {
		return uuid.Nil, uuid.Nil, ErrChatForbidden
	}

	if kind == ChatKindGroup {
		// Групповой чат лобби живёт с лобби — очистка/выход из UI запрещены.
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
	if len(ids) == 0 {
		return uuid.Nil, uuid.Nil, nil
	}
	if len(ids) == 1 {
		return ids[0], ids[0], nil
	}
	return ids[0], ids[1], nil
}

func BlockUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	blockerUserID, blockedUserID uuid.UUID,
) (bool, error) {
	if blockerUserID == blockedUserID {
		return false, ErrCannotBlockYourself
	}

	target, err := GetUserByID(ctx, pool, blockedUserID)
	if err != nil || target == nil {
		return false, ErrUserNotFound
	}
	if target.IsSupport {
		return false, ErrCannotBlockSupport
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)

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
			COALESCE(u.is_support, false),
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
			&item.User.IsSupport,
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
	ids, err := ListChatMemberIDs(ctx, pool, chatID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return uuid.Nil, uuid.Nil, ErrChatNotFound
		}
		return uuid.Nil, uuid.Nil, err
	}
	if len(ids) == 0 {
		return uuid.Nil, uuid.Nil, ErrChatNotFound
	}
	if len(ids) == 1 {
		return ids[0], ids[0], nil
	}
	return ids[0], ids[1], nil
}

// ChatBroadcastUserIDs — все участники чата для realtime/push.
func ChatBroadcastUserIDs(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID uuid.UUID,
) ([]uuid.UUID, error) {
	return ListChatMemberIDs(ctx, pool, chatID)
}

func ensureChatMembership(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatID, userID uuid.UUID,
) error {
	ok, err := IsChatMember(ctx, pool, chatID, userID)
	if err != nil {
		return err
	}
	if !ok {
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
