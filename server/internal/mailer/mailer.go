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
	From         string // "ZozuGames <noreply@zozugames.com>" или onboarding@resend.dev
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
	cfg.From = normalizeMailFrom(cfg.From, strings.TrimSpace(cfg.ResendAPIKey) != "")
	return &Mailer{
		cfg: cfg,
		httpClient: &http.Client{
			Timeout: 20 * time.Second,
		},
	}
}

// normalizeMailFrom — отображаемое имя ZozuGames; старый префикс MultiGames подменяется.
func normalizeMailFrom(from string, resend bool) string {
	from = strings.TrimSpace(from)
	if from == "" {
		if resend {
			return "ZozuGames <onboarding@resend.dev>"
		}
		return "ZozuGames <noreply@zozugames.com>"
	}
	if strings.HasPrefix(from, "MultiGames <") {
		return "ZozuGames <" + strings.TrimPrefix(from, "MultiGames <")
	}
	if strings.HasPrefix(from, "MultiGames ") {
		return "ZozuGames " + strings.TrimPrefix(from, "MultiGames ")
	}
	return from
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
	return m.Send(to, subject, body, "")
}

// Send отправляет письмо (text + опциональный html).
func (m *Mailer) Send(to, subject, textBody, htmlBody string) error {
	to = strings.TrimSpace(to)
	if to == "" {
		return fmt.Errorf("empty recipient")
	}
	if !m.Enabled() {
		log.Printf("[mailer] no provider — to=%s subject=%q body=%q", to, subject, textBody)
		if code := extractVerificationCode(textBody); code != "" {
			log.Printf("[auth] verification code for %s: %s", to, code)
		}
		return nil
	}

	if m.resendEnabled() {
		if err := m.sendResend(to, subject, textBody, htmlBody); err != nil {
			return fmt.Errorf("resend: %w", err)
		}
		return nil
	}
	return m.sendSMTP(to, subject, textBody, htmlBody)
}

func (m *Mailer) sendResend(to, subject, textBody, htmlBody string) error {
	payload := map[string]any{
		"from":    m.cfg.From,
		"to":      []string{to},
		"subject": subject,
		"text":    textBody,
	}
	if strings.TrimSpace(htmlBody) != "" {
		payload["html"] = htmlBody
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

func (m *Mailer) sendSMTP(to, subject, textBody, htmlBody string) error {
	from := strings.TrimSpace(m.cfg.From)
	// Для SMTP Envelope лучше голый email.
	fromAddr := from
	if i := strings.Index(from, "<"); i >= 0 {
		if j := strings.Index(from[i:], ">"); j > 0 {
			fromAddr = strings.TrimSpace(from[i+1 : i+j])
		}
	}

	var msg string
	if strings.TrimSpace(htmlBody) == "" {
		msg = strings.Join([]string{
			"From: " + from,
			"To: " + to,
			"Subject: " + encodeSubject(subject),
			"MIME-Version: 1.0",
			"Content-Type: text/plain; charset=UTF-8",
			"Content-Transfer-Encoding: 8bit",
			"",
			textBody,
		}, "\r\n")
	} else {
		boundary := fmt.Sprintf("mg_alt_%d", time.Now().UnixNano())
		msg = strings.Join([]string{
			"From: " + from,
			"To: " + to,
			"Subject: " + encodeSubject(subject),
			"MIME-Version: 1.0",
			"Content-Type: multipart/alternative; boundary=" + boundary,
			"",
			"--" + boundary,
			"Content-Type: text/plain; charset=UTF-8",
			"Content-Transfer-Encoding: 8bit",
			"",
			textBody,
			"",
			"--" + boundary,
			"Content-Type: text/html; charset=UTF-8",
			"Content-Transfer-Encoding: 8bit",
			"",
			htmlBody,
			"",
			"--" + boundary + "--",
			"",
		}, "\r\n")
	}

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
	for _, prefix := range []string{
		"Ваш код подтверждения: ",
		"Ваш код для сброса пароля: ",
	} {
		i := strings.Index(body, prefix)
		if i < 0 {
			continue
		}
		rest := body[i+len(prefix):]
		return strings.TrimSpace(strings.Split(rest, "\n")[0])
	}
	return ""
}

func (m *Mailer) otpDomain() string {
	u, err := url.Parse(m.appBaseURL())
	if err != nil || u.Hostname() == "" {
		return "localhost"
	}
	return u.Hostname()
}

func (m *Mailer) appBaseURL() string {
	raw := strings.TrimSpace(m.cfg.AppOrigin)
	if raw == "" {
		return ""
	}
	if !strings.Contains(raw, "://") {
		raw = "https://" + raw
	}
	u, err := url.Parse(raw)
	if err != nil || u.Scheme == "" || u.Host == "" {
		return ""
	}
	return strings.TrimRight(u.Scheme+"://"+u.Host, "/")
}

func escapeHTML(s string) string {
	replacer := strings.NewReplacer(
		"&", "&amp;",
		"<", "&lt;",
		">", "&gt;",
		`"`, "&quot;",
		"'", "&#39;",
	)
	return replacer.Replace(s)
}

// otpEmailContent — text + HTML.
// В почте нельзя выполнить JS «скопировать по клику» без перехода на сайт,
// поэтому код — крупный выделяемый блок (user-select:all), без ссылок.
// Строка "@host #CODE" нужна для автоподстановки OTP в форме приложения.
func (m *Mailer) otpEmailContent(titleLine, ignoreLine, code string) (textBody, htmlBody string) {
	domain := m.otpDomain()
	code = strings.TrimSpace(code)

	textBody = fmt.Sprintf(
		"%s %s\n\nКод действует 15 минут.\n%s\n\n@%s #%s\n",
		titleLine, code, ignoreLine, domain, code,
	)

	codeHTML := escapeHTML(code)
	// Без <a>: только span. user-select:all — тройной клик / долгий тап выделяет весь код.
	codeBlock := fmt.Sprintf(
		`<span style="display:inline-block;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:32px;font-weight:700;letter-spacing:0.22em;color:#4F46E5;text-decoration:underline;text-underline-offset:6px;border:2px dashed #A5B4FC;border-radius:12px;padding:14px 22px;background:#EEF2FF;-webkit-user-select:all;user-select:all;">%s</span>`,
		codeHTML,
	)

	htmlBody = fmt.Sprintf(`<!DOCTYPE html>
<html lang="ru"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:24px;background:#E8ECF4;font-family:system-ui,-apple-system,Segoe UI,sans-serif;color:#1a1a2e;">
  <div style="max-width:420px;margin:0 auto;background:#fff;border-radius:16px;padding:28px 24px;border:1px solid #c7d2fe;">
    <p style="margin:0 0 8px;font-size:16px;font-weight:600;">%s</p>
    <p style="margin:20px 0 8px;text-align:center;">%s</p>
    <p style="margin:0 0 20px;text-align:center;font-size:13px;color:#64748b;">Удерживайте код → «Скопировать»</p>
    <p style="margin:0 0 8px;font-size:14px;color:#5a6275;line-height:1.45;">Код действует 15 минут.</p>
    <p style="margin:0;font-size:14px;color:#5a6275;line-height:1.45;">%s</p>
    <p style="margin:20px 0 0;font-size:12px;color:#94a3b8;">@%s #%s</p>
  </div>
</body></html>`,
		escapeHTML(titleLine),
		codeBlock,
		escapeHTML(ignoreLine),
		escapeHTML(domain),
		codeHTML,
	)
	return textBody, htmlBody
}

// SendVerificationCode отправляет 6-значный код на указанный адрес (to = email регистрации).
// В конце тела — строка "@host #CODE" для автозаполнения OTP из почты.
func (m *Mailer) SendVerificationCode(to, code string) error {
	subject := "Код подтверждения ZozuGames"
	textBody, htmlBody := m.otpEmailContent(
		"Ваш код подтверждения:",
		"Если вы не регистрировались — просто проигнорируйте письмо.",
		code,
	)
	return m.Send(to, subject, textBody, htmlBody)
}

// SendPasswordResetCode отправляет код для сброса пароля.
func (m *Mailer) SendPasswordResetCode(to, code string) error {
	subject := "Сброс пароля ZozuGames"
	textBody, htmlBody := m.otpEmailContent(
		"Ваш код для сброса пароля:",
		"Если вы не запрашивали сброс — просто проигнорируйте письмо.",
		code,
	)
	return m.Send(to, subject, textBody, htmlBody)
}
