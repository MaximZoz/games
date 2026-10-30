package api

import (
	"context"
	"errors"
	"testing"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func TestCollectRewardPushSkipsOnlineAndGroupsLang(t *testing.T) {
	idOnline := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	idClaimed := uuid.MustParse("00000000-0000-0000-0000-000000000002")
	idRu := uuid.MustParse("00000000-0000-0000-0000-000000000003")
	idEn := uuid.MustParse("00000000-0000-0000-0000-000000000004")
	idMarked := uuid.MustParse("00000000-0000-0000-0000-000000000005")
	var marked []uuid.UUID

	batches, next, err := collectRewardPushBatches(context.Background(), rewardSweepHooks{
		List: func(ctx context.Context, after uuid.UUID, limit int) ([]store.RewardPushCandidate, error) {
			if after != uuid.Nil {
				return nil, nil
			}
			return []store.RewardPushCandidate{
				{UserID: idOnline, Lang: "ru"},
				{UserID: idClaimed, Lang: "ru"},
				{UserID: idRu, Lang: ""},
				{UserID: idEn, Lang: "en-US"},
				{UserID: idMarked, Lang: "de"},
			}, nil
		},
		Ready: func(ctx context.Context, id uuid.UUID) (bool, error) {
			return id != idClaimed, nil
		},
		Mark: func(ctx context.Context, id uuid.UUID) (bool, error) {
			marked = append(marked, id)
			return id != idMarked, nil
		},
		Online: func(id uuid.UUID) bool { return id == idOnline },
	}, uuid.Nil, 100, 5)
	if err != nil {
		t.Fatal(err)
	}
	if next != uuid.Nil {
		t.Fatalf("short page should wrap, next=%s", next)
	}
	for _, id := range marked {
		if id == idOnline || id == idClaimed {
			t.Fatalf("should not mark %s", id)
		}
	}
	if len(batches["ru"]) != 1 || batches["ru"][0] != idRu {
		t.Fatalf("ru=%v", batches["ru"])
	}
	if len(batches["en"]) != 1 || batches["en"][0] != idEn {
		t.Fatalf("en=%v", batches["en"])
	}
	if _, ok := batches["de"]; ok {
		t.Fatal("failed mark must not be sent")
	}
}

func TestCollectRewardPushPagesPastOnline(t *testing.T) {
	online := uuid.MustParse("00000000-0000-0000-0000-0000000000aa")
	offline := uuid.MustParse("00000000-0000-0000-0000-0000000000bb")
	calls := 0
	batches, next, err := collectRewardPushBatches(context.Background(), rewardSweepHooks{
		List: func(ctx context.Context, after uuid.UUID, limit int) ([]store.RewardPushCandidate, error) {
			calls++
			if after == uuid.Nil {
				return []store.RewardPushCandidate{{UserID: online, Lang: "ru"}}, nil
			}
			if after == online {
				return []store.RewardPushCandidate{{UserID: offline, Lang: "ru"}}, nil
			}
			return nil, nil
		},
		Ready:  func(ctx context.Context, id uuid.UUID) (bool, error) { return true, nil },
		Mark:   func(ctx context.Context, id uuid.UUID) (bool, error) { return true, nil },
		Online: func(id uuid.UUID) bool { return id == online },
	}, uuid.Nil, 1, 5)
	if err != nil {
		t.Fatal(err)
	}
	if calls < 2 {
		t.Fatalf("calls=%d", calls)
	}
	if next != uuid.Nil {
		t.Fatalf("wrapped next=%s", next)
	}
	if len(batches["ru"]) != 1 || batches["ru"][0] != offline {
		t.Fatalf("batches=%v", batches["ru"])
	}
}

func TestCollectRewardPushKeepsCursorOnError(t *testing.T) {
	first := uuid.MustParse("00000000-0000-0000-0000-000000000010")
	start := uuid.MustParse("00000000-0000-0000-0000-00000000000f")
	batches, next, err := collectRewardPushBatches(context.Background(), rewardSweepHooks{
		List: func(ctx context.Context, after uuid.UUID, limit int) ([]store.RewardPushCandidate, error) {
			if after == start {
				return []store.RewardPushCandidate{{UserID: first, Lang: "ru"}}, nil
			}
			return nil, errors.New("db down")
		},
		Ready: func(ctx context.Context, id uuid.UUID) (bool, error) { return true, nil },
		Mark:  func(ctx context.Context, id uuid.UUID) (bool, error) { return true, nil },
	}, start, 1, 5)
	if err == nil {
		t.Fatal("expected error")
	}
	if next != first {
		t.Fatalf("resume from last scanned, next=%s", next)
	}
	if len(batches["ru"]) != 1 || batches["ru"][0] != first {
		t.Fatalf("partial batch=%v", batches["ru"])
	}
}

func TestRewardPushPayload(t *testing.T) {
	daily := rewardPushPayload(rewardPushDaily, "ru")
	if daily.URL != "/coins/login" || daily.Tag != "daily_reward" || daily.Title == "" || daily.Body == "" {
		t.Fatalf("daily=%+v", daily)
	}
	income := rewardPushPayload(rewardPushIncome, "en")
	if income.URL != "/inventory" || income.Tag != "collection_income" {
		t.Fatalf("income=%+v", income)
	}
	if income.Title != "Item income" || income.Body == "" {
		t.Fatalf("income text=%+v", income)
	}
	ru := rewardPushPayload(rewardPushIncome, "ru")
	if ru.Title != "Доход с предметов" {
		t.Fatalf("ru title=%q", ru.Title)
	}
}
