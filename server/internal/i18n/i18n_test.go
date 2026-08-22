package i18n

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNormalize(t *testing.T) {
	cases := map[string]string{
		"":                        LangRU,
		"ru":                      LangRU,
		"ru-RU":                   LangRU,
		"ru-RU,ru;q=0.9,en;q=0.8": LangRU,
		"en":                      LangEN,
		"en-US,en;q=0.9":          LangEN,
		"de-DE,de;q=0.9":          LangDE,
		"uk":                      LangUK,
		"uk-UA":                   LangUK,
		"no":                      LangNB,
		"nn-NO":                   LangNB,
		"nb":                      LangNB,
		"zh-CN":                   LangZH,
		"pt-BR":                   LangPT,
		"xx-YY":                   LangEN,
		"iw":                      LangHE,
		"in":                      LangID,
	}
	for in, want := range cases {
		if got := Normalize(in); got != want {
			t.Fatalf("Normalize(%q)=%q, want %q", in, got, want)
		}
	}
}

func TestNormalizeAllSupported(t *testing.T) {
	for code := range supportedLangs {
		if got := Normalize(code); got != code {
			t.Fatalf("Normalize(%q)=%q, want itself", code, got)
		}
		if got := Normalize(code + "-XX"); got != code {
			t.Fatalf("Normalize(%q-XX)=%q, want %q", code, got, code)
		}
	}
}

func TestLangFromRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/x?lang=en", nil)
	if got := LangFromRequest(req); got != LangEN {
		t.Fatalf("query lang: got %q", got)
	}
	req = httptest.NewRequest(http.MethodGet, "/x?lang=de", nil)
	if got := LangFromRequest(req); got != LangDE {
		t.Fatalf("query de: got %q", got)
	}
	req = httptest.NewRequest(http.MethodGet, "/x", nil)
	req.Header.Set("Accept-Language", "ja-JP,ja;q=0.9")
	if got := LangFromRequest(req); got != LangJA {
		t.Fatalf("header: got %q", got)
	}
	if got := LangFromRequest(nil); got != LangRU {
		t.Fatalf("nil: got %q", got)
	}
}

func TestT(t *testing.T) {
	if got := T(LangRU, "unauthorized"); got != "Требуется авторизация" {
		t.Fatalf("ru unauthorized: %q", got)
	}
	if got := T(LangEN, "unauthorized"); got != "unauthorized" {
		t.Fatalf("en unauthorized: %q", got)
	}
	if got := T(LangDE, "unauthorized"); got != "Anmeldung erforderlich" {
		t.Fatalf("de unauthorized: %q", got)
	}
	if got := T(LangRU, "login already taken"); got != "Такой логин уже занят" {
		t.Fatalf("ru login: %q", got)
	}
	if got := T(LangEN, "Такой логин уже занят"); got != "login already taken" {
		t.Fatalf("en legacy: %q", got)
	}
	if got := T(LangDE, "Такой логин уже занят"); got != "Login bereits vergeben" {
		t.Fatalf("de legacy: %q", got)
	}
	if got := T(LangRU, "cell must be 0-8"); got != "Клетка должна быть от 0 до 8" {
		t.Fatalf("prefix ru: %q", got)
	}
	if got := T(LangEN, "cell must be 0-8"); got != "cell must be 0-8" {
		t.Fatalf("prefix en: %q", got)
	}
	if got := T(LangFR, "invalid user_id: abc"); got != "user_id invalide : abc" {
		t.Fatalf("prefix fr: %q", got)
	}
	if got := T(LangEN, "uno: only the same +2 or +4 can stack"); got != ErrUnoStackSameOnly {
		t.Fatalf("en uno stack: %q", got)
	}
	if got := T(LangRU, "uno: only the same +2 or +4 can stack"); got == ErrUnoStackSameOnly || got == "" {
		t.Fatalf("ru uno stack left English: %q", got)
	}
	if got := T(LangEN, "you cannot call UNO now"); got != ErrUnoCallTooLate {
		t.Fatalf("en uno late call: %q", got)
	}
	if got := T(LangRU, "you cannot call UNO now"); got == "you cannot call UNO now" || got == ErrUnoCallTooLate || got == "" {
		t.Fatalf("ru uno late call left English: %q", got)
	}
}

func TestCatalogComplete(t *testing.T) {
	for _, cat := range []map[string]map[string]string{catalog, actionCatalog} {
		for key, byLang := range cat {
			for code := range supportedLangs {
				if code == LangEN {
					continue
				}
				if v := byLang[code]; v == "" {
					t.Fatalf("missing translation key=%q lang=%q", key, code)
				}
			}
		}
	}
	for _, p := range prefixes {
		for code := range supportedLangs {
			if code == LangEN {
				continue
			}
			if v := p.translations[code]; v == "" {
				t.Fatalf("missing prefix translation en=%q lang=%q", p.en, code)
			}
		}
	}
}

func TestTNoEnglishLeftovers(t *testing.T) {
	sample := []string{"unauthorized", "game not found", "server error", "forbidden", "not your turn"}
	for _, key := range sample {
		for code := range supportedLangs {
			if code == LangEN {
				continue
			}
			got := T(code, key)
			if got == "" || got == key {
				t.Fatalf("T(%q,%q) left English key: %q", code, key, got)
			}
		}
	}
}
