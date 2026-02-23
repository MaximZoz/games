package store

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrFriendNotFound              = errors.New("friend entity not found")
	ErrFriendForbidden             = errors.New("friend action forbidden")
	ErrAlreadyFriends              = errors.New("already friends")
	ErrFriendRequestAlreadySent    = errors.New("friend request already sent")
	ErrFriendRequestAlreadyPending = errors.New("friend request already pending")
	ErrCannotFriendYourself        = errors.New("cannot friend yourself")
)

type FriendUser struct {
	ID          uuid.UUID
	Email       string
	DisplayName *string
	AvatarKind  string
	AvatarValue *string
	Age         *int
	Gender      *string
	About       *string
}

type Friendship struct {
	User      FriendUser
	CreatedAt time.Time
}

type FriendRequest struct {
	ID         uuid.UUID
	SenderID   uuid.UUID
	ReceiverID uuid.UUID
	CreatedAt  time.Time
	User       FriendUser
}

type FriendSearchResult struct {
	User           FriendUser
	RelationStatus string
	RequestID      *uuid.UUID
}

func orderedUserPair(a, b uuid.UUID) (uuid.UUID, uuid.UUID) {
	if strings.Compare(a.String(), b.String()) < 0 {
		return a, b
	}
	return b, a
}

func ListFriendships(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]Friendship, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about,
			f.created_at
		FROM friendships f
		JOIN users u ON u.id = CASE
			WHEN f.user_low = $1 THEN f.user_high
			ELSE f.user_low
		END
		WHERE f.user_low = $1 OR f.user_high = $1
		ORDER BY COALESCE(u.display_name, u.email) ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]Friendship, 0)
	for rows.Next() {
		var item Friendship
		if err := rows.Scan(
			&item.User.ID,
			&item.User.Email,
			&item.User.DisplayName,
			&item.User.AvatarKind,
			&item.User.AvatarValue,
			&item.User.Age,
			&item.User.Gender,
			&item.User.About,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func ListIncomingFriendRequests(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]FriendRequest, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			fr.id, fr.sender_user_id, fr.receiver_user_id, fr.created_at,
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about
		FROM friend_requests fr
		JOIN users u ON u.id = fr.sender_user_id
		WHERE fr.receiver_user_id = $1
		ORDER BY fr.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]FriendRequest, 0)
	for rows.Next() {
		var item FriendRequest
		if err := rows.Scan(
			&item.ID,
			&item.SenderID,
			&item.ReceiverID,
			&item.CreatedAt,
			&item.User.ID,
			&item.User.Email,
			&item.User.DisplayName,
			&item.User.AvatarKind,
			&item.User.AvatarValue,
			&item.User.Age,
			&item.User.Gender,
			&item.User.About,
		); err != nil {
			return nil, err
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func ListOutgoingFriendRequests(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]FriendRequest, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			fr.id, fr.sender_user_id, fr.receiver_user_id, fr.created_at,
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about
		FROM friend_requests fr
		JOIN users u ON u.id = fr.receiver_user_id
		WHERE fr.sender_user_id = $1
		ORDER BY fr.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]FriendRequest, 0)
	for rows.Next() {
		var item FriendRequest
		if err := rows.Scan(
			&item.ID,
			&item.SenderID,
			&item.ReceiverID,
			&item.CreatedAt,
			&item.User.ID,
			&item.User.Email,
			&item.User.DisplayName,
			&item.User.AvatarKind,
			&item.User.AvatarValue,
			&item.User.Age,
			&item.User.Gender,
			&item.User.About,
		); err != nil {
			return nil, err
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func SearchUsersWithFriendRelation(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	query string,
	limit int,
) ([]FriendSearchResult, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return []FriendSearchResult{}, nil
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	pattern := "%" + query + "%"
	rows, err := pool.Query(ctx, `
		SELECT
			u.id, u.email, u.display_name, u.avatar_kind, u.avatar_value, u.age, u.gender, u.about,
			CASE
				WHEN f.user_low IS NOT NULL THEN 'friend'
				WHEN fr_out.id IS NOT NULL THEN 'outgoing'
				WHEN fr_in.id IS NOT NULL THEN 'incoming'
				ELSE 'none'
			END AS relation_status,
			COALESCE(fr_out.id::text, fr_in.id::text) AS request_id
		FROM users u
		LEFT JOIN friendships f ON (
			(f.user_low = $1 AND f.user_high = u.id)
			OR
			(f.user_high = $1 AND f.user_low = u.id)
		)
		LEFT JOIN friend_requests fr_out ON (
			fr_out.sender_user_id = $1 AND fr_out.receiver_user_id = u.id
		)
		LEFT JOIN friend_requests fr_in ON (
			fr_in.sender_user_id = u.id AND fr_in.receiver_user_id = $1
		)
		WHERE
			u.id <> $1
			AND COALESCE(u.display_name, '') ILIKE $2
		ORDER BY
			CASE WHEN u.display_name IS NULL OR u.display_name = '' THEN 1 ELSE 0 END ASC,
			COALESCE(u.display_name, u.email) ASC
		LIMIT $3
	`, userID, pattern, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]FriendSearchResult, 0)
	for rows.Next() {
		var item FriendSearchResult
		var requestIDRaw sql.NullString
		if err := rows.Scan(
			&item.User.ID,
			&item.User.Email,
			&item.User.DisplayName,
			&item.User.AvatarKind,
			&item.User.AvatarValue,
			&item.User.Age,
			&item.User.Gender,
			&item.User.About,
			&item.RelationStatus,
			&requestIDRaw,
		); err != nil {
			return nil, err
		}
		if requestIDRaw.Valid {
			if id, err := uuid.Parse(requestIDRaw.String); err == nil {
				item.RequestID = &id
			}
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func CreateFriendRequest(
	ctx context.Context,
	pool *pgxpool.Pool,
	senderUserID, receiverUserID uuid.UUID,
) (uuid.UUID, error) {
	if senderUserID == receiverUserID {
		return uuid.Nil, ErrCannotFriendYourself
	}

	receiver, err := GetUserByID(ctx, pool, receiverUserID)
	if err != nil || receiver == nil {
		return uuid.Nil, ErrFriendNotFound
	}

	blocked, err := IsUsersBlocked(ctx, pool, senderUserID, receiverUserID)
	if err != nil {
		return uuid.Nil, err
	}
	if blocked {
		return uuid.Nil, ErrUserBlocked
	}

	low, high := orderedUserPair(senderUserID, receiverUserID)
	var exists int
	err = pool.QueryRow(ctx,
		`SELECT 1 FROM friendships WHERE user_low = $1 AND user_high = $2`,
		low, high,
	).Scan(&exists)
	if err == nil {
		return uuid.Nil, ErrAlreadyFriends
	}
	if err != nil && err != pgx.ErrNoRows {
		return uuid.Nil, err
	}

	var request FriendRequest
	err = pool.QueryRow(ctx, `
		SELECT id, sender_user_id, receiver_user_id, created_at
		FROM friend_requests
		WHERE
			(sender_user_id = $1 AND receiver_user_id = $2)
			OR
			(sender_user_id = $2 AND receiver_user_id = $1)
		LIMIT 1
	`, senderUserID, receiverUserID).Scan(
		&request.ID, &request.SenderID, &request.ReceiverID, &request.CreatedAt,
	)
	if err == nil {
		if request.SenderID == senderUserID && request.ReceiverID == receiverUserID {
			return uuid.Nil, ErrFriendRequestAlreadySent
		}
		return uuid.Nil, ErrFriendRequestAlreadyPending
	}
	if err != nil && err != pgx.ErrNoRows {
		return uuid.Nil, err
	}

	var requestID uuid.UUID
	err = pool.QueryRow(ctx, `
		INSERT INTO friend_requests (sender_user_id, receiver_user_id)
		VALUES ($1, $2)
		RETURNING id
	`, senderUserID, receiverUserID).Scan(&requestID)
	if err != nil {
		return uuid.Nil, err
	}
	return requestID, nil
}

func AcceptFriendRequest(ctx context.Context, pool *pgxpool.Pool, requestID, currentUserID uuid.UUID) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var senderID uuid.UUID
	var receiverID uuid.UUID
	err = tx.QueryRow(ctx, `
		SELECT sender_user_id, receiver_user_id
		FROM friend_requests
		WHERE id = $1
		FOR UPDATE
	`, requestID).Scan(&senderID, &receiverID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrFriendNotFound
		}
		return err
	}
	if receiverID != currentUserID {
		return ErrFriendForbidden
	}

	_, err = tx.Exec(ctx, `DELETE FROM friend_requests WHERE id = $1`, requestID)
	if err != nil {
		return err
	}

	low, high := orderedUserPair(senderID, receiverID)
	_, err = tx.Exec(ctx, `
		INSERT INTO friendships (user_low, user_high)
		VALUES ($1, $2)
		ON CONFLICT (user_low, user_high) DO NOTHING
	`, low, high)
	if err != nil {
		return err
	}

	// Защитная очистка: если была встречная заявка, удаляем и её.
	_, _ = tx.Exec(ctx, `
		DELETE FROM friend_requests
		WHERE sender_user_id = $1 AND receiver_user_id = $2
	`, receiverID, senderID)

	return tx.Commit(ctx)
}

func RejectFriendRequest(ctx context.Context, pool *pgxpool.Pool, requestID, currentUserID uuid.UUID) error {
	var receiverID uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT receiver_user_id
		FROM friend_requests
		WHERE id = $1
	`, requestID).Scan(&receiverID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrFriendNotFound
		}
		return err
	}
	if receiverID != currentUserID {
		return ErrFriendForbidden
	}

	_, err = pool.Exec(ctx, `DELETE FROM friend_requests WHERE id = $1`, requestID)
	return err
}

func CancelOutgoingFriendRequest(ctx context.Context, pool *pgxpool.Pool, requestID, currentUserID uuid.UUID) error {
	var senderID uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT sender_user_id
		FROM friend_requests
		WHERE id = $1
	`, requestID).Scan(&senderID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrFriendNotFound
		}
		return err
	}
	if senderID != currentUserID {
		return ErrFriendForbidden
	}

	_, err = pool.Exec(ctx, `DELETE FROM friend_requests WHERE id = $1`, requestID)
	return err
}

func RemoveFriendship(ctx context.Context, pool *pgxpool.Pool, userID, friendUserID uuid.UUID) error {
	if userID == friendUserID {
		return ErrCannotFriendYourself
	}

	low, high := orderedUserPair(userID, friendUserID)
	tag, err := pool.Exec(ctx, `
		DELETE FROM friendships
		WHERE user_low = $1 AND user_high = $2
	`, low, high)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrFriendNotFound
	}
	return nil
}
