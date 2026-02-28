# 🎮 MultiGames

Монорепозиторий веб-клиента на Flutter и API на Go для мультиплатформенного игрового приложения.

## 📌 Текущее состояние проекта

На текущем этапе в репозитории реализованы:

- полноценная аутентификация (register/login/me + refresh flow);
- профиль пользователя (ник, возраст, пол, about, аватар);
- модуль друзей (друзья, входящие/исходящие заявки, поиск, действия);
- админка (пользователи + логи с фильтрами);
- централизованное логирование frontend/backend в БД через файл-буфер;
- деплой Flutter Web + Go API одним сервисом на Fly.io.

Игровые режимы (`/games`, `/tournaments`, и др.) пока представлены базовыми экранами-заглушками.

---

## 🏗 Архитектура

```text
Flutter (Web client, Riverpod + go_router)
            │ REST (/api/*)
            ▼
Go (net/http, middleware, auth, friends, admin, logging)
            │
            ├── PostgreSQL (users, sessions, friends, logs)
            └── Redis (опционально)
```

---

## 🧱 Актуальный стек

### Клиент (`client/`)

- Flutter (Dart SDK `>=3.2.0 <4.0.0`)
- `flutter_riverpod`
- `go_router`
- `http`
- `shared_preferences`
- `image_picker`, `path_provider`, `image_picker_web`

### Сервер (`server/`)

- Go `1.24`
- стандартный `net/http` + `http.ServeMux`
- `pgx/v5` (PostgreSQL)
- `golang-migrate/migrate` (миграции)
- `golang-jwt/jwt/v5` (JWT)
- `go-redis/v9` (Redis)
- `joho/godotenv` (env-конфиг)

### Инфраструктура

- Docker multi-stage build (Flutter build + Go binary)
- `docker-compose` для локального Postgres/Redis
- Fly.io (деплой приложения)

---

## 📁 Структура репозитория

```text
.
├── client/                    # Flutter клиент
│   ├── lib/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── core/
│   │   ├── friends/
│   │   ├── screens/
│   │   ├── ui/
│   │   └── widgets/
│   └── pubspec.yaml
├── server/                    # Go API
│   ├── cmd/server/
│   ├── internal/
│   │   ├── api/
│   │   ├── applog/
│   │   ├── auth/
│   │   └── store/
│   ├── migrations/
│   └── go.mod
├── launcher/                  # скрипты запуска/тестов/деплоя
├── docs/
├── docker-compose.yml
├── Dockerfile
├── fly.toml
└── README.md
```

---

## ✅ Что уже реализовано

### Бэкенд

- Миграции `001..006`:
  - `users`, `sessions`;
  - `is_admin`;
  - логин по `email` или `display_name`;
  - профильные поля (`age`, `gender`, `about`, `avatar_*`);
  - `app_logs`;
  - `friendships`, `friend_requests`.
- Auth API:
  - `POST /api/auth/register`
  - `POST /api/auth/login`
  - `POST /api/auth/refresh`
  - `GET /api/me`
  - `PUT /api/profile`
- Friends API:
  - `GET /api/friends`
  - `GET /api/friends/search`
  - `POST /api/friends/request|accept|reject|cancel|remove`
- Admin API:
  - `POST /api/admin/init`
  - `GET /api/admin/users`
  - `GET /api/admin/logs`
  - `POST /api/admin/users/set-admin|reset-password|delete`
- Логи:
  - backend request logging middleware;
  - endpoint `POST /api/logs/frontend` для клиентских событий;
  - импорт JSONL-файла в `app_logs`;
  - retention cleanup по времени.

### Фронтенд

- Авторизация с автопродлением сессии через refresh token.
- Guard маршрутов (в т.ч. `/admin`) и редирект на `/login` при невалидной сессии.
- Профиль с редактированием и аватаром.
- Админка:
  - управление пользователями;
  - просмотр логов с фильтрами (user/source/date range);
  - копирование логов (включая лимиты 120/500/1000/все).
- Модуль друзей:
  - друзья/входящие/исходящие;
  - бейдж входящих в нижнем меню;
  - сворачиваемый поиск;
  - динамическое скрытие пустых вкладок входящих/исходящих;
  - компактные карточки и icon-only actions;
  - поиск только по нику (`display_name`);
  - email в карточках друзей не отображается.

---

## 🚀 Быстрый старт

### Требования

- Flutter `3.24+`
- Go `1.24+`
- Docker (для локальной БД/кэша)

### 1) Локальные сервисы

```bash
docker compose up -d
```

### 2) Переменные окружения

```bash
cp .env.example .env
```

Ключевые переменные:

- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `ADMIN_INIT_SECRET`
- `APP_LOG_FILE`, `APP_LOG_STATE_FILE`
- `APP_LOG_SYNC_INTERVAL_SECONDS`
- `APP_LOG_RETENTION_DAYS`
- `APP_LOG_CLEANUP_INTERVAL_SECONDS`

### 3) Сервер

```bash
cd server
go mod download
go run ./cmd/server
```

### 4) Клиент

```bash
cd client
flutter pub get
flutter run -d chrome
```

> Если платформенные папки ещё не созданы: `cd client && flutter create .`

---

## 🧪 Тесты и проверки

### Go

```bash
cd server
go test ./...
go build ./...
```

### Flutter

```bash
cd client
flutter analyze --no-fatal-infos
flutter test
```

---

## ☁️ Деплой (Fly.io)

Проект деплоится одним приложением:

- Go API на `/api/*`;
- Flutter Web как встроенная статика (`embed`) на `/*`.

Быстрый вариант из Cursor/локально:

```bash
cp deploy.cursor.env.example deploy.cursor.env
# заполнить FLY_API_TOKEN, FLY_APP_NAME, JWT_SECRET, ADMIN_INIT_SECRET
./launcher/deploy_cursor.sh
```

Если нужно всегда деплоить именно `origin/develop`:

```bash
./launcher/deploy_develop.sh
```

Windows:

```powershell
.\launcher\deploy_cursor.ps1
```

```powershell
.\launcher\deploy_develop.ps1
```

В чате Cursor доступна slash-команда проекта:

```
/deploy-develop
```

**Отключить логирование в production:**

```bash
fly secrets set APP_LOG_ENABLED=false --app multigameszozu
```

Подробно: [DEPLOY.md](DEPLOY.md), [docs/DEPLOY_FLY.md](docs/DEPLOY_FLY.md)

---

## 🎯 Актуальные задачи (roadmap)

### Уже сделано

- [x] Auth + refresh token flow
- [x] Профиль пользователя
- [x] Админка пользователей
- [x] Система логирования frontend/backend в БД
- [x] Модуль друзей (API + UI)
- [x] Базовый деплой на Fly.io

### Ближайшие задачи

- [ ] Добавить интеграционные тесты с реальной БД для friends/admin сценариев
- [ ] Расширить покрытие Flutter widget-тестами ключевых экранов
- [ ] Реализовать игровые режимы (вместо заглушек) и соответствующие API
- [ ] Подготовить релизный чек-лист для production (monitoring, alerts, backup policy)

---

## 🔗 Документация

- [API](docs/API.md)
- [DATABASE](docs/DATABASE.md)
- [DEPLOY](DEPLOY.md)
- [Fly.io deployment guide](docs/DEPLOY_FLY.md)
- [Launcher scripts](launcher/README.md)
