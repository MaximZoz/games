package store

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	// BronzePerSilver — 100 бронзы = 1 серебро (единое хранилище balance_bronze).
	BronzePerSilver = 100

	RegistrationBonusBronze = 50
	DailyBaseRewardBronze   = 10
	DailyStreakCycleDays    = 30
)

// ErrAlreadyClaimed — ежедневная награда уже получена сегодня.
var ErrAlreadyClaimed = fmt.Errorf("daily reward already claimed today")

// DailyRewardInfo — статус ежедневной награды для API/UI.
type DailyRewardInfo struct {
	Available         bool
	Streak            int // серия после последнего успешного клейма (0 — ещё не было)
	NextStreak        int // серия, если забрать сегодня
	NextRewardBronze  int
	MilestonesBronze  map[int]int // день серии → награда в бронзе (для UI)
}

// DailyRewardBronzeForStreak возвращает награду за день серии (в бронзовых).
// День 1 и обычные дни: 10 бронзы; 3: 50 бронзы; 7: 10 серебра; 30: 30 серебра.
func DailyRewardBronzeForStreak(streak int) int {
	switch streak {
	case 3:
		return 50
	case 7:
		return 10 * BronzePerSilver
	case 30:
		return 30 * BronzePerSilver
	default:
		return DailyBaseRewardBronze
	}
}

// DailyRewardMilestones — ключевые дни для отображения в UI.
func DailyRewardMilestones() map[int]int {
	return map[int]int{
		1:  DailyRewardBronzeForStreak(1),
		3:  DailyRewardBronzeForStreak(3),
		7:  DailyRewardBronzeForStreak(7),
		30: DailyRewardBronzeForStreak(30),
	}
}

func utcDate(t time.Time) time.Time {
	u := t.UTC()
	return time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
}

// NextDailyStreak считает серию на сегодня по дате прошлого клейма.
func NextDailyStreak(claimedAt *time.Time, currentStreak int, now time.Time) int {
	if claimedAt == nil {
		return 1
	}
	claimedDay := utcDate(*claimedAt)
	today := utcDate(now)
	yesterday := today.AddDate(0, 0, -1)

	if claimedDay.Equal(today) {
		if currentStreak < 1 {
			return 1
		}
		return currentStreak
	}
	if claimedDay.Equal(yesterday) {
		next := currentStreak + 1
		if next > DailyStreakCycleDays {
			return 1
		}
		if next < 1 {
			return 1
		}
		return next
	}
	return 1
}

// CanClaimDailyReward returns true if user has not claimed today (by UTC date).
func CanClaimDailyReward(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (bool, error) {
	info, err := GetDailyRewardInfo(ctx, pool, userID)
	if err != nil {
		return false, err
	}
	return info.Available, nil
}

// GetDailyRewardInfo возвращает available/streak/следующую награду.
func GetDailyRewardInfo(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (DailyRewardInfo, error) {
	var claimedAt *time.Time
	var streak int
	err := pool.QueryRow(ctx, `
		SELECT daily_reward_claimed_at, daily_login_streak
		FROM users WHERE id = $1
	`, userID).Scan(&claimedAt, &streak)
	if err != nil {
		return DailyRewardInfo{}, err
	}

	now := time.Now().UTC()
	available := true
	if claimedAt != nil {
		claimed := utcDate(*claimedAt)
		today := utcDate(now)
		available = !claimed.Equal(today)
	}

	nextStreak := NextDailyStreak(claimedAt, streak, now)
	return DailyRewardInfo{
		Available:        available,
		Streak:           streak,
		NextStreak:       nextStreak,
		NextRewardBronze: DailyRewardBronzeForStreak(nextStreak),
		MilestonesBronze: DailyRewardMilestones(),
	}, nil
}

// ClaimDailyRewardResult — итог клейма.
type ClaimDailyRewardResult struct {
	BalanceBronze int
	RewardBronze  int
	Streak        int
}

// ClaimDailyReward начисляет награду по серии дней и обновляет streak.
func ClaimDailyReward(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (ClaimDailyRewardResult, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return ClaimDailyRewardResult{}, err
	}
	defer tx.Rollback(ctx)

	var claimedAt *time.Time
	var streak int
	err = tx.QueryRow(ctx, `
		SELECT daily_reward_claimed_at, daily_login_streak
		FROM users WHERE id = $1
		FOR UPDATE
	`, userID).Scan(&claimedAt, &streak)
	if err != nil {
		return ClaimDailyRewardResult{}, err
	}

	now := time.Now().UTC()
	if claimedAt != nil && utcDate(*claimedAt).Equal(utcDate(now)) {
		return ClaimDailyRewardResult{}, ErrAlreadyClaimed
	}

	nextStreak := NextDailyStreak(claimedAt, streak, now)
	reward := DailyRewardBronzeForStreak(nextStreak)

	var newBalance int
	err = tx.QueryRow(ctx, `
		UPDATE users SET
			balance_bronze = balance_bronze + $2,
			daily_reward_claimed_at = now(),
			daily_login_streak = $3,
			updated_at = now()
		WHERE id = $1
		RETURNING balance_bronze
	`, userID, reward, nextStreak).Scan(&newBalance)
	if err != nil {
		return ClaimDailyRewardResult{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return ClaimDailyRewardResult{}, err
	}
	return ClaimDailyRewardResult{
		BalanceBronze: newBalance,
		RewardBronze:  reward,
		Streak:        nextStreak,
	}, nil
}
