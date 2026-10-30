package api

import (
	"context"
	"log"
	"time"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

const (
	rewardPushDaily  = "daily"
	rewardPushIncome = "income"

	rewardPushBatchLimit = 400
	rewardPushMaxPages   = 25
	rewardPushFirstDelay = 25 * time.Second
	rewardPushInterval   = 15 * time.Minute
	rewardPushSweepMax   = 4 * time.Minute
)

// StartRewardPushLoop раз в 15 минут шлёт пуш тем, кто не в приложении:
// монеты за вход и дневной доход коллекций. Пока сокет жив, слот дня не
// сжигаем — иначе баннер уходит в открытое приложение и на телефоне его нет.
func StartRewardPushLoop(
	ctx context.Context,
	pool *pgxpool.Pool,
	hub *RealtimeHub,
	rdb *redis.Client,
	push *WebPushSender,
) {
	if pool == nil || push == nil || !push.CanNotify() {
		log.Printf("reward push: skipped (push disabled)")
		return
	}
	log.Printf("reward push: daily coins and collection income every %s", rewardPushInterval)
	go runRewardPushLoop(ctx, pool, hub, rdb, push)
}

func runRewardPushLoop(
	ctx context.Context,
	pool *pgxpool.Pool,
	hub *RealtimeHub,
	rdb *redis.Client,
	push *WebPushSender,
) {
	timer := time.NewTimer(rewardPushFirstDelay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return
	case <-timer.C:
	}
	var dailyAfter, incomeAfter uuid.UUID
	dailyAfter = sweepRewardPush(ctx, pool, hub, rdb, push, rewardPushDaily, dailyAfter)
	incomeAfter = sweepRewardPush(ctx, pool, hub, rdb, push, rewardPushIncome, incomeAfter)
	ticker := time.NewTicker(rewardPushInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			dailyAfter = sweepRewardPush(ctx, pool, hub, rdb, push, rewardPushDaily, dailyAfter)
			incomeAfter = sweepRewardPush(ctx, pool, hub, rdb, push, rewardPushIncome, incomeAfter)
		}
	}
}

func sweepRewardPush(
	parent context.Context,
	pool *pgxpool.Pool,
	hub *RealtimeHub,
	rdb *redis.Client,
	push *WebPushSender,
	kind string,
	after uuid.UUID,
) uuid.UUID {
	if push == nil || !push.CanNotify() || pool == nil {
		return after
	}
	ctx, cancel := context.WithTimeout(parent, rewardPushSweepMax)
	defer cancel()
	batches, next, err := collectRewardPushBatches(ctx, rewardSweepHooks{
		List: func(ctx context.Context, after uuid.UUID, limit int) ([]store.RewardPushCandidate, error) {
			if kind == rewardPushIncome {
				return store.ListCollectionIncomePushCandidates(ctx, pool, after, limit)
			}
			return store.ListDailyRewardPushCandidates(ctx, pool, after, limit)
		},
		Ready: func(ctx context.Context, userID uuid.UUID) (bool, error) {
			if kind == rewardPushIncome {
				info, infoErr := store.GetCollectionIncomeInfo(ctx, pool, userID)
				if infoErr != nil || info == nil {
					return false, infoErr
				}
				return info.Available && info.AmountBronze > 0, nil
			}
			return store.CanClaimDailyReward(ctx, pool, userID)
		},
		Mark: func(ctx context.Context, userID uuid.UUID) (bool, error) {
			if kind == rewardPushIncome {
				return store.TryMarkCollectionIncomePush(ctx, pool, userID)
			}
			return store.TryMarkDailyRewardPush(ctx, pool, userID)
		},
		Online: func(userID uuid.UUID) bool {
			if hub == nil {
				return false
			}
			return hub.IsUserOnlineAnywhere(ctx, rdb, userID)
		},
	}, after, rewardPushBatchLimit, rewardPushMaxPages)
	if err != nil {
		log.Printf("reward push: %s: %v", kind, err)
	}
	n := deliverRewardPushes(push, kind, batches)
	if n > 0 {
		log.Printf("reward push: %s users=%d", kind, n)
	}
	return next
}

type rewardSweepHooks struct {
	List   func(ctx context.Context, after uuid.UUID, limit int) ([]store.RewardPushCandidate, error)
	Ready  func(ctx context.Context, userID uuid.UUID) (bool, error)
	Mark   func(ctx context.Context, userID uuid.UUID) (bool, error)
	Online func(userID uuid.UUID) bool
}

// collectRewardPushBatches идёт по id дальше [after]. Онлайн не помечаем:
// следующий проход дойдёт до них, когда сокет закроется. Короткий хвост
// возвращает курсор Nil — обход сначала.
func collectRewardPushBatches(
	ctx context.Context,
	hooks rewardSweepHooks,
	start uuid.UUID,
	limit int,
	maxPages int,
) (map[string][]uuid.UUID, uuid.UUID, error) {
	if limit < 1 {
		limit = 1
	}
	if maxPages < 1 {
		maxPages = 1
	}
	out := map[string][]uuid.UUID{}
	after := start
	for page := 0; page < maxPages; page++ {
		if err := ctx.Err(); err != nil {
			return out, after, err
		}
		rows, err := hooks.List(ctx, after, limit)
		if err != nil {
			return out, after, err
		}
		if len(rows) == 0 {
			return out, uuid.Nil, nil
		}
		for _, row := range rows {
			after = row.UserID
			if hooks.Online != nil && hooks.Online(row.UserID) {
				continue
			}
			if hooks.Ready != nil {
				ok, readyErr := hooks.Ready(ctx, row.UserID)
				if readyErr != nil || !ok {
					continue
				}
			}
			if hooks.Mark != nil {
				ok, markErr := hooks.Mark(ctx, row.UserID)
				if markErr != nil || !ok {
					continue
				}
			}
			lang := i18n.Normalize(row.Lang)
			out[lang] = append(out[lang], row.UserID)
		}
		if len(rows) < limit {
			return out, uuid.Nil, nil
		}
	}
	return out, after, nil
}

func deliverRewardPushes(push *WebPushSender, kind string, batches map[string][]uuid.UUID) int {
	if push == nil || len(batches) == 0 {
		return 0
	}
	n := 0
	for lang, ids := range batches {
		if len(ids) == 0 {
			continue
		}
		n += len(ids)
		push.NotifyUsers(ids, store.WebPushCategoryRewards, rewardPushPayload(kind, lang))
	}
	return n
}

func rewardPushPayload(kind, lang string) PushPayload {
	if kind == rewardPushIncome {
		return PushPayload{
			Title: i18n.Content(lang, "push.collection_income_title"),
			Body:  i18n.Content(lang, "push.collection_income_body"),
			URL:   "/inventory",
			Tag:   "collection_income",
		}
	}
	return PushPayload{
		Title: i18n.Content(lang, "push.daily_reward_title"),
		Body:  i18n.Content(lang, "push.daily_reward_body"),
		URL:   "/coins/login",
		Tag:   "daily_reward",
	}
}
