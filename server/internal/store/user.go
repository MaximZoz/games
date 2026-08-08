package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID                uuid.UUID
	Email             string
	PasswordHash      string
	DisplayName       *string
	IsAdmin           bool
	Age               *int
	Gender            *string
	About             *string
	AvatarKind        string
	AvatarValue       *string
	BalanceBronze     int
	ShowStatsToOthers bool
	EmailVerifiedAt   *time.Time
	FrozenAt          *time.Time
	IsSupport         bool
	LastSeenAt        *time.Time
	CreatedAt         string
	UpdatedAt         string
}

const selectUserCols = `id, email, COALESCE(password_hash, ''), display_name, is_admin,
	age, gender, about, avatar_kind, avatar_value,
	balance_bronze,
	COALESCE(show_stats_to_others, true),
	email_verified_at,
	frozen_at,
	COALESCE(is_support, false),
	last_seen_at,
	created_at::text, updated_at::text`

func scanUser(row pgx.Row) (*User, error) {
	var u User
	err := row.Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin,
		&u.Age, &u.Gender, &u.About, &u.AvatarKind, &u.AvatarValue,
		&u.BalanceBronze,
		&u.ShowStatsToOthers,
		&u.EmailVerifiedAt,
		&u.FrozenAt,
		&u.IsSupport,
		&u.LastSeenAt,
		&u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (u *User) EmailVerified() bool {
	return u != nil && u.EmailVerifiedAt != nil
}

func (u *User) IsFrozen() bool {
	return u != nil && u.FrozenAt != nil
}

// ListUsersParams — параметры поиска/сортировки/пагинации пользователей админом.
type ListUsersParams struct {
	Query        string // ILIKE по email/display_name
	Sort         string // created_at | last_seen | email
	Order        string // asc | desc
	AdminFilter  string // all | admin | user
	FrozenFilter string // all | frozen | active
	Limit        int
	Offset       int
}

// ListUsersResult — страница списка пользователей + общее число.
type ListUsersResult struct {
	Users []*User
	Total int
}

// ListUsersPaged — поиск/сортировка/пагинация пользователей для админки.
func ListUsersPaged(ctx context.Context, pool *pgxpool.Pool, p ListUsersParams) (ListUsersResult, error) {
	if p.Limit <= 0 || p.Limit > 200 {
		p.Limit = 20
	}
	if p.Offset < 0 {
		p.Offset = 0
	}

	var (
		where []string
		args  []any
		n     = 1
	)
	if q := strings.TrimSpace(p.Query); q != "" {
		like := "%" + q + "%"
		where = append(where, "(email ILIKE $1 OR COALESCE(display_name, '') ILIKE $1)")
		args = append(args, like)
		n = 2
	}
	switch p.AdminFilter {
	case "admin":
		where = append(where, "is_admin = true")
	case "user":
		where = append(where, "is_admin = false")
	}
	switch p.FrozenFilter {
	case "frozen":
		where = append(where, "frozen_at IS NOT NULL")
	case "active":
		where = append(where, "frozen_at IS NULL")
	}
	// Системный support-аккаунт не показываем в общем списке.
	where = append(where, "COALESCE(is_support, false) = false")

	whereClause := ""
	if len(where) > 0 {
		whereClause = " WHERE " + strings.Join(where, " AND ")
	}

	// Сортировка по whitelist-колонке.
	orderCol := "created_at"
	switch p.Sort {
	case "last_seen":
		orderCol = "last_seen_at"
	case "email":
		orderCol = "email"
	}
	dir := "DESC"
	if strings.EqualFold(p.Order, "asc") {
		dir = "ASC"
	}

	// Общее число (с теми же фильтрами).
	var total int
	countSQL := "SELECT COUNT(*) FROM users" + whereClause
	if err := pool.QueryRow(ctx, countSQL, args...).Scan(&total); err != nil {
		return ListUsersResult{}, err
	}

	listSQL := "SELECT " + selectUserCols + " FROM users" + whereClause +
		" ORDER BY " + orderCol + " " + dir + " NULLS LAST, created_at DESC LIMIT $" + itoa(n) +
		" OFFSET $" + itoa(n+1)
	args = append(args, p.Limit, p.Offset)

	rows, err := pool.Query(ctx, listSQL, args...)
	if err != nil {
		return ListUsersResult{}, err
	}
	defer rows.Close()

	var users []*User
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return ListUsersResult{}, err
		}
		users = append(users, u)
	}
	return ListUsersResult{Users: users, Total: total}, rows.Err()
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	var b [20]byte
	pos := len(b)
	for i > 0 {
		pos--
		b[pos] = byte('0' + i%10)
		i /= 10
	}
	return string(b[pos:])
}

// SetUserFrozen замораживает/размораживает пользователя.
func SetUserFrozen(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID, frozen bool) error {
	var val *time.Time
	if frozen {
		now := time.Now().UTC()
		val = &now
	}
	_, err := pool.Exec(ctx,
		`UPDATE users SET frozen_at = $2, updated_at = now() WHERE id = $1`, id, val)
	return err
}

// IsUserFrozen возвращает true, если пользователь заморожен.
func IsUserFrozen(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (bool, error) {
	var frozenAt *time.Time
	err := pool.QueryRow(ctx, `SELECT frozen_at FROM users WHERE id = $1`, id).Scan(&frozenAt)
	if err == pgx.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return frozenAt != nil, nil
}

// GetSupportUser возвращает системный аккаунт поддержки.
func GetSupportUser(ctx context.Context, pool *pgxpool.Pool) (*User, error) {
	row := pool.QueryRow(ctx, "SELECT "+selectUserCols+" FROM users WHERE is_support = true LIMIT 1")
	return scanUser(row)
}

// EnsureSupportUser создаёт системный аккаунт поддержки, если его нет
// (например, был удалён). Идемпотентно — вызывается при старте сервера.
func EnsureSupportUser(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := GetSupportUser(ctx, pool)
	if err == nil {
		return nil // уже есть
	}
	_, err = pool.Exec(ctx, `
		INSERT INTO users (email, password_hash, display_name, is_admin, is_support, avatar_kind)
		VALUES ('support@zozu', '', 'Поддержка', true, true, 'letter')
		ON CONFLICT (email) DO UPDATE SET is_support = true, is_admin = true
	`)
	return err
}

func CreateUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	email, passwordHash, displayName string,
	referredBy *uuid.UUID,
) (*User, error) {
	displayNamePtr := (*string)(nil)
	if displayName != "" {
		displayNamePtr = &displayName
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var referrerID *uuid.UUID
	if referredBy != nil && *referredBy != uuid.Nil {
		var exists uuid.UUID
		err = tx.QueryRow(ctx, `SELECT id FROM users WHERE id = $1`, *referredBy).Scan(&exists)
		if err == nil {
			referrerID = referredBy
		}
		// Невалидный ref игнорируем — регистрация всё равно проходит.
	}

	// CreateUser вызывается только после подтверждения email (или admin init) —
	// сразу помечаем email_verified_at.
	row := tx.QueryRow(ctx,
		`INSERT INTO users (email, password_hash, display_name, balance_bronze, referred_by, email_verified_at, show_stats_to_others)
		 VALUES ($1, $2, $3, $4, $5, now(), true)
		 RETURNING `+selectUserCols,
		email, passwordHash, displayNamePtr, RegistrationBonusBronze, referrerID,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, err
	}

	if referrerID != nil {
		_, err = tx.Exec(ctx, `
			UPDATE users
			SET balance_bronze = balance_bronze + $2, updated_at = now()
			WHERE id = $1
		`, *referrerID, ReferralBonusBronze)
		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return u, nil
}

func GetUserByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE email = $1`, email)
	return scanUser(row)
}

func GetUserByDisplayName(ctx context.Context, pool *pgxpool.Pool, displayName string) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE display_name = $1`, displayName)
	return scanUser(row)
}

func GetUserByEmailOrDisplayName(ctx context.Context, pool *pgxpool.Pool, login string) (*User, error) {
	login = strings.TrimSpace(login)
	if login == "" {
		return nil, pgx.ErrNoRows
	}
	u, err := GetUserByEmail(ctx, pool, strings.ToLower(login))
	if err == nil {
		return u, nil
	}
	if err != pgx.ErrNoRows {
		return nil, err
	}
	return GetUserByDisplayName(ctx, pool, login)
}

func GetUserByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE id = $1`, id)
	return scanUser(row)
}

// GetUsersByIDs — пакетная загрузка профилей (без N+1 в лобби/игре).
func GetUsersByIDs(ctx context.Context, pool *pgxpool.Pool, ids []uuid.UUID) (map[uuid.UUID]*User, error) {
	out := make(map[uuid.UUID]*User, len(ids))
	if len(ids) == 0 {
		return out, nil
	}
	uniq := make([]uuid.UUID, 0, len(ids))
	seen := make(map[uuid.UUID]struct{}, len(ids))
	for _, id := range ids {
		if id == uuid.Nil {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		uniq = append(uniq, id)
	}
	if len(uniq) == 0 {
		return out, nil
	}
	rows, err := pool.Query(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE id = ANY($1)`, uniq)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		out[u.ID] = u
	}
	return out, rows.Err()
}

func ListUsers(ctx context.Context, pool *pgxpool.Pool) ([]User, error) {
	rows, err := pool.Query(ctx,
		`SELECT `+selectUserCols+` FROM users ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []User
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, *u)
	}
	return list, rows.Err()
}

func SetUserAdmin(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID, isAdmin bool) error {
	_, err := pool.Exec(ctx, `UPDATE users SET is_admin = $1, updated_at = now() WHERE id = $2`, isAdmin, id)
	return err
}

func SetUserPassword(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID, passwordHash string) error {
	_, err := pool.Exec(ctx, `UPDATE users SET password_hash = $1, updated_at = now() WHERE id = $2`, passwordHash, id)
	return err
}

func DeleteUser(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM users WHERE id = $1`, id)
	return err
}

func CountAdmins(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE is_admin = true`).Scan(&n)
	return n, err
}

// ListAdminIDs возвращает ID всех админов (для WS-бродкаста).
func ListAdminIDs(ctx context.Context, pool *pgxpool.Pool) ([]uuid.UUID, error) {
	rows, err := pool.Query(ctx, `SELECT id FROM users WHERE is_admin = true`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func CountUsers(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `SELECT COUNT(*)::int FROM users`).Scan(&n)
	return n, err
}

type UpdateProfileParams struct {
	ID                uuid.UUID
	DisplayName       *string
	Age               *int
	Gender            *string
	About             *string
	AvatarKind        *string
	AvatarValue       *string
	ShowStatsToOthers *bool
}

func UpdateUserProfile(ctx context.Context, pool *pgxpool.Pool, p UpdateProfileParams) (*User, error) {
	row := pool.QueryRow(ctx,
		`UPDATE users SET
			display_name  = COALESCE($2, display_name),
			age           = $3,
			gender        = $4,
			about         = $5,
			avatar_kind   = COALESCE($6, avatar_kind),
			avatar_value  = $7,
			show_stats_to_others = COALESCE($8, show_stats_to_others),
			updated_at    = now()
		 WHERE id = $1
		 RETURNING `+selectUserCols,
		p.ID, p.DisplayName, p.Age, p.Gender, p.About, p.AvatarKind, p.AvatarValue, p.ShowStatsToOthers,
	)
	return scanUser(row)
}

// UpdateUserLastSeen sets last_seen_at to now() for the given user.
func UpdateUserLastSeen(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx,
		`UPDATE users SET last_seen_at = now() WHERE id = $1`,
		userID,
	)
	return err
}

// PresenceEntry holds online status and last_seen_at for a user.
type PresenceEntry struct {
	Online     bool
	LastSeenAt *time.Time
}

// GetLastSeenForUsers returns last_seen_at for the given user IDs.
// Users not in the map have no last_seen_at recorded.
func GetLastSeenForUsers(ctx context.Context, pool *pgxpool.Pool, userIDs []uuid.UUID) (map[uuid.UUID]*time.Time, error) {
	result := make(map[uuid.UUID]*time.Time)
	for _, id := range userIDs {
		var t time.Time
		err := pool.QueryRow(ctx,
			`SELECT last_seen_at FROM users WHERE id = $1 AND last_seen_at IS NOT NULL`,
			id,
		).Scan(&t)
		if err == pgx.ErrNoRows {
			continue
		}
		if err != nil {
			return nil, err
		}
		result[id] = &t
	}
	return result, nil
}

// GetPresenceRecipientsForUser returns user IDs that should receive
// user_online/user_offline when the given user connects or disconnects:
// friends + chat peers.
func GetPresenceRecipientsForUser(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := pool.Query(ctx, `
		(SELECT CASE WHEN user_low = $1 THEN user_high ELSE user_low END AS peer_id
		 FROM friendships WHERE user_low = $1 OR user_high = $1)
		UNION
		(SELECT CASE WHEN user_low = $1 THEN user_high ELSE user_low END AS peer_id
		 FROM chats WHERE user_low = $1 OR user_high = $1)
	`, userID, userID, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	seen := make(map[uuid.UUID]struct{})
	var result []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		if id == userID {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		result = append(result, id)
	}
	return result, rows.Err()
}
