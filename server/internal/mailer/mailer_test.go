package mailer

import "testing"

func TestEnabled_Resend(t *testing.T) {
	m := New(Config{ResendAPIKey: "re_test"})
	if !m.Enabled() {
		t.Fatal("expected enabled with Resend key")
	}
	if m.Provider() != "resend" {
		t.Fatalf("provider = %q", m.Provider())
	}
}

func TestEnabled_SMTP(t *testing.T) {
	m := New(Config{Host: "smtp.gmail.com"})
	if !m.Enabled() {
		t.Fatal("expected enabled with SMTP")
	}
	if m.Provider() != "smtp" {
		t.Fatalf("provider = %q", m.Provider())
	}
}

func TestEnabled_None(t *testing.T) {
	m := New(Config{})
	if m.Enabled() {
		t.Fatal("expected disabled")
	}
	if m.Provider() != "log" {
		t.Fatalf("provider = %q", m.Provider())
	}
}

func TestExtractVerificationCode(t *testing.T) {
	body := "Ваш код подтверждения: 123456\n\nКод действует 15 минут.\n"
	if got := extractVerificationCode(body); got != "123456" {
		t.Fatalf("got %q", got)
	}
}
