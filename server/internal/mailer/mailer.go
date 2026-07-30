package mailer

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/smtp"
	"net/url"
	"strings"
	"time"
)

// Config — Resend (предпочтительно) или SMTP. Без обоих письма только логируются.
type Config struct {
	ResendAPIKey string
	From         string // "MultiGames <noreply@zozu.games>" или onboarding@resend.dev
	// AppOrigin — URL фронта (FRONTEND_URL). Хост используется в строке
	// "@host #CODE" для автоподстановки OTP из письма (iOS/Safari и др.).
	AppOrigin string

	Host     string
	Port     string
	Username string
	Password string
}

type Mailer struct {
	cfg        Config
	httpClient *http.Client
}

func New(cfg Config) *Mailer {
	if cfg.Port == "" {
		cfg.Port = "587"
	}
	if cfg.From == "" {
		if strings.TrimSpace(cfg.ResendAPIKey) != "" {
			cfg.From = "MultiGames <onboarding@resend.dev>"
		} else {
			cfg.From = "MultiGames <noreply@zozu.games>"
		}
	}
	return &Mailer{
		cfg: cfg,
		httpClient: &http.Client{
			Timeout: 20 * time.Second,
		},
	}
}

func (m *Mailer) Enabled() bool {
	return m.resendEnabled() || m.smtpEnabled()
}

func (m *Mailer) Provider() string {
	if m.resendEnabled() {
		return "resend"
	}
	if m.smtpEnabled() {
		return "smtp"
	}
	return "log"
}

func (m *Mailer) resendEnabled() bool {
	return strings.TrimSpace(m.cfg.ResendAPIKey) != ""
}

func (m *Mailer) smtpEnabled() bool {
	return strings.TrimSpace(m.cfg.Host) != ""
}

// SendPlain отправляет текстовое письмо.
// Без Resend/SMTP пишет в лог и не падает (dev).
func (m *Mailer) SendPlain(to, subject, body string) error {
	to = strings.TrimSpace(to)
	if to == "" {
		return fmt.Errorf("empty recipient")
	}
	if !m.Enabled() {
		log.Printf("[mailer] no provider — to=%s subject=%q body=%q", to, subject, body)
		if code := extractVerificationCode(body); code != "" {
			log.Printf("[auth] verification code for %s: %s", to, code)
		}
		return nil
	}

	if m.resendEnabled() {
		if err := m.sendResend(to, subject, body); err != nil {
			return fmt.Errorf("resend: %w", err)
		}
		return nil
	}
	return m.sendSMTP(to, subject, body)
}

func (m *Mailer) sendResend(to, subject, body string) error {
	payload := map[string]any{
		"from":    m.cfg.From,
		"to":      []string{to},
		"subject": subject,
		"text":    body,
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	req, err := http.NewRequest(http.MethodPost, "https://api.resend.com/emails", bytes.NewReader(raw))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+strings.TrimSpace(m.cfg.ResendAPIKey))
	req.Header.Set("Content-Type", "application/json")

	resp, err := m.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		msg := strings.TrimSpace(string(respBody))
		if isResendTestingRestriction(msg) {
			return fmt.Errorf(
				"resend testing mode: can only deliver to the Resend account email until a domain is verified (status %d: %s)",
				resp.StatusCode, msg,
			)
		}
		return fmt.Errorf("status %d: %s", resp.StatusCode, msg)
	}
	log.Printf("[mailer] resend ok to=%s", to)
	return nil
}

func isResendTestingRestriction(msg string) bool {
	lower := strings.ToLower(msg)
	return strings.Contains(lower, "testing emails") ||
		strings.Contains(lower, "verify a domain") ||
		strings.Contains(lower, "only send testing")
}

func (m *Mailer) sendSMTP(to, subject, body string) error {
	from := strings.TrimSpace(m.cfg.From)
	// Для SMTP Envelope лучше голый email.
	fromAddr := from
	if i := strings.Index(from, "<"); i >= 0 {
		if j := strings.Index(from[i:], ">"); j > 0 {
			fromAddr = strings.TrimSpace(from[i+1 : i+j])
		}
	}

	msg := strings.Join([]string{
		"From: " + from,
		"To: " + to,
		"Subject: " + encodeSubject(subject),
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"Content-Transfer-Encoding: 8bit",
		"",
		body,
	}, "\r\n")

	addr := net.JoinHostPort(m.cfg.Host, m.cfg.Port)
	var auth smtp.Auth
	if m.cfg.Username != "" {
		auth = smtp.PlainAuth("", m.cfg.Username, m.cfg.Password, m.cfg.Host)
	}

	if m.cfg.Port == "465" {
		return sendMailTLS(addr, m.cfg.Host, auth, fromAddr, []string{to}, []byte(msg))
	}
	return smtp.SendMail(addr, auth, fromAddr, []string{to}, []byte(msg))
}

func sendMailTLS(addr, host string, auth smtp.Auth, from string, to []string, msg []byte) error {
	tlsCfg := &tls.Config{ServerName: host, MinVersion: tls.VersionTLS12}
	conn, err := tls.DialWithDialer(&net.Dialer{Timeout: 15 * time.Second}, "tcp", addr, tlsCfg)
	if err != nil {
		return err
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return err
	}
	defer client.Close()

	if auth != nil {
		if ok, _ := client.Extension("AUTH"); ok {
			if err := client.Auth(auth); err != nil {
				return err
			}
		}
	}
	if err := client.Mail(from); err != nil {
		return err
	}
	for _, rcpt := range to {
		if err := client.Rcpt(rcpt); err != nil {
			return err
		}
	}
	w, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := w.Write(msg); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	return client.Quit()
}

func encodeSubject(s string) string {
	needs := false
	for _, r := range s {
		if r > 127 {
			needs = true
			break
		}
	}
	if !needs {
		return s
	}
	const table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	raw := []byte(s)
	encoded := make([]byte, 0, len(raw)*2)
	for i := 0; i < len(raw); i += 3 {
		var n uint32
		remain := len(raw) - i
		switch {
		case remain >= 3:
			n = uint32(raw[i])<<16 | uint32(raw[i+1])<<8 | uint32(raw[i+2])
			encoded = append(encoded, table[n>>18&63], table[n>>12&63], table[n>>6&63], table[n&63])
		case remain == 2:
			n = uint32(raw[i])<<16 | uint32(raw[i+1])<<8
			encoded = append(encoded, table[n>>18&63], table[n>>12&63], table[n>>6&63], '=')
		default:
			n = uint32(raw[i]) << 16
			encoded = append(encoded, table[n>>18&63], table[n>>12&63], '=', '=')
		}
	}
	return "=?UTF-8?B?" + string(encoded) + "?="
}

func extractVerificationCode(body string) string {
	const prefix = "Ваш код подтверждения: "
	i := strings.Index(body, prefix)
	if i < 0 {
		return ""
	}
	rest := body[i+len(prefix):]
	return strings.TrimSpace(strings.Split(rest, "\n")[0])
}

func (m *Mailer) otpDomain() string {
	raw := strings.TrimSpace(m.cfg.AppOrigin)
	if raw == "" {
		return "localhost"
	}
	if !strings.Contains(raw, "://") {
		raw = "https://" + raw
	}
	u, err := url.Parse(raw)
	if err != nil || u.Hostname() == "" {
		return "localhost"
	}
	return u.Hostname()
}

// SendVerificationCode отправляет 6-значный код на указанный адрес (to = email регистрации).
// В конце тела — строка "@host #CODE" для автозаполнения OTP из почты.
func (m *Mailer) SendVerificationCode(to, code string) error {
	subject := "Код подтверждения MultiGames"
	domain := m.otpDomain()
	body := fmt.Sprintf(
		"Ваш код подтверждения: %s\n\nКод действует 15 минут.\nЕсли вы не регистрировались — просто проигнорируйте письмо.\n\n@%s #%s\n",
		code, domain, code,
	)
	return m.SendPlain(to, subject, body)
}
