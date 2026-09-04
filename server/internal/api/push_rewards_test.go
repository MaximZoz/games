package api

import (
	"testing"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func TestAchievementsUpdatedPayload_Tasks(t *testing.T) {
	payload := achievementsUpdatedPayload([]store.AchievementDef{
		{Code: store.AchievementFriends5},
		{Code: store.AchievementGames10},
	})
	if payload["type"] != "achievements_updated" {
		t.Fatalf("type=%v", payload["type"])
	}
	if payload["tasks"] != true {
		t.Fatalf("tasks=%v", payload["tasks"])
	}
	if payload["achievements"] != false {
		t.Fatalf("achievements=%v", payload["achievements"])
	}
	codes, ok := payload["unlocked"].([]string)
	if !ok || len(codes) != 2 {
		t.Fatalf("unlocked=%v", payload["unlocked"])
	}
	if codes[0] != store.AchievementFriends5 || codes[1] != store.AchievementGames10 {
		t.Fatalf("codes=%v", codes)
	}
}

func TestAchievementsUpdatedPayload_Frames(t *testing.T) {
	payload := achievementsUpdatedPayload([]store.AchievementDef{
		{Code: store.AchievementWinsBronze10},
	})
	if payload["tasks"] != false {
		t.Fatalf("tasks=%v", payload["tasks"])
	}
	if payload["achievements"] != true {
		t.Fatalf("achievements=%v", payload["achievements"])
	}
}

func TestNotifyAchievementUnlocks_EmptyDoesNothing(t *testing.T) {
	notifyAchievementUnlocks(nil, nil, uuid.Nil, nil)
	notifyAchievementUnlocks(nil, nil, uuid.Nil, []store.AchievementDef{})
}
