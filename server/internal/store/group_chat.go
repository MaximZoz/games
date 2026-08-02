package store

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const ChatKindDirect = "direct"
const ChatKindGroup = "group"

// EnsureGameGroupChat создаёт или возвращает групповой чат лобби и синхронизирует участников.
func EnsureGameGroupChat(
	ctx context.Context,
	pool *pgxpool.Pool,
	lobbyID string,
	memberIDs []uuid.UUID,
	title string,
	gameType string,
) (uuid.UUID, error) {
	lobbyID = strings.TrimSpace(lobbyID)
	if lobbyID == "" {
		return uuid.Nil, errors.New("lobby_id required")
	}
	if title == "" {
		title = "Игра"
	}
	if gameType == "" {
		gameType = "tictactoe"
	}

	var chatID uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT id FROM chats WHERE lobby_id = $1 AND kind = 'group'
	`, lobbyID).Scan(&chatID)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}
	if errors.Is(err, pgx.ErrNoRows) {
		err = pool.QueryRow(ctx, `
			INSERT INTO chats (kind, lobby_id, title, game_type)
			VALUES ('group', $1, $2, $3)
			RETURNING id
		`, lobbyID, title, gameType).Scan(&chatID)
		if err != nil {
			return uuid.Nil, err
		}
	} else {
		_, _ = pool.Exec(ctx, `
			UPDATE chats SET title = $2, game_type = $3 WHERE id = $1
		`, chatID, title, gameType)
	}

	uniq := make([]uuid.UUID, 0, len(memberIDs))
	seen := make(map[uuid.UUID]struct{}, len(memberIDs))
	for _, uid := range memberIDs {
		if uid == uuid.Nil {
			continue
		}
		if _, ok := seen[uid]; ok {
			continue
		}
		seen[uid] = struct{}{}
		uniq = append(uniq, uid)
	}
	if len(uniq) > 0 {
		_, err = pool.Exec(ctx, `
			INSERT INTO chat_members (chat_id, user_id)
			SELECT $1, UNNEST($2::uuid[])
			ON CONFLICT DO NOTHING
		`, chatID, uniq)
		if err != nil {
			return uuid.Nil, err
		}
	}
	return chatID, nil
}

// DeleteGameGroupChatByLobby удаляет групповой чат лобби (сообщения — CASCADE).
func DeleteGameGroupChatByLobby(ctx context.Context, pool *pgxpool.Pool, lobbyID string) error {
	lobbyID = strings.TrimSpace(lobbyID)
	if lobbyID == "" {
		return nil
	}
	_, err := pool.Exec(ctx, `
		DELETE FROM chats WHERE lobby_id = $1 AND kind = 'group'
	`, lobbyID)
	return err
}

// ListUserGroupLobbyIDs — lobby_id групповых чатов, в которых состоит пользователь.
func ListUserGroupLobbyIDs(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]string, error) {
	rows, err := pool.Query(ctx, `
		SELECT DISTINCT c.lobby_id
		FROM chats c
		JOIN chat_members m ON m.chat_id = c.id
		WHERE c.kind = 'group'
		  AND c.lobby_id IS NOT NULL
		  AND TRIM(c.lobby_id) <> ''
		  AND m.user_id = $1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var lobbyID string
		if err := rows.Scan(&lobbyID); err != nil {
			return nil, err
		}
		lobbyID = strings.TrimSpace(lobbyID)
		if lobbyID != "" {
			out = append(out, lobbyID)
		}
	}
	return out, rows.Err()
}

// RemoveChatMember убирает участника из группового чата.
func RemoveChatMember(ctx context.Context, pool *pgxpool.Pool, chatID, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		DELETE FROM chat_members WHERE chat_id = $1 AND user_id = $2
	`, chatID, userID)
	return err
}

// ChatKind возвращает kind чата (direct|group).
func ChatKind(ctx context.Context, pool *pgxpool.Pool, chatID uuid.UUID) (string, error) {
	var kind string
	err := pool.QueryRow(ctx, `
		SELECT COALESCE(kind, 'direct') FROM chats WHERE id = $1
	`, chatID).Scan(&kind)
	if err != nil {
		return "", err
	}
	return kind, nil
}

// IsChatMember — участник direct или group чата.
func IsChatMember(ctx context.Context, pool *pgxpool.Pool, chatID, userID uuid.UUID) (bool, error) {
	var ok bool
	err := pool.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM chats c
			WHERE c.id = $1 AND c.kind = 'direct'
			  AND (c.user_low = $2 OR c.user_high = $2)
		) OR EXISTS(
			SELECT 1 FROM chat_members m
			WHERE m.chat_id = $1 AND m.user_id = $2
		)
	`, chatID, userID).Scan(&ok)
	return ok, err
}

// ListChatMemberIDs возвращает участников чата.
func ListChatMemberIDs(ctx context.Context, pool *pgxpool.Pool, chatID uuid.UUID) ([]uuid.UUID, error) {
	var kind string
	var low, high *uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT kind, user_low, user_high FROM chats WHERE id = $1
	`, chatID).Scan(&kind, &low, &high)
	if err != nil {
		return nil, err
	}
	if kind != ChatKindGroup {
		out := make([]uuid.UUID, 0, 2)
		if low != nil {
			out = append(out, *low)
		}
		if high != nil {
			out = append(out, *high)
		}
		return out, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT user_id FROM chat_members WHERE chat_id = $1 ORDER BY joined_at
	`, chatID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

// GroupChatMeta — метаданные группового чата для списка/шапки.
type GroupChatMeta struct {
	ChatID    uuid.UUID
	LobbyID   string
	Title     string
	GameType  string
	CreatedAt time.Time
	Members   []ChatUser
}

func GetGroupChatMeta(ctx context.Context, pool *pgxpool.Pool, chatID uuid.UUID) (*GroupChatMeta, error) {
	var m GroupChatMeta
	err := pool.QueryRow(ctx, `
		SELECT id, COALESCE(lobby_id, ''), COALESCE(title, ''), COALESCE(game_type, ''), created_at
		FROM chats WHERE id = $1 AND kind = 'group'
	`, chatID).Scan(&m.ChatID, &m.LobbyID, &m.Title, &m.GameType, &m.CreatedAt)
	if err != nil {
		return nil, err
	}
	byChat, err := ListGroupChatMembersByChatIDs(ctx, pool, []uuid.UUID{chatID})
	if err != nil {
		return nil, err
	}
	m.Members = byChat[chatID]
	return &m, nil
}

// ListGroupChatMembersByChatIDs — участники нескольких групповых чатов одним запросом.
func ListGroupChatMembersByChatIDs(
	ctx context.Context,
	pool *pgxpool.Pool,
	chatIDs []uuid.UUID,
) (map[uuid.UUID][]ChatUser, error) {
	out := make(map[uuid.UUID][]ChatUser, len(chatIDs))
	if len(chatIDs) == 0 {
		return out, nil
	}
	rows, err := pool.Query(ctx, `
		SELECT
			cm.chat_id,
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value,
			u.age, u.gender, u.about, COALESCE(u.is_support, false),
			COALESCE(us.preferred_language, '')
		FROM chat_members cm
		JOIN users u ON u.id = cm.user_id
		LEFT JOIN user_settings us ON us.user_id = u.id
		WHERE cm.chat_id = ANY($1)
		ORDER BY cm.chat_id, cm.joined_at
	`, chatIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var chatID uuid.UUID
		var cu ChatUser
		if err := rows.Scan(
			&chatID,
			&cu.ID, &cu.Email, &cu.DisplayName, &cu.AvatarKind, &cu.AvatarValue,
			&cu.Age, &cu.Gender, &cu.About, &cu.IsSupport, &cu.PreferredLanguage,
		); err != nil {
			return nil, err
		}
		out[chatID] = append(out[chatID], cu)
	}
	return out, rows.Err()
}
