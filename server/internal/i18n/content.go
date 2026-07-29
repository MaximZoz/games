package i18n

import "strings"

// Achievement and push content keys.

func AchievementTitle(lang, code string) string {
	return Content(lang, "ach.title."+code)
}

func AchievementDescription(lang, code string) string {
	return Content(lang, "ach.desc."+code)
}

// Content returns a localized content string (achievements, push, labels).
func Content(lang, key string) string {
	lang = Normalize(lang)
	byLang, ok := contentCatalog[key]
	if !ok {
		return ""
	}
	if v := byLang[lang]; v != "" {
		return v
	}
	if v := byLang[LangEN]; v != "" {
		return v
	}
	return byLang[LangRU]
}

// Contentf replaces {name} placeholders in a content string.
func Contentf(lang, key string, vars map[string]string) string {
	s := Content(lang, key)
	for k, v := range vars {
		s = strings.ReplaceAll(s, "{"+k+"}", v)
	}
	return s
}
