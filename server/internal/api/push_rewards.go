package api

import (
	"strings"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func notifyAchievementUnlocks(push *WebPushSender, userID uuid.UUID, unlocked []store.AchievementDef) {
	if push == nil || !push.CanNotify() || len(unlocked) == 0 {
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
		push.NotifyUsers([]uuid.UUID{userID}, store.WebPushCategoryRewards, PushPayload{
			Title: i18n.Content(lang, "push.new_achievement"),
			Body:  body,
			URL:   "/achievements",
			Tag:   "achievement_" + def.Code,
		})
	}
}
