# 🎮 MultiGames

Монорепозиторий веб-клиента на Flutter и API на Go для мультиплатформенного игрового приложения.

## 📌 Текущее состояние проекта

На текущем этапе в репозитории реализованы:

- полноценная аутентификация (register/login/me + refresh flow, подтверждение email, сброс пароля, OAuth Google/Apple/Yandex/VK);
- профиль пользователя (ник, возраст, пол, about, аватар);
- модуль друзей (друзья, входящие/исходящие заявки, поиск, действия);
- чаты между друзьями (список, сообщения, чтение, блокировка, изображения, редактирование/ответы);
- presence (онлайн-статус пользователей);
- монеты и ежедневная награда;
- крестики-нолики (лобби, invite/matchmake, игра 3×3–8×8, ставки, бот);
- статистика игрока (победы/ничьи/поражения, win-rate, время в игре, топ соперников, счёт head-to-head в попапе профиля);
- магазин и инвентарь (эмоции, коллекции, рамки, подарки, доход коллекций);
- достижения с наградами (рамки);
- Web Push-уведомления (PWA) с категориями (чат/друзья/игры/награды);
- локализация интерфейса (27+ языков через `.arb`);
- адаптивный интерфейс (десктоп / мобильные, PWA на iOS);
- админка (пользователи + логи с фильтрами);
- централизованное логирование frontend/backend в БД через файл-буфер;
- деплой Flutter Web + Go API одним сервисом на Fly.io.

---

## 🏗 Архитектура

```text
Flutter (Web client, Riverpod + go_router)
            │ REST (/api/*) + WebSocket (/api/ws)
            ▼
Go (net/http, middleware, auth, friends, chats, games, shop, admin, logging, i18n, mailer)
            │
            ├── PostgreSQL — источник истины (users, sessions, друзья, чаты, экономика, настройки, логи)
            └── Redis — эфемерное состояние игр/лобби/матчмейкинга + Pub/Sub (опционален; без него games недоступны)
```

> Чаты и presence (онлайн-статус) живут в **Postgres**, а не в Redis. В Redis
> хранится только состояние партий, лобби и очередь матчмейкинга. Подробности —
> в [docs/DATABASE.md](docs/DATABASE.md) и [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🧱 Актуальный стек

### Клиент (`client/`)

- Flutter (Dart SDK `>=3.2.0 <4.0.0`), Material 3
- `flutter_riverpod` (state management)
- `go_router` (роутинг, `StatefulShellRoute`)
- `http`, `shared_preferences`
- `image_picker`, `path_provider`
- `flutter_localizations` + `intl` (i18n, 27+ языков через `.arb`)
- `lottie`, `flutter_animate`, `flutter_slidable`
- `image` (сжатие изображений в чате)

### Сервер (`server/`)

- Go `1.24`
- стандартный `net/http` + `http.ServeMux`
- `pgx/v5` (PostgreSQL)
- `golang-migrate/migrate` (миграции)
- `golang-jwt/jwt/v5` (JWT, access + refresh)
- `go-redis/v9` (Redis)
- `gorilla/websocket` (WebSocket, realtime)
- `SherClockHolmes/webpush-go` (Web Push / VAPID)
- `golang.org/x/crypto` (bcrypt)
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
│   │   ├── achievements/      # достижения (рамки/награды)
│   │   ├── admin/             # админка (пользователи, логи)
│   │   ├── auth/              # AuthRepository, JWT-автоrefresh, OAuth, сброс пароля
│   │   ├── chats/             # чаты: список, комната, доставка/чтение, изображения
│   │   ├── core/              # api_client, api_config, realtime-ядро, presence, web_push
│   │   ├── friends/           # друзья: репозиторий, провайдеры, поиск
│   │   ├── games/             # крестики-нолики: настройки, лобби, игра, навигация
│   │   ├── shop/              # магазин, инвентарь, коллекции, эмоции, подарки
│   │   ├── screens/           # экраны
│   │   ├── widgets/           # app_shell (навигация + бейджи), OAuth-виджеты
│   │   ├── ui/                # тема, responsive, ui/widgets (UI-кит)
│   │   ├── utils/             # relative_time, user_error
│   │   ├── l10n/              # сгенерированная локализация (.dart) + исходники (.arb)
│   │   ├── src/               # console_log (web/stub)
│   │   ├── main.dart
│   │   └── router.dart
│   └── pubspec.yaml
├── server/                    # Go API
│   ├── cmd/server/            # main.go — точка входа
│   ├── internal/
│   │   ├── api/               # HTTP-хендлеры, middleware, WebSocket, OAuth, Web Push
│   │   ├── applog/            # логирование: файл JSONL → импорт в app_logs
│   │   ├── auth/              # JWT (HS256), bcrypt
│   │   ├── i18n/              # локализация серверных сообщений
│   │   ├── mailer/            # почта: Resend или SMTP (коды подтверждения)
│   │   └── store/             # слой БД (stateless-функции, pgx)
│   ├── migrations/            # миграции golang-migrate (001..045)
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

- Миграции `001..044`:
  - `users`, `sessions`; `is_admin`; логин по `email` или `display_name`;
    профильные поля (`age`, `gender`, `about`, `avatar_*`); баланс, ежедневная
    награда, серия входов, рефералы; `email_verified_at`;
  - `app_logs`; `friendships`, `friend_requests`;
  - чаты (`chats`, `chat_messages`, `chat_message_images`) и блокировки
    (`user_blocks`);
  - прогресс и достижения (`user_stats`, `user_achievements`);
  - магазин и инвентарь (`shop_items`, `user_inventory`);
  - настройки игр (`user_game_settings`) и общие настройки (`user_settings`);
  - Web Push (`web_push_subscriptions`, `web_push_preferences`);
  - OAuth (`oauth_accounts`), коды подтверждения email и сброса пароля
    (`email_verification_codes`, `password_reset_codes`, `pending_registrations`).
- Auth API:
  - `POST /api/auth/register` — заявка + код на email; пользователь в БД создаётся только после verify
  - `POST /api/auth/verify-email` — подтверждение кода, выдача JWT
  - `POST /api/auth/resend-verification` — повторная отправка кода
  - `POST /api/auth/forgot-password` — код сброса пароля на email
  - `POST /api/auth/reset-password` — новый пароль по коду, выдача JWT
  - `POST /api/auth/login`
  - `POST /api/auth/refresh`
  - `GET /api/auth/oauth/providers` — включённые OAuth (google/apple/yandex/vk)
  - `GET /api/auth/oauth/{provider}/start` → callback → `/oauth/callback`
  - `GET /api/me`
  - `PUT /api/profile`
- Friends API:
  - `GET /api/friends`
  - `GET /api/friends/users-count`
  - `GET /api/friends/search`
  - `POST /api/friends/request|accept|reject|cancel|remove`
- Chats API (всё в Postgres):
  - `GET /api/chats`, `POST /api/chats/start`, `GET /api/chats/capabilities`
  - `GET /api/chats/messages`, `POST /api/chats/messages`, `POST /api/chats/messages/image`
  - `POST /api/chats/messages/edit`, `POST /api/chats/messages/delete` (редактирование, удаление, ответы, вложения)
  - `POST /api/chats/read`, `POST /api/chats/delivered`
  - `POST /api/chats/clear`, `POST /api/chats/block`, `POST /api/chats/unblock`, `GET /api/chats/blocked`
- Presence API: `GET /api/presence?user_ids=...`
- Coins API: `GET /api/coins/daily-available`, `POST /api/coins/claim-daily`
- Games API (крестики-нолики, Redis обязателен):
  - `GET|PUT /api/games/settings` — настройки игры (без Redis, Postgres)
  - `POST /api/games/tictactoe/lobby` — создать лобби (invite/matchmake)
  - `GET /api/games/tictactoe/lobbies` — список открытых лобби
  - `GET /api/games/tictactoe/lobby/:id`, `POST /api/games/tictactoe/lobby/:id/invite|join|leave|decline`
  - `POST /api/games/tictactoe/rematch` — реванш
  - `GET /api/games/tictactoe/active` — активная игра/лобби
  - `GET /api/games/tictactoe/game/:id`, `POST /api/games/tictactoe/game/:id/move|swap|forfeit|draw-offer|draw-accept`
  - `GET /api/games/stats` — своя статистика (W/D/L, win-rate, время в игре, топ соперников; без Redis)
  - `GET /api/games/head-to-head?user_id=<uuid>` — счёт между двумя игроками (без ботов)
- Shop & inventory API:
  - `GET /api/shop`, `POST /api/shop/buy`
  - `GET /api/inventory`, `GET /api/inventory/capabilities`
  - `POST /api/inventory/consume|sell|gift`
  - `GET /api/inventory/collections`, `GET /api/inventory/collection-income`, `POST /api/inventory/claim-collection-income`
- Achievements API: `GET /api/achievements`, `GET /api/achievements/unclaimed-count`, `POST /api/achievements/claim`
- Settings API: `GET|PUT /api/settings` (например, `messages_friends_only`)
- Web Push API (PWA): `GET /api/push/vapid-key`, `POST /api/push/subscribe|unsubscribe`, `GET|PUT /api/push/preferences`
- Admin API:
  - `POST /api/admin/init`
  - `GET /api/admin/users`
  - `GET /api/admin/logs`, `POST /api/admin/logs/clear`
  - `POST /api/admin/users/set-admin|reset-password|delete`
- Realtime: `GET /api/ws?access_token=<jwt>` (WebSocket) — presence, чаты, друзья, игры, награды.
- Логи:
  - backend request logging middleware;
  - endpoint `POST /api/logs/frontend` для клиентских событий;
  - импорт JSONL-файла в `app_logs`;
  - retention cleanup по времени.

### Фронтенд

- Авторизация с автопродлением сессии через refresh token.
- Вход через OAuth (Google/Apple/Yandex/VK), если настроены провайдеры.
- Подтверждение email и восстановление пароля по коду.
- Guard маршрутов (в т.ч. `/admin`) и редирект на `/login` при невалидной сессии.
- Профиль с редактированием и аватаром.
- Адаптивный интерфейс: нижняя навигация на мобильных, `NavigationRail` на десктопе/landscape; на широких экранах магазин/инвентарь/монеты за вход — плитки по центру; учёт iOS PWA (чёлка, home indicator).
- Локализация интерфейса (27+ языков).
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
- Чаты (`/chats`): список диалогов, комната чата, непрочитанные, блокировка, изображения, редактирование и ответы.
- Presence: онлайн-статус в списке друзей и чатах.
- Монеты и ежедневная награда (`/coins` или в меню).
- Крестики-нолики (`/games`):
  - «Своя игра» (приглашение друга) и «Поиск игры» (matchmake);
  - поле 3×3–8×8, время на ход, правило swap, запрет центра;
  - ставки в бронзовых;
  - бот: если соперник не найден за 30 с (опция в настройках) — игра на 1 бр.;
  - умный бот (минимакс 3×3, эвристики для больших полей), задержка 1 с перед ходом;
  - карточка соперника (чат, добавить в друзья — скрыто для бота);
  - иконка правил в экране игры.
- Магазин и инвентарь (`/shop`, `/inventory`): эмоции, коллекции, рамки, подарки друзьям, доход коллекций.
- Достижения (`/achievements`) с наградами и рамками аватара.
- Web Push (PWA): подписка и категории уведомлений (чат/друзья/игры/награды).
- Настройки (`/settings`):
  - опция «Добавлять ботов через 30 с» — при поиске игры: если соперник не найден за 30 секунд, начинается игра с ботом.

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
- `PUBLIC_BASE_URL`, `FRONTEND_URL` — для OAuth redirect_uri
- `RESEND_API_KEY`, `MAIL_FROM` — письма с кодом через [Resend](https://resend.com) (предпочтительно). Код всегда адресуется на email из регистрации; с `onboarding@resend.dev` Resend доставляет только на email аккаунта Resend — после верификации домена поставьте `MAIL_FROM=ZozuGames <noreply@ваш-домен>`
- `SMTP_*` — альтернатива Resend; без почты код только в логе сервера
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`, `APPLE_*`, `YANDEX_*`, `VK_*` — OAuth (пусто = кнопки скрыты)
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
- [x] Подтверждение email, сброс пароля, OAuth (Google/Apple/Yandex/VK)
- [x] Профиль пользователя
- [x] Админка пользователей
- [x] Система логирования frontend/backend в БД
- [x] Модуль друзей (API + UI)
- [x] Чаты (API + UI) с изображениями, редактированием и ответами
- [x] Presence, монеты, ежедневная награда
- [x] Крестики-нолики (лобби, matchmake, игра, бот, ставки)
- [x] Магазин, инвентарь, коллекции, эмоции, подарки
- [x] Достижения с наградами (рамки)
- [x] Web Push-уведомления (PWA)
- [x] Локализация интерфейса (27+ языков)
- [x] Базовый деплой на Fly.io

### Ближайшие задачи

- [ ] Добавить интеграционные тесты с реальной БД для friends/admin/chats/games
- [ ] Расширить покрытие Flutter widget-тестами ключевых экранов
- [ ] Реализовать дополнительные игровые режимы (сейчас только крестики-нолики)
- [ ] Подготовить релизный чек-лист для production (monitoring, alerts, backup policy)

---

## 🔗 Документация

- [Архитектура](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Базы данных](docs/DATABASE.md)
- [DEPLOY](DEPLOY.md)
- [Fly.io deployment guide](docs/DEPLOY_FLY.md)
- [Launcher scripts](launcher/README.md)
