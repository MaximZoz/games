package api

import (
	"strings"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func achievementsUpdatedPayload(unlocked []store.AchievementDef) map[string]any {
	codes := make([]string, len(unlocked))
	hasTask := false
	hasAchievement := false
	for i, def := range unlocked {
		codes[i] = def.Code
		if store.IsTaskCode(def.Code) {
			hasTask = true
		} else {
			hasAchievement = true
		}
	}
	return map[string]any{
		"type":         "achievements_updated",
		"unlocked":     codes,
		"tasks":        hasTask,
		"achievements": hasAchievement,
	}
}

func notifyAchievementUnlocks(hub *RealtimeHub, push *WebPushSender, userID uuid.UUID, unlocked []store.AchievementDef) {
	if len(unlocked) == 0 {
		return
	}
	if hub != nil {
		hub.PublishToUsers([]uuid.UUID{userID}, achievementsUpdatedPayload(unlocked))
	}
	if push == nil || !push.CanNotify() {
		return
	}
	// Push has no Accept-Language; default RU (primary audience), body uses localized title.
	lang := i18n.LangRU
	for _, def := range unlocked {
		body := i18n.AchievementTitle(lang, def.Code)
		if strings.TrimSpace(body) == "" {
			body = strings.TrimSpace(def.Title)
		}
		if body == "" {
			body = i18n.Content(lang, "push.new_achievement")
		}
		url := "/achievements"
		if store.IsTaskCode(def.Code) {
			url = "/coins/tasks"
		}
		push.NotifyUsers([]uuid.UUID{userID}, store.WebPushCategoryRewards, PushPayload{
			Title: i18n.Content(lang, "push.new_achievement"),
			Body:  body,
			URL:   url,
			Tag:   "achievement_" + def.Code,
		})
	}
}
