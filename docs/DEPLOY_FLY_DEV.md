# Fly DEV-окружение (копия прод-стека)

Прод остаётся как есть:

| | Прод | DEV |
|---|---|---|
| App | `multigameszozu` | `multigameszozu-dev` |
| Конфиг | `fly.toml` | `fly.dev.toml` |
| Postgres | прод-БД | `multigameszozu-dev-db` |
| URL | `https://multigameszozu.fly.dev` | `https://multigameszozu-dev.fly.dev` |
| Секреты | `deploy.cursor.env` | `deploy.dev.env` |

DEV — **отдельное** приложение и **отдельная** БД. Прод не затрагивается.

---

## 1. Создать локальный конфиг

```bash
cp deploy.dev.env.example deploy.dev.env
```

Заполни:
- `FLY_API_TOKEN`
- `JWT_SECRET` / `ADMIN_INIT_SECRET` — **новые**, не копируй с прода
- при необходимости `REDIS_URL`, почту (`RESEND_API_KEY`, `MAIL_FROM`)

Токен:

```bash
fly tokens create deploy -a multigameszozu-dev -x 72h -n "cursor-dev-deploy"
```

Если приложения ещё нет — можно взять org-токен / токен от прода и сначала прогнать setup.

---

## 2. Создать ресурсы на Fly

```bash
chmod +x launcher/setup_fly_dev.sh launcher/deploy_dev.sh
./launcher/setup_fly_dev.sh
```

PowerShell:

```powershell
.\launcher\setup_fly_dev.ps1
```

Скрипт:
1. создаёт app `multigameszozu-dev`
2. создаёт Postgres `multigameszozu-dev-db`
3. делает `postgres attach` → секрет `DATABASE_URL`
4. ставит `JWT_SECRET`, `ADMIN_INIT_SECRET`, `PUBLIC_BASE_URL`, …

---

## 3. Задеплоить код

```bash
./launcher/deploy_dev.sh
```

```powershell
.\launcher\deploy_dev.ps1
```

Проверка:

```bash
curl -sS https://multigameszozu-dev.fly.dev/api/start
```

Ожидается: `go start`.

Открыть: https://multigameszozu-dev.fly.dev/

---

## 4. Первый админ на DEV

```bash
curl -X POST "https://multigameszozu-dev.fly.dev/api/admin/init" \
  -H "Content-Type: application/json" \
  -H "X-Admin-Init-Secret: <ADMIN_INIT_SECRET из deploy.dev.env>" \
  -d '{"email":"admin@example.com","password":"secret12"}'
```

---

## Что копируется, а что нет

**Копируется по форме (стек):**
- тот же `Dockerfile`
- тот же код приложения
- тот же тип сервиса (Go + Flutter Web)
- отдельный Postgres + секреты

**Не копируется автоматически:**
- данные пользователей/чатов из прод-БД
- Redis/Upstash прода
- домен `zozugames.com` / прод-OAuth callback’и

По умолчанию DEV стартует с **пустой** БД; миграции накатываются при старте сервера.

---

## Опционально: склонировать данные из прода

Только если реально нужны прод-данные на DEV. Делай осознанно.

1. Снять dump с прод-Postgres (через `fly postgres connect` / `pg_dump`).
2. Восстановить в `multigameszozu-dev-db`.
3. Не затирать секреты DEV (`JWT_SECRET` и т.д.).

Рекомендация для повседневной разработки: **пустая DEV-БД** + тестовые аккаунты.

---

## Полезные команды

```bash
fly status --app multigameszozu-dev
fly logs --app multigameszozu-dev
fly secrets list --app multigameszozu-dev
fly apps restart multigameszozu-dev
```

Прод при этом деплоится как раньше:

```bash
./launcher/deploy_cursor.sh          # текущая ветка → multigameszozu
./launcher/deploy_develop.sh         # origin/develop → multigameszozu
```
