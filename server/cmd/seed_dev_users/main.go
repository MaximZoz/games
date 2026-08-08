// Генератор SQL для DEV: админ + тестовые player1..player20.
// Запуск: go run ./cmd/seed_dev_users
// Не для продакшена.
package main

import (
	"fmt"
	"os"
	"strings"

	"multigames/server/internal/auth"
)

func main() {
	adminEmail := "max591018@gmail.com"
	if v := strings.TrimSpace(os.Getenv("SEED_ADMIN_EMAIL")); v != "" {
		adminEmail = strings.ToLower(v)
	}

	var b strings.Builder
	b.WriteString("-- DEV seed: admin + player1..player20\n")
	b.WriteString("BEGIN;\n\n")

	// Сделать админом, если пользователь уже есть (обычно после Google login).
	fmt.Fprintf(&b, `-- promote admin
UPDATE users
SET is_admin = true, updated_at = now()
WHERE lower(email) = lower('%s');

`, escapeSQL(adminEmail))

	fmt.Fprintf(&b, `-- create admin stub if missing (password = admin-dev-temp, лучше войти через Google)
`)
	adminHash, err := auth.HashPassword("admin-dev-temp")
	if err != nil {
		fatal(err)
	}
	fmt.Fprintf(&b, `
INSERT INTO users (email, password_hash, display_name, is_admin, balance_bronze, email_verified_at)
SELECT '%s', '%s', 'MaxAdmin', true, 50, now()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE lower(email) = lower('%s')
);

`, escapeSQL(adminEmail), escapeSQL(adminHash), escapeSQL(adminEmail))

	b.WriteString("-- test players player1..player20\n")
	for i := 1; i <= 20; i++ {
		name := fmt.Sprintf("player%d", i)
		email := fmt.Sprintf("player%d@player.com", i)
		password := name
		hash, err := auth.HashPassword(password)
		if err != nil {
			fatal(err)
		}
		fmt.Fprintf(&b, `
INSERT INTO users (email, password_hash, display_name, is_admin, balance_bronze, email_verified_at)
VALUES ('%s', '%s', '%s', false, 50, now())
ON CONFLICT (email) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  display_name = EXCLUDED.display_name,
  email_verified_at = COALESCE(users.email_verified_at, now()),
  updated_at = now();
`, escapeSQL(email), escapeSQL(hash), escapeSQL(name))
	}

	b.WriteString(`
COMMIT;

SELECT email, display_name, is_admin
FROM users
WHERE lower(email) = lower('` + escapeSQL(adminEmail) + `')
   OR email ~ '^player([1-9]|1[0-9]|20)@player\.com$'
ORDER BY email;
`)

	fmt.Print(b.String())
}

func escapeSQL(s string) string {
	return strings.ReplaceAll(s, "'", "''")
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "seed_dev_users: %v\n", err)
	os.Exit(1)
}
