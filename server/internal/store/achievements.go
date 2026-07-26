package store

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	AchievementProfileComplete = "profile_complete"
	AchievementGames10         = "games_10"
	AchievementFriends5        = "friends_5"

	AchievementRewardBronze = 25
)

// ErrAchievementNotUnlocked — достижение ещё не разблокировано.
var ErrAchievementNotUnlocked = fmt.Errorf("achievement not unlocked")

// ErrAchievementAlreadyClaimed — награда уже забрана.
var ErrAchievementAlreadyClaimed = fmt.Errorf("achievement already claimed")

// ErrAchievementUnknown — неизвестный код.
var ErrAchievementUnknown = fmt.Errorf("unknown achievement")

type AchievementDef struct {
	Code         string
	Title        string
	Description  string
	RewardBronze int
	Target       int
}

func AchievementCatalog() []AchievementDef {
	return []AchievementDef{
		{
			Code:         AchievementProfileComplete,
			Title:        "Полная анкета",
			Description:  "Заполните все поля профиля и загрузите фото",
			RewardBronze: AchievementRewardBronze,
			Target:       1,
		},
		{
			Code:         AchievementGames10,
			Title:        "10 игр",
			Description:  "Сыграйте 10 партий в любые игры",
			RewardBronze: AchievementRewardBronze,
			Target:       10,
		},
		{
			Code:         AchievementFriends5,
			Title:        "5 друзей",
			Description:  "Добавьте 5 друзей",
			RewardBronze: AchievementRewardBronze,
			Target:       5,
		},
	}
}

func AchievementByCode(code string) (AchievementDef, bool) {
	for _, d := range AchievementCatalog() {
		if d.Code == code {
			return d, true
		}
	}
	return AchievementDef{}, false
}

// AchievementItem — состояние одного достижения для API.
type AchievementItem struct {
	Code         string
	Title        string
	Description  string
	RewardBronze int
	Progress     int
	Target       int
	Status       string // locked | unlocked | claimed
	UnlockedAt   *time.Time
	ClaimedAt    *time.Time
}

type achievementRow struct {
	Code         string
	RewardBronze int
	UnlockedAt   time.Time
	ClaimedAt    *time.Time
}

// IncrementGamesFinished увеличивает счётчик завершённых партий.
func IncrementGamesFinished(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO user_stats (user_id, games_finished)
		VALUES ($1, 1)
		ON CONFLICT (user_id) DO UPDATE
		SET games_finished = user_stats.games_finished + 1
	`, userID)
	return err
}

func GetGamesFinished(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `
		SELECT games_finished FROM user_stats WHERE user_id = $1
	`, userID).Scan(&n)
	if err == pgx.ErrNoRows {
		return 0, nil
	}
	return n, err
}

func CountFriends(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `
		SELECT COUNT(*)::int FROM friendships
		WHERE user_low = $1 OR user_high = $1
	`, userID).Scan(&n)
	return n, err
}

func isProfileComplete(u *User) bool {
	if u == nil {
		return false
	}
	name := ""
	if u.DisplayName != nil {
		name = strings.TrimSpace(*u.DisplayName)
	}
	about := ""
	if u.About != nil {
		about = strings.TrimSpace(*u.About)
	}
	gender := ""
	if u.Gender != nil {
		gender = strings.TrimSpace(*u.Gender)
	}
	avatarOK := u.AvatarKind == "file" &&
		u.AvatarValue != nil &&
		strings.TrimSpace(*u.AvatarValue) != ""
	return name != "" &&
		u.Age != nil && *u.Age > 0 &&
		gender != "" &&
		about != "" &&
		avatarOK
}

func loadAchievementRows(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (map[string]achievementRow, error) {
	rows, err := pool.Query(ctx, `
		SELECT code, reward_bronze, unlocked_at, claimed_at
		FROM user_achievements
		WHERE user_id = $1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := make(map[string]achievementRow)
	for rows.Next() {
		var r achievementRow
		if err := rows.Scan(&r.Code, &r.RewardBronze, &r.UnlockedAt, &r.ClaimedAt); err != nil {
			return nil, err
		}
		out[r.Code] = r
	}
	return out, rows.Err()
}

func unlockAchievement(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, def AchievementDef) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO user_achievements (user_id, code, reward_bronze, unlocked_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (user_id, code) DO NOTHING
	`, userID, def.Code, def.RewardBronze)
	return err
}

// EvaluateAndUnlock проверяет условия и разблокирует новые достижения.
func EvaluateAndUnlock(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	u, err := GetUserByID(ctx, pool, userID)
	if err != nil {
		return err
	}
	gamesFinished, err := GetGamesFinished(ctx, pool, userID)
	if err != nil {
		return err
	}
	friendsCount, err := CountFriends(ctx, pool, userID)
	if err != nil {
		return err
	}
	existing, err := loadAchievementRows(ctx, pool, userID)
	if err != nil {
		return err
	}

	for _, def := range AchievementCatalog() {
		if _, ok := existing[def.Code]; ok {
			continue
		}
		met := false
		switch def.Code {
		case AchievementProfileComplete:
			met = isProfileComplete(u)
		case AchievementGames10:
			met = gamesFinished >= def.Target
		case AchievementFriends5:
			met = friendsCount >= def.Target
		}
		if met {
			if err := unlockAchievement(ctx, pool, userID, def); err != nil {
				return err
			}
		}
	}
	return nil
}

func progressFor(def AchievementDef, profileDone bool, gamesFinished, friendsCount int) int {
	switch def.Code {
	case AchievementProfileComplete:
		if profileDone {
			return 1
		}
		return 0
	case AchievementGames10:
		if gamesFinished > def.Target {
			return def.Target
		}
		return gamesFinished
	case AchievementFriends5:
		if friendsCount > def.Target {
			return def.Target
		}
		return friendsCount
	default:
		return 0
	}
}

// ListAchievements возвращает каталог со статусами; перед этим обновляет unlock.
func ListAchievements(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]AchievementItem, error) {
	if err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
		return nil, err
	}
	u, err := GetUserByID(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	gamesFinished, err := GetGamesFinished(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	friendsCount, err := CountFriends(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	rows, err := loadAchievementRows(ctx, pool, userID)
	if err != nil {
		return nil, err
	}

	profileDone := isProfileComplete(u)
	out := make([]AchievementItem, 0, len(AchievementCatalog()))
	for _, def := range AchievementCatalog() {
		item := AchievementItem{
			Code:         def.Code,
			Title:        def.Title,
			Description:  def.Description,
			RewardBronze: def.RewardBronze,
			Progress:     progressFor(def, profileDone, gamesFinished, friendsCount),
			Target:       def.Target,
			Status:       "locked",
		}
		if r, ok := rows[def.Code]; ok {
			ua := r.UnlockedAt
			item.UnlockedAt = &ua
			if r.ClaimedAt != nil {
				item.Status = "claimed"
				item.ClaimedAt = r.ClaimedAt
				item.Progress = def.Target
			} else {
				item.Status = "unlocked"
				item.Progress = def.Target
			}
		}
		out = append(out, item)
	}
	return out, nil
}

// CountUnclaimedAchievements — для бейджа на главной.
func CountUnclaimedAchievements(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	if err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
		return 0, err
	}
	var n int
	err := pool.QueryRow(ctx, `
		SELECT COUNT(*)::int FROM user_achievements
		WHERE user_id = $1 AND claimed_at IS NULL
	`, userID).Scan(&n)
	return n, err
}

type ClaimAchievementResult struct {
	BalanceBronze int
	RewardBronze  int
	Code          string
}

// ClaimAchievement начисляет награду за разблокированное достижение.
func ClaimAchievement(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (ClaimAchievementResult, error) {
	def, ok := AchievementByCode(code)
	if !ok {
		return ClaimAchievementResult{}, ErrAchievementUnknown
	}

	// На случай, если условие уже выполнено, но строка ещё не создана.
	if err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
		return ClaimAchievementResult{}, err
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return ClaimAchievementResult{}, err
	}
	defer tx.Rollback(ctx)

	var claimedAt *time.Time
	var reward int
	err = tx.QueryRow(ctx, `
		SELECT reward_bronze, claimed_at
		FROM user_achievements
		WHERE user_id = $1 AND code = $2
		FOR UPDATE
	`, userID, def.Code).Scan(&reward, &claimedAt)
	if err == pgx.ErrNoRows {
		return ClaimAchievementResult{}, ErrAchievementNotUnlocked
	}
	if err != nil {
		return ClaimAchievementResult{}, err
	}
	if claimedAt != nil {
		return ClaimAchievementResult{}, ErrAchievementAlreadyClaimed
	}
	if reward <= 0 {
		reward = def.RewardBronze
	}

	tag, err := tx.Exec(ctx, `
		UPDATE user_achievements
		SET claimed_at = now()
		WHERE user_id = $1 AND code = $2 AND claimed_at IS NULL
	`, userID, def.Code)
	if err != nil {
		return ClaimAchievementResult{}, err
	}
	if tag.RowsAffected() == 0 {
		return ClaimAchievementResult{}, ErrAchievementAlreadyClaimed
	}

	_, err = tx.Exec(ctx, `
		UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now()
		WHERE id = $1
	`, userID, reward)
	if err != nil {
		return ClaimAchievementResult{}, err
	}

	var balance int
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return ClaimAchievementResult{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return ClaimAchievementResult{}, err
	}
	return ClaimAchievementResult{
		BalanceBronze: balance,
		RewardBronze:  reward,
		Code:          def.Code,
	}, nil
}
