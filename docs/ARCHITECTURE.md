# 🏗 Архитектура проекта

## Обзор

Проект состоит из двух сервисов в одном репозитории (монорепо):

- **`client/`** — клиент на **Flutter Web** (Riverpod + go_router), SPA.
- **`server/`** — **Go** API на стандартном `net/http` + `http.ServeMux`.

Связь: **REST** (`/api/*`) для запросов «запрос–ответ» и **WebSocket**
(`/api/ws`) для событий реального времени (presence, чаты, игры, друзья,
награды). Продакшн — один Docker-образ: Go-сервер встраивает собранную
Flutter Web-статикy через `//go:embed web` и раздаёт её на `/*`, API — на
`/api/*`.

```
Flutter Web (Riverpod + go_router)
        │  REST /api/*  +  WebSocket /api/ws?access_token=<jwt>
        ▼
Go (net/http, middleware, auth, store, applog, i18n, mailer)
        │
        ├── PostgreSQL 16  — пользователи, соцграф, чаты, экономика, настройки, логи (источник истины)
        └── Redis 7        — эфемерное состояние игр/лобби/матчмейкинга + Pub/Sub-бродкаст (опционален)
```

> **Postgres vs Redis.** Источник истины — Postgres. Состояние партий,
> лобби и очереди матчмейкинга живёт **только в Redis** (хэши `game:*`,
> `lobby:*`, списки `tictactoe:matchmake:*`). Поэтому без Redis игры
> недоступны, но остальное (auth, друзья, чаты, магазин, монеты, админка,
> presence) продолжает работать. См. [DATABASE.md](DATABASE.md).

---

## Server (Go)

```
server/
├── cmd/
│   └── server/         # main.go — точка входа: env, миграции, пул соединений, сборка роутов
├── internal/
│   ├── api/            # HTTP-хендлеры, middleware, WebSocket-hub, OAuth, Web Push, бродкастер игр
│   ├── applog/         # Логирование: файл JSONL → фоновый импорт в app_logs + retention
│   ├── auth/           # JWT (HS256, access + refresh), bcrypt
│   ├── i18n/           # Локализация серверных сообщений (по Accept-Language)
│   ├── mailer/         # Отправка писем: Resend или SMTP (коды подтверждения, сброс пароля)
│   └── store/          # Слой БД: stateless-функции с *pgxpool.Pool, прямой SQL, транзакции
├── migrations/         # SQL-миграции golang-migrate (NNN_name.up.sql / .down.sql)
└── go.mod              # module multigames/server, Go 1.24
```

### Слои и поток данных

Зависимости однонаправленные: `cmd → api → {auth, store, applog, i18n, mailer}`;
`store`, `auth`, `i18n`, `mailer` не зависят от других внутренних пакетов.

Типичный HTTP-запрос:
```
Request
  → CORS
  → RequestLogger (лог в файл/БД + асинхронное обновление last_seen_at)
  → RequireAuth (Bearer JWT → UserID в context)        [для защищённых роутов]
  → RequireAdmin (проверка is_admin)                   [для /api/admin/*]
  → Handler (валидация → store.* → маппинг в JSON)
  → побочные эффекты: RealtimeHub.Publish (WS) + WebPush.NotifyUsers (асинхронно) + достижения
```

- **`cmd/server/main.go`** — загружает `.env` (`server/.env` или корневой),
  применяет миграции (`migrate.Up`), создаёт `pgxpool`, опционально Redis,
  собирает хендлеры и регистрирует все роуты на одном `http.ServeMux`.
  Если рядом лежит встроенная Flutter-сборка (`cmd/server/web/index.html`),
  заворачивает mux так, что `/api/*` идёт в API, остальное — в SPA-раздачу.
- **`internal/api/`** — хендлеры — это структуры с полями-зависимостями
  (`Pool`, `Hub`, `Push`, `Rdb`, `Mailer`, `OAuth`), тонкая логика:
  валидация → вызов `store.*` → JSON-ответ + realtime/push side-effects.
  Домены: `auth`, `friends`, `chats`, `games`, `presence`, `coins`,
  `achievements`, `shop`, `web_push`, `settings`, `admin`, `realtime_ws`,
  `oauth`. Middleware: `CORS`, `RequireAuth`, `RequireAdmin`,
  `RequestLogger`, `GetUserID`.
- **`internal/store/`** — функции верхнего уровня
  (`func CreateUser(ctx, pool, …)`), не методы/репозитории. Прямой SQL через
  `pool.Query/QueryRow/Exec`, транзакции `pool.Begin` только где нужна
  атомарность (списание монет, accept friend, claim reward, покупки).
- **`internal/auth/`** — два токена: access (15 мин) + refresh (7 дней).
  Refresh хранится в `sessions` как SHA-256-хэш и ротируется при `/refresh`.
- **`internal/applog/`** — события (фронт + бэк) пишутся в JSONL-файл,
  фоновый `Importer` переносит их в таблицу `app_logs` и чистит по
  retention. Есть и прямой путь записи в БД.
- **`internal/i18n/`** — серверные сообщения локализуются по `Accept-Language`
  (`i18n.T(lang, key)`).
- **`internal/mailer/`** — провайдер `resend` или `smtp`; отправляет коды
  подтверждения email и сброса пароля.

### Realtime и масштабирование

`RealtimeHub` (in-memory, `map[userID]map[*conn]*client`) хранит WS-клиенты
текущего инстанса. Для горизонтального масштабирования события игр идут через
`GamesBroadcaster` → **Redis Pub/Sub**-канал `games:broadcast` → все инстансы
получают и форвардят в свой локальный `Hub`. Присутствие/чаты/друзья идут
через локальный `Hub` (требуют общего Postgres/Redis).

---

## Client (Flutter)

```
client/
├── lib/
│   ├── main.dart       # Точка входа: ProviderScope, локализация, темы, Web Push-навигация
│   ├── router.dart     # go_router: StatefulShellRoute (6 веток) + guards
│   ├── core/           # api_client, api_config, realtime-ядро, presence, settings, web_push, locale, connectivity
│   ├── auth/           # AuthRepository (JWT + авто-refresh), провайдеры, OAuth, восстановление пароля
│   ├── friends/        # Репозиторий + провайдеры (snapshot через realtime), поиск
│   ├── chats/          # Чаты: список, комната, доставка/чтение, изображения, провайдеры
│   ├── games/          # Крестики-нолики: настройки, лобби, игра, навигация, офлайн-режим
│   ├── shop/           # Магазин, инвентарь, коллекции, эмоции, подарки
│   ├── achievements/   # Достижения (рамки), награды
│   ├── admin/          # Админка: пользователи, логи
│   ├── screens/        # Экраны (home, profile, login, register, friends, chats, games, shop, settings, admin, …)
│   ├── widgets/        # app_shell (навигация + бейджи), OAuth-виджеты
│   ├── ui/             # app_theme, responsive (isNarrow/isWide), ui/widgets/ (UI-кит)
│   ├── utils/          # relative_time, user_error
│   ├── l10n/           # Сгенерированная локализация (.dart) + исходники (.arb)
│   └── src/            # console_log (web/stub)
├── assets/             # Изображения, Lottie
└── pubspec.yaml        # flutter_riverpod, go_router, http, generate: true (l10n)
```

### State management и поток данных

**Riverpod 2.6** (`ProviderScope` в `main.dart`). Паттерны:

- `Provider` — репозитории, конфиг, роутер.
- `StateNotifierProvider` — мутируемое состояние (`AuthStateNotifier`,
  `GameInvitesNotifier`, настройки, Web Push).
- `FutureProvider` / `.autoDispose` / `.family` — разовые запросы (лобби,
  состояние игры, каталог магазина).
- `StreamProvider.autoDispose` + `keepAlive` — live-данные, все подписаны
  на единый `realtimeEventsProvider`.

Поток: **UI** (`ref.watch`/`ref.read`) → **Provider** (оркестрация, подписка
на realtime) → **Repository** (`*_repository.dart`: модели `fromJson`,
типизированные exceptions, URI через `apiBaseUrl`) → **`AuthRepository.
sendAuthorized()`** (добавляет `Bearer`, при 401 → авто-refresh → повтор) →
**`ApiClient`** (`core/api_client.dart`: статические `get/post/put`, тайминги,
телеметрия-лог на `/api/logs/frontend`) → **Backend** (Go API).

### Realtime-ядро

Один общий `realtimeEventsProvider` — единственный WebSocket `/api/ws` на всё
приложение. Все доменные stream-провайдеры (`friendsSnapshotProvider`,
`chatsListProvider`, `blockedUsersProvider`, `presenceMapProvider`)
`ref.listen(realtimeEventsProvider)` и фильтруют события по `type`. Это
исключает гонки множественных сокетов. Переподключение через таймер,
управление видимостью вкладки (при скрытой — дисконнект, при показе —
реконнект).

### Роутинг и адаптивность

`go_router` (`StatefulShellRoute.indexedStack`) — 6 веток: Главная, Профиль,
Друзья, Чаты, Игры, Настройки. Guards: redirect на `/login` без токена,
admin-guard для `/admin`. `AppShell` (`widgets/app_shell.dart`) держит
активными realtime/presence/push и обновляет бейджи.

Адаптивность (`ui/responsive.dart`): `Breakpoints.mobile = 700`,
`isNarrow(context)`/`isWide(context)` через `MediaQuery.shortestSide`
(корректно для landscape). Узкий экран → нижняя навигация, широкий/landscape →
`NavigationRail`. Учёт iOS PWA (чёлка, home indicator, схлопывание панели при
клавиатуре). Подробности — в правиле `.cursor/rules/ui-adaptive.mdc`.

---

## Связанные документы

- [API](API.md) — все эндпоинты REST + WebSocket.
- [DATABASE](DATABASE.md) — таблицы Postgres, ключи Redis, подключение.
- [DEPLOY](../DEPLOY.md), [DEPLOY_FLY.md](DEPLOY_FLY.md) — деплой на Fly.io.
