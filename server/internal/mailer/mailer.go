package mailer

import (
	"fmt"
	"log"
	"net/smtp"
	"strings"
)

// Config — SMTP. Если Host пустой, письма только логируются (dev).
type Config struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
}

type Mailer struct {
	cfg Config
}

func New(cfg Config) *Mailer {
	if cfg.Port == "" {
		cfg.Port = "587"
	}
	if cfg.From == "" {
		cfg.From = "noreply@zozu.games"
	}
	return &Mailer{cfg: cfg}
}

func (m *Mailer) Enabled() bool {
	return strings.TrimSpace(m.cfg.Host) != ""
}

// SendPlain отправляет текстовое письмо. Без SMTP пишет в лог и не падает.
func (m *Mailer) SendPlain(to, subject, body string) error {
	to = strings.TrimSpace(to)
	if to == "" {
		return fmt.Errorf("empty recipient")
	}
	if !m.Enabled() {
		log.Printf("[mailer] SMTP not configured — to=%s subject=%q body=%q", to, subject, body)
		// Дублируем код отдельной строкой для удобства локальной отладки.
		if i := strings.Index(body, "Ваш код подтверждения: "); i >= 0 {
			rest := body[i+len("Ваш код подтверждения: "):]
			code := strings.TrimSpace(strings.Split(rest, "\n")[0])
			if code != "" {
				log.Printf("[auth] verification code for %s: %s", to, code)
			}
		}
		return nil
	}

	addr := m.cfg.Host + ":" + m.cfg.Port
	msg := strings.Join([]string{
		"From: " + m.cfg.From,
		"To: " + to,
		"Subject: " + subject,
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"",
		body,
	}, "\r\n")

	var auth smtp.Auth
	if m.cfg.Username != "" {
		auth = smtp.PlainAuth("", m.cfg.Username, m.cfg.Password, m.cfg.Host)
	}
	return smtp.SendMail(addr, auth, m.cfg.From, []string{to}, []byte(msg))
}

// SendVerificationCode отправляет 6-значный код подтверждения.
func (m *Mailer) SendVerificationCode(to, code string) error {
	subject := "Код подтверждения MultiGames"
	body := fmt.Sprintf(
		"Ваш код подтверждения: %s\n\nКод действует 15 минут.\nЕсли вы не регистрировались — просто проигнорируйте письмо.\n",
		code,
	)
	return m.SendPlain(to, subject, body)
}
