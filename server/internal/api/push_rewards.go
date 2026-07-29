package api

import (
	"strings"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func notifyAchievementUnlocks(push *WebPushSender, userID uuid.UUID, unlocked []store.AchievementDef) {
	if push == nil || !push.Enabled() || len(unlocked) == 0 {
		return
	}
	for _, def := range unlocked {
		title := strings.TrimSpace(def.Title)
		if title == "" {
			title = "Новое достижение"
		}
		push.NotifyUsers([]uuid.UUID{userID}, store.WebPushCategoryRewards, PushPayload{
			Title: "Новое достижение",
			Body:  title,
			URL:   "/achievements",
			Tag:   "achievement_" + def.Code,
		})
	}
}
