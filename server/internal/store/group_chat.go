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

	for _, uid := range memberIDs {
		if uid == uuid.Nil {
			continue
		}
		_, err = pool.Exec(ctx, `
			INSERT INTO chat_members (chat_id, user_id)
			VALUES ($1, $2)
			ON CONFLICT DO NOTHING
		`, chatID, uid)
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
	ids, err := ListChatMemberIDs(ctx, pool, chatID)
	if err != nil {
		return nil, err
	}
	for _, id := range ids {
		u, err := GetUserByID(ctx, pool, id)
		if err != nil || u == nil {
			continue
		}
		lang := ""
		if s, serr := GetUserSettings(ctx, pool, id); serr == nil {
			lang = s.PreferredLanguage
		}
		m.Members = append(m.Members, ChatUser{
			ID:                u.ID,
			Email:             u.Email,
			DisplayName:       u.DisplayName,
			AvatarKind:        u.AvatarKind,
			AvatarValue:       u.AvatarValue,
			Age:               u.Age,
			Gender:            u.Gender,
			About:             u.About,
			IsSupport:         u.IsSupport,
			PreferredLanguage: lang,
		})
	}
	return &m, nil
}
