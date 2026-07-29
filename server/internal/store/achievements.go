package store

import (
	"context"
	"fmt"
	"sort"
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
	AchievementWinsBronze10    = "wins_bronze_10"
	AchievementWinsSilver10    = "wins_silver_10"
	AchievementWinsGold10      = "wins_gold_10"

	AchievementRewardBronze = 25

	FrameBronzeCode = "frame_bronze"
	FrameSilverCode = "frame_silver"
	FrameGoldCode   = "frame_gold"

	// StakeBronzeMax — ставки ниже этого порога считаются бронзовой лигой.
	StakeBronzeMax = 100
	// StakeSilverMax — серебро до этого порога (включительно начиная со StakeBronzeMax).
	StakeSilverMax = 10000
)

// ErrAchievementNotUnlocked — достижение ещё не разблокировано.
var ErrAchievementNotUnlocked = fmt.Errorf("achievement not unlocked")

// ErrAchievementAlreadyClaimed — награда уже забрана.
var ErrAchievementAlreadyClaimed = fmt.Errorf("achievement already claimed")

// ErrAchievementUnknown — неизвестный код.
var ErrAchievementUnknown = fmt.Errorf("unknown achievement")

type AchievementDef struct {
	Code           string
	Title          string
	Description    string
	RewardBronze   int
	RewardItemCode string // опционально: предмет в инвентарь (рамка и т.п.)
	Target         int
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
		{
			Code:           AchievementWinsBronze10,
			Title:          "Бронзовая рамка",
			Description:    "Выиграйте 10 игр на бронзовых ставках",
			RewardBronze:   0,
			RewardItemCode: FrameBronzeCode,
			Target:         10,
		},
		{
			Code:           AchievementWinsSilver10,
			Title:          "Серебряная рамка",
			Description:    "Выиграйте 10 игр на серебряных ставках",
			RewardBronze:   0,
			RewardItemCode: FrameSilverCode,
			Target:         10,
		},
		{
			Code:           AchievementWinsGold10,
			Title:          "Золотая рамка",
			Description:    "Выиграйте 10 игр на золотых ставках",
			RewardBronze:   0,
			RewardItemCode: FrameGoldCode,
			Target:         10,
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

// StakeLeague — лига ставки по бронзовому номиналу.
func StakeLeague(stakeBronze int) string {
	if stakeBronze >= StakeSilverMax {
		return "gold"
	}
	if stakeBronze >= StakeBronzeMax {
		return "silver"
	}
	if stakeBronze > 0 {
		return "bronze"
	}
	return ""
}

// AchievementItem — состояние одного достижения для API.
type AchievementItem struct {
	Code           string
	Title          string
	Description    string
	RewardBronze   int
	RewardItemCode string
	Progress       int
	Target         int
	Status         string // locked | unlocked | claimed
	UnlockedAt     *time.Time
	ClaimedAt      *time.Time
}

type achievementRow struct {
	Code         string
	RewardBronze int
	UnlockedAt   time.Time
	ClaimedAt    *time.Time
}

type userWinStats struct {
	WinsBronze int
	WinsSilver int
	WinsGold   int
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

// IncrementWinsByStake увеличивает счётчик побед в лиге ставки.
func IncrementWinsByStake(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, stakeBronze int) error {
	league := StakeLeague(stakeBronze)
	if league == "" {
		return nil
	}
	col := "wins_bronze"
	switch league {
	case "silver":
		col = "wins_silver"
	case "gold":
		col = "wins_gold"
	}
	q := fmt.Sprintf(`
		INSERT INTO user_stats (user_id, games_finished, %s)
		VALUES ($1, 0, 1)
		ON CONFLICT (user_id) DO UPDATE
		SET %s = user_stats.%s + 1
	`, col, col, col)
	_, err := pool.Exec(ctx, q, userID)
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

func GetWinStats(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (userWinStats, error) {
	var s userWinStats
	err := pool.QueryRow(ctx, `
		SELECT wins_bronze, wins_silver, wins_gold
		FROM user_stats WHERE user_id = $1
	`, userID).Scan(&s.WinsBronze, &s.WinsSilver, &s.WinsGold)
	if err == pgx.ErrNoRows {
		return userWinStats{}, nil
	}
	return s, err
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

func achievementMet(def AchievementDef, profileDone bool, gamesFinished, friendsCount int, wins userWinStats) bool {
	switch def.Code {
	case AchievementProfileComplete:
		return profileDone
	case AchievementGames10:
		return gamesFinished >= def.Target
	case AchievementFriends5:
		return friendsCount >= def.Target
	case AchievementWinsBronze10:
		return wins.WinsBronze >= def.Target
	case AchievementWinsSilver10:
		return wins.WinsSilver >= def.Target
	case AchievementWinsGold10:
		return wins.WinsGold >= def.Target
	default:
		return false
	}
}

// EvaluateAndUnlock проверяет условия и разблокирует новые достижения.
// Возвращает только что разблокированные (для push / UI).
func EvaluateAndUnlock(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]AchievementDef, error) {
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
	wins, err := GetWinStats(ctx, pool, userID)
	if err != nil {
		return nil, err
	}
	existing, err := loadAchievementRows(ctx, pool, userID)
	if err != nil {
		return nil, err
	}

	profileDone := isProfileComplete(u)
	unlocked := make([]AchievementDef, 0)
	for _, def := range AchievementCatalog() {
		if _, ok := existing[def.Code]; ok {
			continue
		}
		if achievementMet(def, profileDone, gamesFinished, friendsCount, wins) {
			if err := unlockAchievement(ctx, pool, userID, def); err != nil {
				return unlocked, err
			}
			unlocked = append(unlocked, def)
		}
	}
	return unlocked, nil
}

func progressFor(def AchievementDef, profileDone bool, gamesFinished, friendsCount int, wins userWinStats) int {
	clamp := func(n int) int {
		if n > def.Target {
			return def.Target
		}
		if n < 0 {
			return 0
		}
		return n
	}
	switch def.Code {
	case AchievementProfileComplete:
		if profileDone {
			return 1
		}
		return 0
	case AchievementGames10:
		return clamp(gamesFinished)
	case AchievementFriends5:
		return clamp(friendsCount)
	case AchievementWinsBronze10:
		return clamp(wins.WinsBronze)
	case AchievementWinsSilver10:
		return clamp(wins.WinsSilver)
	case AchievementWinsGold10:
		return clamp(wins.WinsGold)
	default:
		return 0
	}
}

// ListAchievements возвращает каталог со статусами; перед этим обновляет unlock.
func ListAchievements(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]AchievementItem, error) {
	if _, err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
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
	wins, err := GetWinStats(ctx, pool, userID)
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
			Code:           def.Code,
			Title:          def.Title,
			Description:    def.Description,
			RewardBronze:   def.RewardBronze,
			RewardItemCode: def.RewardItemCode,
			Progress:       progressFor(def, profileDone, gamesFinished, friendsCount, wins),
			Target:         def.Target,
			Status:         "locked",
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
	// Сначала то, что можно забрать; потом в прогрессе; полученные — в конце.
	statusRank := map[string]int{
		"unlocked": 0,
		"locked":   1,
		"claimed":  2,
	}
	sort.SliceStable(out, func(i, j int) bool {
		ri := statusRank[out[i].Status]
		rj := statusRank[out[j].Status]
		if ri != rj {
			return ri < rj
		}
		return false
	})
	return out, nil
}

// CountUnclaimedAchievements — для бейджа на главной.
func CountUnclaimedAchievements(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	if _, err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
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
	BalanceBronze  int
	RewardBronze   int
	RewardItemCode string
	Code           string
}

// ClaimAchievement начисляет награду за разблокированное достижение.
func ClaimAchievement(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, code string) (ClaimAchievementResult, error) {
	def, ok := AchievementByCode(code)
	if !ok {
		return ClaimAchievementResult{}, ErrAchievementUnknown
	}

	// На случай, если условие уже выполнено, но строка ещё не создана.
	if _, err := EvaluateAndUnlock(ctx, pool, userID); err != nil {
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
	if reward < 0 {
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

	if reward > 0 {
		_, err = tx.Exec(ctx, `
			UPDATE users SET balance_bronze = balance_bronze + $2, updated_at = now()
			WHERE id = $1
		`, userID, reward)
		if err != nil {
			return ClaimAchievementResult{}, err
		}
	}

	if def.RewardItemCode != "" {
		_, err = tx.Exec(ctx, `
			INSERT INTO user_inventory (user_id, item_code, quantity)
			VALUES ($1, $2, 1)
			ON CONFLICT (user_id, item_code) DO NOTHING
		`, userID, def.RewardItemCode)
		if err != nil {
			return ClaimAchievementResult{}, err
		}
	}

	var balance int
	if err := tx.QueryRow(ctx, `SELECT balance_bronze FROM users WHERE id = $1`, userID).Scan(&balance); err != nil {
		return ClaimAchievementResult{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return ClaimAchievementResult{}, err
	}
	return ClaimAchievementResult{
		BalanceBronze:  balance,
		RewardBronze:   reward,
		RewardItemCode: def.RewardItemCode,
		Code:           def.Code,
	}, nil
}
