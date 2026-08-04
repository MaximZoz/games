# Деплой MultiGames на Fly.io

Краткое руководство: один сервис (Go API + Flutter Web), Postgres и секреты.

---

## Требования

- [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/) установлен
- Выполнен вход: `fly auth login`
- В корне проекта есть `fly.toml` и `Dockerfile`

---

## Быстрый режим: конфиг для Cursor

Если деплоишь из Cursor/CLI регулярно, вынеси токены и секреты в локальный файл:

```bash
cp deploy.cursor.env.example deploy.cursor.env
```

Заполни `deploy.cursor.env` значениями:
- `FLY_API_TOKEN` (создать: `fly tokens create deploy -a <APP_NAME> -x 24h -n "cursor-deploy"`)
- `FLY_APP_NAME`
- `JWT_SECRET`
- `ADMIN_INIT_SECRET`
- опционально для логирования: `APP_LOG_ENABLED`, `APP_LOG_RETENTION_DAYS`, `APP_LOG_CLEANUP_INTERVAL_SECONDS`

Файл `deploy.cursor.env` не коммитится (он в `.gitignore`).

**Запуск в 1 команду:**

```bash
./launcher/deploy_cursor.sh
```

```powershell
.\launcher\deploy_cursor.ps1
```

**Отдельно: деплой именно ветки `develop` (удобно как “одна кнопка” в чате Cursor):**

```bash
./launcher/deploy_develop.sh
```

```powershell
.\launcher\deploy_develop.ps1
```

**Отдельное DEV-окружение на Fly** (копия прод-стека, другая БД/секреты):

```bash
cp deploy.dev.env.example deploy.dev.env
# заполни FLY_API_TOKEN, JWT_SECRET, ADMIN_INIT_SECRET
./launcher/setup_fly_dev.sh
./launcher/deploy_dev.sh
```

```powershell
Copy-Item deploy.dev.env.example deploy.dev.env
# заполни FLY_API_TOKEN, JWT_SECRET, ADMIN_INIT_SECRET
.\launcher\setup_fly_dev.ps1
.\launcher\deploy_dev.ps1
```

Подробно: [docs/DEPLOY_FLY_DEV.md](docs/DEPLOY_FLY_DEV.md).  
Прод: `multigameszozu` (`fly.toml`). DEV: `multigameszozu-dev` (`fly.dev.toml`).

**Прямо в чате Cursor (slash-команда проекта):**

```
/deploy-develop
```

Команда лежит в `.cursor/commands/deploy-develop.md` и запускает тот же сценарий деплоя ветки `origin/develop`.

**Linux/macOS/Cursor shell:**

```bash
set -a
source deploy.cursor.env
set +a
fly secrets set JWT_SECRET="$JWT_SECRET" ADMIN_INIT_SECRET="$ADMIN_INIT_SECRET" --app "$FLY_APP_NAME"
fly deploy --app "$FLY_APP_NAME" --remote-only --yes
```

**PowerShell:**

```powershell
Get-Content .\deploy.cursor.env | ForEach-Object {
  if ($_ -and -not $_.StartsWith("#")) {
    $name, $value = $_ -split "=", 2
    Set-Item -Path "Env:$name" -Value $value
  }
}
fly secrets set JWT_SECRET="$env:JWT_SECRET" ADMIN_INIT_SECRET="$env:ADMIN_INIT_SECRET" --app "$env:FLY_APP_NAME"
fly deploy --app "$env:FLY_APP_NAME" --remote-only --yes
```

---

## Шаг 1. Создать приложение (если ещё нет)

Из **корня репозитория**:

```bash
fly launch --no-deploy
```

Укажи имя приложения (например `multigames`) и регион (например `arn` — Стокгольм, `ams` — Амстердам). Postgres и Redis на этом шаге не добавляй.

---

## Шаг 2. Postgres

```bash
fly postgres create --name multigames-db --region arn
```

Регион (`arn`) замени на тот, что выбрал для приложения. После создания:

```bash
fly postgres attach multigames-db --app <имя-твоего-приложения>
```

На вопрос «Set DATABASE_URL?» ответь **y**. Секрет `DATABASE_URL` установится автоматически.

---

## Шаг 3. Секреты

**Обязательно:**

```bash
fly secrets set JWT_SECRET="придумай-длинную-случайную-строку-32-символа" --app <имя-приложения>
```

**Для создания первого админа** (один раз):

```bash
fly secrets set ADMIN_INIT_SECRET="твой-секрет-для-админа" --app <имя-приложения>
```

**Redis** не обязателен: если `REDIS_URL` не задан, приложение запустится без Redis. Позже можно добавить Upstash и задать `REDIS_URL`.

**Отключение логирования в `app_logs`** (для production):

```bash
fly secrets set APP_LOG_ENABLED=false --app <имя-приложения>
```

---

## Шаг 4. Деплой

Из корня репозитория:

```bash
fly deploy --app <имя-приложения>
```

Сборка (Flutter Web + Go) займёт несколько минут. В конце будет ссылка вида `https://<имя-приложения>.fly.dev`.

---

## Шаг 5. Первый админ

Если задал `ADMIN_INIT_SECRET`, создай первого админа одним запросом.

**PowerShell** (каждую команду вводи с Enter отдельно):

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-Admin-Init-Secret" = "твой-секрет-для-админа"
}
```

```powershell
$body = '{"email":"admin@example.com","password":"надёжный-пароль-6-символов"}'
```

```powershell
Invoke-RestMethod -Uri "https://<имя-приложения>.fly.dev/api/admin/init" -Method POST -Headers $headers -Body $body
```

Подставь своё имя приложения и тот же секрет, что в `ADMIN_INIT_SECRET`. После успешного ответа войди на сайт под этим email и паролем — в тулбаре появится иконка щита (админка).

**Bash / curl:**

```bash
curl -X POST "https://<имя-приложения>.fly.dev/api/admin/init" \
  -H "Content-Type: application/json" \
  -H "X-Admin-Init-Secret: твой-секрет-для-админа" \
  -d '{"email":"admin@example.com","password":"надёжный-пароль"}'
```

---

## Полезные команды

| Команда | Описание |
|--------|----------|
| `fly status --app <имя>` | Статус машин |
| `fly logs --app <имя>` | Логи приложения |
| `fly secrets list --app <имя>` | Список секретов |
| `fly scale count 1 --app <имя>` | Держать одну машину всегда включённой (без холодного старта) |

---

## Если что-то не так

- **Сайт не открывается** — см. [docs/DEPLOY_FLY_TROUBLESHOOTING.md](docs/DEPLOY_FLY_TROUBLESHOOTING.md) (статус, логи, доступ из РФ, редиректы).
- **Полная пошаговая инструкция** — [docs/DEPLOY_FLY.md](docs/DEPLOY_FLY.md).
- **Отдельный DEV на Fly** — [docs/DEPLOY_FLY_DEV.md](docs/DEPLOY_FLY_DEV.md).
- **Автодеплой веток** — `develop` → DEV, `main` → прод (`.github/workflows/deploy.yml`, secret `FLY_API_TOKEN`).
