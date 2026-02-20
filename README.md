# 🎮 MultiGames — мультиплатформенные онлайн мини-игры

> Карты, нарды, шашки, шахматы и другие игры с единым рейтингом ELO.  
> **Flutter + Go** | iOS • Android • Web • Desktop • TV

---

## 📋 Описание

Платформа онлайн мини-игр с акцентом на:
- **Мультиплатформенность** — сайт, iOS, Android, планшеты, Apple TV, Android TV, desktop, Steam
- **Единый рейтинг ELO** — общий рейтинг по всем играм с коэффициентами
- **Анимации** — плавные переходы, Rive, Lottie, кастомные анимации

---

## 🏗 Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER (клиент)                              │
│  Web • iOS • Android • Windows • macOS • Linux • tvOS • Android TV│
└───────────────────────────────┬─────────────────────────────────┘
                                │ REST API + WebSocket
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GO (бэкенд)                                 │
│  API • Game Logic • Matchmaking • ELO • WebSocket Hub            │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│               PostgreSQL • Redis                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Структура репозитория

```
myProject/
├── client/                 # Flutter приложение
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   ├── shared/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── server/                 # Go бэкенд
│   ├── cmd/
│   ├── internal/
│   ├── pkg/
│   └── go.mod
│
├── launcher/               # Запуск клиента и сервера одной командой
│   ├── start.ps1           # Windows
│   ├── start.sh            # macOS / Linux
│   └── README.md
│
├── docs/                   # Документация
│   ├── ARCHITECTURE.md
│   ├── API.md              # REST API (авторизация и др.)
│   ├── DATABASE.md         # PostgreSQL и Redis: как смотреть таблицы и ключи
│   └── GITHUB_PLAN.md
│
├── .github/                # GitHub Actions, Issue templates
│   └── workflows/
│
├── .gitignore
└── README.md
```

---

## 🚀 Быстрый старт

### Требования

- **Flutter** 3.24+
- **Go** 1.22+
- **Docker** (опционально, для локальной БД)

### Клиент (Flutter)

> Перед первым запуском: `cd client && flutter create .` — создаст папки платформ (android, ios, web и т.д.)

```bash
cd client
flutter pub get
flutter run -d chrome     # Web
flutter run -d windows    # Desktop
flutter run               # Подключённое устройство
```

Если на Web иконки (Material Icons) не отображаются — шрифт подключён в `client/web/assets/fonts/` и в `pubspec.yaml`. Для продакшен-сборки при необходимости: `flutter build web --no-tree-shake-icons`.

### Сервер (Go)

```bash
cd server
go mod download
go run ./cmd/server
```

### База данных (Docker)

В корне проекта есть `docker-compose.yml` с **PostgreSQL** и **Redis**. Поднять контейнеры:

```bash
docker compose up -d
```

- **Postgres**: порт `5432`, пользователь/БД `multigames`, пароль `multigames`
- **Redis**: порт `6379`

Сервер подключается к ним по умолчанию (`localhost:5432`, `localhost:6379`). Чтобы задать свои URL — скопируйте `.env.example` в `.env` и при необходимости измените `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `ADMIN_INIT_SECRET` (секрет для однократного создания первого админа через POST `/api/admin/init`), `APP_LOG_FILE`, `APP_LOG_STATE_FILE`, `APP_LOG_SYNC_INTERVAL_SECONDS`.

**Как посмотреть таблицы и данные:** см. [docs/DATABASE.md](docs/DATABASE.md) — подключение через `psql`/redis-cli в контейнерах и параметры для GUI.

### Лаунчер (клиент + сервер одной командой)

Из корня проекта можно запустить и клиент, и сервер сразу:

| ОС        | Команда                |
|-----------|------------------------|
| Windows   | `.\launcher\start.ps1` |
| Windows (перезапуск) | `.\launcher\restart.ps1` |
| Windows (тесты) | `.\launcher\test.ps1` |
| macOS/Linux | `./launcher/start.sh` |
| macOS/Linux (тесты) | `./launcher/test.sh` |

Подробнее: [launcher/README.md](launcher/README.md)

### Деплой на Fly.io

API и статика Flutter Web — один сервис на Fly.io. Postgres — Fly Postgres; Redis опционален.

**Команды** (из корня проекта, подставь своё имя приложения вместо `APP`):

```bash
# 1. Создать приложение (если ещё нет)
fly launch --no-deploy

# 2. Postgres: создать и привязать
fly postgres create --name multigames-db --region arn
fly postgres attach multigames-db --app APP

# 3. Секреты
fly secrets set JWT_SECRET="длинная-случайная-строка-32-символа" --app APP
fly secrets set ADMIN_INIT_SECRET="секрет-для-первого-админа" --app APP

# 4. Деплой
fly deploy --app APP
```

#### Быстрый деплой из Cursor через конфиг

Чтобы каждый раз не вводить токены вручную, используй шаблон:

```bash
cp deploy.cursor.env.example deploy.cursor.env
```

Заполни `deploy.cursor.env` своими значениями (`FLY_API_TOKEN`, `JWT_SECRET`, `ADMIN_INIT_SECRET`).

> `deploy.cursor.env` уже добавлен в `.gitignore`, поэтому реальные токены в git не уйдут.

**Самый простой запуск:**

```bash
./launcher/deploy_cursor.sh
```

```powershell
.\launcher\deploy_cursor.ps1
```

Скрипты сами подхватывают `deploy.cursor.env`, обновляют секреты и запускают deploy.

**Linux/macOS/Cursor shell:**

```bash
set -a
source deploy.cursor.env
set +a

fly secrets set JWT_SECRET="$JWT_SECRET" ADMIN_INIT_SECRET="$ADMIN_INIT_SECRET" --app "$FLY_APP_NAME"
fly deploy --app "$FLY_APP_NAME" --remote-only --yes
```

**PowerShell (Windows):**

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

После деплоя — https://APP.fly.dev. Первого админа создаёшь запросом `POST /api/admin/init` с заголовком `X-Admin-Init-Secret` (см. [DEPLOY.md](DEPLOY.md)).

- **Подробно:** [DEPLOY.md](DEPLOY.md), [docs/DEPLOY_FLY.md](docs/DEPLOY_FLY.md)
- **Не открывается сайт:** [docs/DEPLOY_FLY_TROUBLESHOOTING.md](docs/DEPLOY_FLY_TROUBLESHOOTING.md)

### Запуск из IDE (Cursor / VS Code)

В `.vscode/` настроены:

- **Задача «Docker: Compose Up»** — поднимает Postgres и Redis (`docker compose up -d`).
- **Конфигурация «Go: Server»** — перед отладкой сервера автоматически запускает Docker.
- **«MultiGames: Server + Client»** — compound: сначала Docker, затем Go-сервер и Flutter Web.

Выбери нужную конфигурацию в списке Run and Debug и нажми Run.

---

## ✅ Реализовано

- **Docker Compose** — PostgreSQL 16 и Redis 7 с healthcheck и томами.
- **Миграции БД** — при старте сервера применяются:
  - `001` — таблицы `users` (email, password_hash, display_name) и `sessions`;
  - `002` — колонка `is_admin` у пользователей;
  - `003` — уникальный `display_name` для входа по логину или по почте.
  - `005` — таблица `app_logs` для логов фронта/бэка (через импорт из файла).
- **Авторизация (бэкенд)** — POST `/api/auth/register`, POST `/api/auth/login`, GET `/api/me` (Bearer). Вход по **email или по логину** (display_name). JWT: access (15 мин) и refresh (7 дней).
- **Первый админ** — POST `/api/admin/init` с заголовком `X-Admin-Init-Secret` (значение из `ADMIN_INIT_SECRET` в `.env`). Создаёт первого пользователя-админа.
- **Админ-API** — только для пользователей с `is_admin = true`: GET `/api/admin/users`, GET `/api/admin/logs`, POST `/api/admin/users/set-admin`, `reset-password`, `delete`. Цепочка middleware: RequireAuth → RequireAdmin.
- **Клиент (Flutter)** — общий Shell с тулбаром (логотип, вход/имя+щит+выход), маршруты `/`, `/login`, `/register`, `/admin`. Экраны входа (email или логин + пароль) и регистрации. Админка: вкладки «Пользователи» и «Логи», где логи разбиты по временным окнам, фильтруются по пользователю и источнику (frontend/backend), есть копирование окна и «Скопировать всё». Riverpod, go_router, SharedPreferences для токена и пользователя.
- **Документация** — [API](docs/API.md), [базы данных](docs/DATABASE.md).
- **Тесты** — Go: `cd server && go test ./...`; Flutter: `cd client && flutter test`.

---

## 🎯 План

| Этап | Действие |
|------|----------|
| 1 | Развернуть всё на **Fly.io**: Go-API, Postgres (Fly Postgres), статика Flutter Web (тот же сервис или отдельное приложение) |
| 2 | ~~Сделать админку: смена паролей и удаление пользователей~~ ✅ Готово |

### Схема веток

```
main     ──●────────────────────●──────────────
            \                  /
develop ────●──●──●──●──●──●──●
                 \      /
feature/xxx ──────●──●──●
```

- **main** — продакшен, релизы
- **develop** — активная разработка
- **feature/\*** — отдельные фичи, вливаются в develop через PR

Подробнее: [docs/GITHUB_PLAN.md](docs/GITHUB_PLAN.md)

---

## 📦 Стек технологий

| Слой | Технологии |
|------|------------|
| Клиент | Flutter, Riverpod, go_router, Rive, Lottie, flame |
| Сервер | Go, Chi/Fiber, gorilla/websocket |
| БД | PostgreSQL, Redis |
| Деплой | Docker, Fly.io / Railway / VPS |

---

## 📄 Лицензия

MIT (или указать свою)

---

## 🔗 Ссылки

- [Документация](docs/)
- [API (авторизация)](docs/API.md)
- [Базы данных: таблицы и Redis](docs/DATABASE.md)
- [Деплой на Fly.io](DEPLOY.md) · [подробная инструкция](docs/DEPLOY_FLY.md)
- [План GitHub](docs/GITHUB_PLAN.md)
- [Лаунчер (клиент + сервер)](launcher/README.md)
