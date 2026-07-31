package mailer

import (
	"strings"
	"testing"
)

func TestEnabled_Resend(t *testing.T) {
	m := New(Config{ResendAPIKey: "re_test"})
	if !m.Enabled() {
		t.Fatal("expected enabled with Resend key")
	}
	if m.Provider() != "resend" {
		t.Fatalf("provider = %q", m.Provider())
	}
}

func TestNormalizeMailFrom(t *testing.T) {
	if got := normalizeMailFrom("", true); got != "ZozuGames <onboarding@resend.dev>" {
		t.Fatalf("empty resend: %q", got)
	}
	if got := normalizeMailFrom("MultiGames <noreply@zozugames.com>", true); got != "ZozuGames <noreply@zozugames.com>" {
		t.Fatalf("legacy: %q", got)
	}
	if got := normalizeMailFrom("ZozuGames <noreply@zozugames.com>", true); got != "ZozuGames <noreply@zozugames.com>" {
		t.Fatalf("keep: %q", got)
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
	body := "Ваш код подтверждения: 123456\n\nКод действует 15 минут.\n\n@localhost #123456\n"
	if got := extractVerificationCode(body); got != "123456" {
		t.Fatalf("got %q", got)
	}
}

func TestOTPDomain(t *testing.T) {
	m := New(Config{AppOrigin: "https://zozu.games"})
	if got := m.otpDomain(); got != "zozu.games" {
		t.Fatalf("got %q", got)
	}
	m = New(Config{AppOrigin: "http://localhost:3000/"})
	if got := m.otpDomain(); got != "localhost" {
		t.Fatalf("got %q", got)
	}
}

func TestIsResendTestingRestriction(t *testing.T) {
	msg := `{"message":"You can only send testing emails to your own email address. To send emails to other recipients, please verify a domain"}`
	if !isResendTestingRestriction(msg) {
		t.Fatal("expected testing restriction detection")
	}
	if isResendTestingRestriction("status 500: boom") {
		t.Fatal("unexpected match")
	}
}

func TestSendVerificationCode_BodyContainsOTPBinding(t *testing.T) {
	m := New(Config{AppOrigin: "https://app.zozu.games"})
	textBody, htmlBody := m.otpEmailContent(
		"Ваш код подтверждения:",
		"Если вы не регистрировались — просто проигнорируйте письмо.",
		"654321",
	)
	if extractVerificationCode(textBody) != "654321" {
		t.Fatalf("code extract failed: %q", textBody)
	}
	if !strings.Contains(textBody, "@app.zozu.games #654321") {
		t.Fatal("missing OTP autofill binding line")
	}
	if strings.Contains(htmlBody, "<a ") || strings.Contains(htmlBody, "href=") {
		t.Fatal("OTP email must not contain links")
	}
	if !strings.Contains(htmlBody, "user-select:all") {
		t.Fatal("code should be easily selectable")
	}
	if !strings.Contains(htmlBody, "text-decoration:underline") {
		t.Fatal("code should be underlined")
	}
}
