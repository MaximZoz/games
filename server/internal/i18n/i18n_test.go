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
		"de-DE,de;q=0.9":          LangEN,
	}
	for in, want := range cases {
		if got := Normalize(in); got != want {
			t.Fatalf("Normalize(%q)=%q, want %q", in, got, want)
		}
	}
}

func TestLangFromRequest(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/x?lang=en", nil)
	if got := LangFromRequest(req); got != LangEN {
		t.Fatalf("query lang: got %q", got)
	}
	req = httptest.NewRequest(http.MethodGet, "/x", nil)
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	if got := LangFromRequest(req); got != LangEN {
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
	if got := T(LangRU, "login already taken"); got != "Такой логин уже занят" {
		t.Fatalf("ru login: %q", got)
	}
	if got := T(LangEN, "Такой логин уже занят"); got != "login already taken" {
		t.Fatalf("en legacy: %q", got)
	}
	if got := T(LangRU, "cell must be 0-8"); got != "Клетка должна быть от 0 до 8" {
		t.Fatalf("prefix: %q", got)
	}
}
