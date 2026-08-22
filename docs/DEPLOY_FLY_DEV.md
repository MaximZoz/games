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
- `FLY_API_TOKEN` — **в кавычках**, одной строкой  
  (`FLY_API_TOKEN="FlyV1 fm2_....="` — иначе bash ломается на пробеле)
- `JWT_SECRET` / `ADMIN_INIT_SECRET` — **новые**, не копируй с прода (тоже лучше в кавычках)
- при необходимости почту (`RESEND_API_KEY`, `MAIL_FROM`)

`REDIS_URL` вручную заполнять не обязательно — после создания app прогони
`./launcher/setup_fly_redis.sh deploy.dev.env` (см. ниже). Без внешнего Redis
после каждого деплоя DEV сбрасываются лобби/матчмейкинг.

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

### 2.1. Внешний Redis (чтобы лобби переживали деплой)

```bash
chmod +x launcher/setup_fly_redis.sh
./launcher/setup_fly_redis.sh deploy.dev.env
```

```powershell
.\launcher\setup_fly_redis.ps1 deploy.dev.env
```

Создаст Upstash Redis `multigameszozu-dev-redis` и пропишет `REDIS_URL` в секреты DEV.

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

## Тестовые пользователи на DEV

```bash
./launcher/seed_dev_users.sh
```

Скрипт:
- делает `max591018@gmail.com` админом (если нет — создаёт)
- создаёт `player1` … `player20`  
  email `playerN@player.com`, пароль `playerN`

Только для `multigameszozu-dev-db`, прод не трогает.

## Полезные команды

```bash
fly status --app multigameszozu-dev
fly logs --app multigameszozu-dev
fly secrets list --app multigameszozu-dev
fly apps restart multigameszozu-dev
```

## Автодеплой из GitHub Actions

Workflow `.github/workflows/deploy.yml`:

| Ветка | Fly app | Конфиг |
|---|---|---|
| `develop` | `multigameszozu-dev` | `fly.dev.toml` |
| `main` | `multigameszozu` | `fly.toml` |

Нужен один GitHub secret:

```text
Settings → Secrets and variables → Actions → FLY_API_TOKEN
```

Токен:

```bash
fly tokens create org -x 2160h -n github-actions
# или deploy-токен с доступом к обоим app
```

После настройки:
- любой push/merge в `develop` → деплой на https://multigameszozu-dev.fly.dev
- любой push/merge в `main` → деплой на https://multigameszozu.fly.dev
- workflow `CI` (analyze/test) на push/PR не запускается; только ручной Run workflow

Ручной запуск: Actions → **Deploy Fly** → Run workflow → выбрать `dev` или `prod`.

Локально по-прежнему можно:

```bash
./launcher/deploy_dev.sh             # → DEV
./launcher/deploy_cursor.sh          # → прод (текущая ветка)
```
