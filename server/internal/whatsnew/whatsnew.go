// Package whatsnew — разбор WHAT_NEW.md и выбор текста по языку клиента.
package whatsnew

import (
	"strings"
)

// Format возвращает тело changelog для lang.
//
// Формат файла:
//
//	# заголовок (игнор)
//	## ru
//	- пункт
//	## en
//	- item
//
// Если секций ## lang нет — весь текст считается русским (legacy).
// Fallback: запрошенный → en → ru → первая секция → legacy.
func Format(raw, lang string) string {
	lang = normalizeLang(lang)
	sections, legacy := parse(raw)
	if len(sections) == 0 {
		return strings.TrimSpace(legacy)
	}
	for _, key := range []string{lang, "en", "ru"} {
		if body, ok := sections[key]; ok && strings.TrimSpace(body) != "" {
			return strings.TrimSpace(body)
		}
	}
	for _, body := range sections {
		if strings.TrimSpace(body) != "" {
			return strings.TrimSpace(body)
		}
	}
	return strings.TrimSpace(legacy)
}

// SourceRU — исходный русский текст (для автоперевода в другие языки).
func SourceRU(raw string) string {
	sections, legacy := parse(raw)
	if body, ok := sections["ru"]; ok && strings.TrimSpace(body) != "" {
		return strings.TrimSpace(body)
	}
	if strings.TrimSpace(legacy) != "" {
		return strings.TrimSpace(legacy)
	}
	return Format(raw, "ru")
}

// HasLang — есть ли явная секция ## lang (не legacy).
func HasLang(raw, lang string) bool {
	sections, _ := parse(raw)
	body, ok := sections[normalizeLang(lang)]
	return ok && strings.TrimSpace(body) != ""
}

func normalizeLang(lang string) string {
	c := strings.ToLower(strings.TrimSpace(lang))
	if i := strings.IndexByte(c, '-'); i > 0 {
		c = c[:i]
	}
	switch c {
	case "no", "nn":
		return "nb"
	case "iw":
		return "he"
	case "":
		return "ru"
	default:
		return c
	}
}

func parse(raw string) (map[string]string, string) {
	raw = strings.ReplaceAll(raw, "\r\n", "\n")
	lines := strings.Split(raw, "\n")
	sections := map[string]string{}
	var legacy []string
	var curLang string
	var cur []string
	flush := func() {
		if curLang == "" {
			return
		}
		sections[curLang] = strings.TrimSpace(strings.Join(cur, "\n"))
		cur = nil
		curLang = ""
	}
	for _, line := range lines {
		trim := strings.TrimSpace(line)
		if strings.HasPrefix(trim, "## ") {
			flush()
			curLang = normalizeLang(strings.TrimSpace(strings.TrimPrefix(trim, "## ")))
			continue
		}
		// Одиночный # — заголовок файла / комментарий.
		if strings.HasPrefix(trim, "#") {
			continue
		}
		if curLang != "" {
			if trim == "" && len(cur) == 0 {
				continue
			}
			cur = append(cur, strings.TrimRight(line, " \t"))
			continue
		}
		if trim == "" {
			continue
		}
		legacy = append(legacy, strings.TrimRight(line, " \t"))
	}
	flush()
	return sections, strings.Join(legacy, "\n")
}
