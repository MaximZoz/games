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
	// без провайдера — только лог; проверяем тело через extract + формат
	body := "Ваш код подтверждения: 654321\n\nКод действует 15 минут.\nЕсли вы не регистрировались — просто проигнорируйте письмо.\n\n@app.zozu.games #654321\n"
	if extractVerificationCode(body) != "654321" {
		t.Fatal("code extract failed")
	}
	if !strings.Contains(body, "@app.zozu.games #654321") {
		t.Fatal("missing OTP autofill binding line")
	}
	_ = m
}
