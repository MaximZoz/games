package i18n

import (
	"net/http"
	"strings"
)

// Supported language codes (aligned with Flutter client locales).
const (
	LangAR = "ar"
	LangBE = "be"
	LangCS = "cs"
	LangDA = "da"
	LangDE = "de"
	LangEL = "el"
	LangEN = "en"
	LangES = "es"
	LangFI = "fi"
	LangFR = "fr"
	LangHE = "he"
	LangHI = "hi"
	LangID = "id"
	LangIT = "it"
	LangJA = "ja"
	LangKK = "kk"
	LangKO = "ko"
	LangNB = "nb"
	LangNL = "nl"
	LangPL = "pl"
	LangPT = "pt"
	LangRU = "ru"
	LangSV = "sv"
	LangTH = "th"
	LangTR = "tr"
	LangUK = "uk"
	LangUZ = "uz"
	LangVI = "vi"
	LangZH = "zh"
)

// supportedLangs is the set of canonical BCP-47 primary language subtags we serve.
var supportedLangs = map[string]struct{}{
	LangAR: {}, LangBE: {}, LangCS: {}, LangDA: {}, LangDE: {}, LangEL: {},
	LangEN: {}, LangES: {}, LangFI: {}, LangFR: {}, LangHE: {}, LangHI: {},
	LangID: {}, LangIT: {}, LangJA: {}, LangKK: {}, LangKO: {}, LangNB: {},
	LangNL: {}, LangPL: {}, LangPT: {}, LangRU: {}, LangSV: {}, LangTH: {},
	LangTR: {}, LangUK: {}, LangUZ: {}, LangVI: {}, LangZH: {},
}

// LangFromRequest reads Accept-Language (or ?lang=) and returns a supported code.
// Empty / missing → ru (historical default).
func LangFromRequest(r *http.Request) string {
	if r == nil {
		return LangRU
	}
	if q := strings.TrimSpace(r.URL.Query().Get("lang")); q != "" {
		return Normalize(q)
	}
	if al := strings.TrimSpace(r.Header.Get("Accept-Language")); al != "" {
		return Normalize(al)
	}
	return LangRU
}

// Normalize maps Accept-Language / locale tags to a supported code.
// "ru-RU,ru;q=0.9,en;q=0.8" → ru; no/nn → nb; unknown → en.
// Empty → ru.
func Normalize(raw string) string {
	s := strings.ToLower(strings.TrimSpace(raw))
	if s == "" {
		return LangRU
	}
	first := s
	if i := strings.IndexAny(s, ",;"); i >= 0 {
		first = s[:i]
	}
	first = strings.TrimSpace(first)
	if first == "" {
		return LangRU
	}
	// Primary subtag (before region / script).
	base := first
	if i := strings.IndexAny(first, "-_"); i >= 0 {
		base = first[:i]
	}
	switch base {
	case "no", "nn":
		return LangNB
	case "iw": // legacy Hebrew
		return LangHE
	case "in": // legacy Indonesian
		return LangID
	case "zh":
		return LangZH
	}
	if _, ok := supportedLangs[base]; ok {
		return base
	}
	return LangEN
}

// T translates a canonical English API error key into lang.
// For en, returns the key as-is (after resolving legacy Russian keys).
func T(lang, key string) string {
	key = strings.TrimSpace(key)
	if key == "" {
		return key
	}
	lang = Normalize(lang)

	if en, ok := legacyRUToEN[key]; ok {
		key = en
	}

	if lang == LangEN {
		return key
	}

	if byLang, ok := catalog[key]; ok {
		if v := byLang[lang]; v != "" {
			return v
		}
	}

	for _, p := range prefixes {
		if strings.HasPrefix(key, p.en) {
			if pref := p.translations[lang]; pref != "" {
				return pref + strings.TrimPrefix(key, p.en)
			}
			break
		}
	}
	return key
}
