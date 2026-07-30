# Деплой MultiGames на Fly.io

Один сервис: Go-API + статика Flutter Web. Postgres и Redis — отдельные ресурсы Fly.

## Требования

- [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/) установлен и выполнен `fly auth login`
- Аккаунт Fly.io

## 1. Создать приложение (если ещё не создано)

Из **корня репозитория**:

```bash
fly launch --no-deploy
```

- Имя приложения можно оставить или задать (например `multigames-yourname`).
- Регион — по желанию (например `ams`).
- Postgres и Redis на этом шаге **не** создаём — создадим отдельно.

Если `fly.toml` уже есть (как в этом репо), `fly launch` подхватит его.

## 2. Postgres (Fly Postgres)

```bash
fly postgres create --name multigames-db --region ams
```

- Запомни имя приложения БД (например `multigames-db`) и регион.
- После создания привяжи БД к приложению:

```bash
fly postgres attach multigames-db --app multigames
```

Команда выведет что-то вроде: `Set DATABASE_URL on multigames? (y/N)` — ответь `y`. Секрет `DATABASE_URL` будет установлен автоматически.

(Если приложение называется иначе — укажи его: `--app <твоё-имя-приложения>`.)

## 3. Redis (Upstash на Fly)

Сервер ожидает переменную `REDIS_URL`. Варианты:

**Вариант A — Upstash Redis (рекомендуется)**

1. В [Fly Dashboard](https://fly.io/dashboard) открой своё приложение.
2. **Resources** → **Upstash** → создать Redis (или перейди в [Upstash](https://upstash.com) и создай БД).
3. Скопируй URL подключения (например `rediss://default:xxx@xxx.upstash.io:6379`) и задай секрет:

```bash
fly secrets set REDIS_URL="rediss://default:PASSWORD@HOST:6379" --app multigames
```

**Вариант B — Redis в отдельном Fly-приложении**

Можно поднять Redis-образ как отдельное приложение и использовать внутренний URL (через Flycast), но проще начать с Upstash.

## 4. Остальные секреты

```bash
# Обязательно: длинная случайная строка для JWT
fly secrets set JWT_SECRET="$(openssl rand -base64 32)" --app multigameszozu

# Опционально: секрет для создания первого админа (POST /api/admin/init)
fly secrets set ADMIN_INIT_SECRET="твой-секретный-пароль" --app multigameszozu

# Почта (Resend) — без этих секретов код подтверждения НЕ уходит на email
# (в ответе register будет "mail_sent": false, код только в fly logs)
fly secrets set \
  RESEND_API_KEY="re_xxxxxxxx" \
  MAIL_FROM="MultiGames <noreply@zozugames.com>" \
  PUBLIC_BASE_URL="https://zozugames.com" \
  FRONTEND_URL="https://zozugames.com" \
  --app multigameszozu
```

Имя приложения замени на своё, если использовал другое при `fly launch`. Проверка:  
`curl -s -X POST https://multigameszozu.fly.dev/api/auth/register -H 'Content-Type: application/json' -d '{"email":"you@example.com","password":"secret12"}'`  
должно вернуть `"mail_sent":true`.

## 5. Деплой

Из корня репозитория:

```bash
fly deploy
```

Сборка может занять несколько минут (Flutter Web + Go). По окончании приложение будет доступно по адресу вида `https://multigames.fly.dev` (или твой `app` в `fly.toml`).

## 6. Проверка

- Открой в браузере `https://<твоё-приложение>.fly.dev` — должна открыться главная MultiGames.
- Регистрация, вход, админка работают через тот же домен (API на `/api/*`).

## 7. Первый админ

Если задал `ADMIN_INIT_SECRET`:

**PowerShell:**
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-Admin-Init-Secret" = "твой-секретный-пароль"
}
$body = '{"email":"admin@example.com","password":"надёжный-пароль"}'
Invoke-RestMethod -Uri "https://multigameszozu.fly.dev/api/admin/init" -Method POST -Headers $headers -Body $body
```

**Bash / curl:**
```bash
curl -X POST https://multigameszozu.fly.dev/api/admin/init \
  -H "Content-Type: application/json" \
  -H "X-Admin-Init-Secret: 123456" \
  -d '{"email":"admin@example.com","password":"123456"}'
```

После этого можно войти под этим пользователем и зайти в админку по иконке щита.

## Полезные команды

| Команда | Описание |
|--------|----------|
| `fly logs` | Логи приложения |
| `fly status` | Статус машин |
| `fly secrets list` | Список секретов (значения не показываются) |
| `fly scale count 0` | Остановить все машины (экономия) |
| `fly scale count 1` | Запустить одну машину |

## Переменные окружения (секреты)

| Секрет | Обязательный | Описание |
|--------|--------------|----------|
| `DATABASE_URL` | Да | Выдаётся при `fly postgres attach` |
| `REDIS_URL` | Да | URL Redis (Upstash или свой) |
| `JWT_SECRET` | Да | Секрет для подписи JWT |
| `ADMIN_INIT_SECRET` | Нет | Секрет для однократного создания первого админа |

`PORT` в контейнере задаёт Fly (обычно 8080), в `fly.toml` уже указан `internal_port = 8080`.
