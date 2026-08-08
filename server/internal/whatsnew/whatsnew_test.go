package whatsnew

import "testing"

func TestFormatLegacy(t *testing.T) {
	raw := "# Title\n\n- One\n- Two\n"
	got := Format(raw, "en")
	if got != "- One\n- Two" {
		t.Fatalf("got %q", got)
	}
}

func TestFormatSections(t *testing.T) {
	raw := `# Что нового

## ru
- Пункт раз
- Пункт два

## en
- Item one
- Item two
`
	if got := Format(raw, "en"); got != "- Item one\n- Item two" {
		t.Fatalf("en=%q", got)
	}
	if got := Format(raw, "ru"); got != "- Пункт раз\n- Пункт два" {
		t.Fatalf("ru=%q", got)
	}
	// Нет секции de → en fallback.
	if got := Format(raw, "de"); got != "- Item one\n- Item two" {
		t.Fatalf("de fallback en=%q", got)
	}
}

func TestSourceRU(t *testing.T) {
	raw := "## en\n- Hi\n\n## ru\n- Привет\n"
	if got := SourceRU(raw); got != "- Привет" {
		t.Fatalf("%q", got)
	}
	if !HasLang(raw, "en") || HasLang(raw, "de") {
		t.Fatal("HasLang")
	}
}
