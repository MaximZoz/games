# Базы данных: PostgreSQL и Redis

В проекте используются **PostgreSQL 16** (таблицы — источник истины) и
**Redis 7** (эфемерное состояние игр/лобби, Pub/Sub-бродкаст; опционален).
Оба сервиса запускаются через Docker Compose.

> **Postgres vs Redis.** Пользователи, соцграф, чаты, экономика, настройки и
> логи живут в Postgres. Состояние партий, лобби и очередь матчмейкинга —
> **только в Redis**. Поэтому без Redis игры (`/api/games/*`) недоступны, но
> остальное работает. Миграции применяются Go-сервером при старте.

---

## Docker Compose

Контейнеры описаны в корне проекта в `docker-compose.yml`.

| Сервис    | Контейнер             | Порт  | Назначение                                  |
|-----------|-----------------------|-------|---------------------------------------------|
| PostgreSQL | `multigames-postgres` | 5432 | Основная БД (таблицы)                        |
| Redis     | `multigames-redis`    | 6379  | Игры/лобби/матчмейкинг, Pub/Sub (опционален) |

Поднять контейнеры из корня проекта:

```bash
docker compose up -d
```

Остановить:

```bash
docker compose down
```

---

## PostgreSQL

Миграции лежат в `server/migrations/` (формат golang-migrate:
`NNN_name.up.sql` / `NNN_name.down.sql`) и применяются автоматически при
старте Go-сервера (`m.Up()` в `cmd/server/main.go`).

### Подключение к БД из контейнера (psql)

Интерактивная консоль:

```bash
docker exec -it multigames-postgres psql -U multigames -d multigames
```

Внутри `psql`:

| Команда           | Описание                    |
|-------------------|-----------------------------|
| `\dt`             | Список всех таблиц          |
| `\d имя_таблицы`  | Структура таблицы           |
| `SELECT * FROM users;` | Содержимое таблицы (пример) |
| `\q`              | Выход                       |

Одна команда с хоста (только список таблиц):

```bash
docker exec -it multigames-postgres psql -U multigames -d multigames -c "\dt"
```

### Параметры подключения (для GUI или приложения)

| Параметр  | Значение      |
|-----------|---------------|
| Host      | `localhost`   |
| Port      | `5432`        |
| User      | `multigames`  |
| Password  | `multigames`  |
| Database  | `multigames`  |

Используй их в DBeaver, pgAdmin, DataGrip и т.п. В продакшене (Fly.io) `DATABASE_URL`
проставляется командой `fly postgres attach`.

### Таблицы

Схема формируется миграциями `001`–`044`. Ниже — актуальный список таблиц и
их назначение. Пары «низший/высший ID» (`user_low`/`user_high`) используются
в `friendships`, `chats`, `user_blocks` для канонического хранения
неориентированных связей (`CHECK user_low < user_high`).

#### Учётные записи и сессии

- **`users`** — пользователи. Колонки:
  `id`, `email`, `password_hash`, `display_name`, `created_at`, `updated_at`,
  `is_admin`, `age`, `gender`, `about`, `avatar_kind`, `avatar_value`,
  `balance_bronze`, `last_seen_at`, `daily_reward_claimed_at`,
  `daily_login_streak`, `referred_by`, `collection_income_claimed_at`,
  `email_verified_at`.
- **`sessions`** — refresh-сессии: `id`, `user_id`, `refresh_token_hash`
  (SHA-256), `expires_at`, `created_at`, `previous_refresh_token_hash`,
  `previous_refresh_valid_until`. У пользователя может быть несколько живых
  сессий (телефон и веб). Предыдущий refresh принимается, пока не вышло
  `previous_refresh_valid_until`.
- **`oauth_accounts`** — привязки OAuth-провайдеров: `provider`
  (google/apple/yandex/vk), `provider_user_id`, `email`. `UNIQUE(provider, provider_user_id)`.
- **`pending_registrations`** — незавершённые регистрации (до подтверждения
  email): `email`, `password_hash`, `display_name`, `referred_by`,
  `code_hash`, `expires_at`, `attempts`.
- **`email_verification_codes`** — коды подтверждения email:
  `user_id`, `code_hash`, `expires_at`, `attempts`.
- **`password_reset_codes`** — коды сброса пароля:
  `user_id` (UNIQUE), `code_hash`, `expires_at`, `attempts`.

#### Социальный граф и чаты

- **`friendships`** — друзья. PK `(user_low, user_high)`,
  `CHECK user_low < user_high`.
- **`friend_requests`** — заявки в друзья: `sender_user_id`,
  `receiver_user_id`. `UNIQUE(sender_user_id, receiver_user_id)`.
- **`user_blocks`** — блокировки пользователей. PK `(blocker_user_id, blocked_user_id)`.
- **`chats`** — личные диалоги. PK `id`, `UNIQUE(user_low, user_high)`.
- **`chat_messages`** — сообщения: `chat_id`, `sender_user_id`, `body`,
  `created_at`, `read_at`, `delivered_at`, `edited_at`,
  `reply_to_message_id`, `has_image`, `image_mime`, `image_count`.
  Лимит текста — 2000 рун (`CHECK char_length(body) BETWEEN 1 AND 2000`).
- **`chat_message_images`** — вложенные изображения (до 3 на сообщение):
  `message_id`, `idx` (0–2), `image_mime`, `image_data` (BYTEA,
  `CHECK ≤ 256 KiB`).

#### Экономика, прогресс и магазин

- **`user_stats`** — игровая статистика: `user_id` (PK), `games_finished`.
  Победы по лигам хранятся во `user_achievements` (ниже).
- **`user_achievements`** — достижения/рамки: `user_id`, `code`,
  `reward_bronze`, `unlocked_at`, `claimed_at`. PK `(user_id, code)`.
- **`shop_items`** — каталог магазина: `code` (PK), `kind`
  (`emoji` / `stake_unlock` / `frame`), `title`, `price_bronze`,
  `payload` (JSONB), `stock_remaining` (NULL = безлимит), `active`, `sort_order`.
- **`user_inventory`** — инвентарь покупок: `user_id`, `item_code`,
  `quantity`, `acquired_at`. PK `(user_id, item_code)`.
- **`user_game_settings`** — настройки игр: `user_id`, `game_type`
  (`tictactoe`), `turn_time_sec`, `grid_size` (`CHECK 3..8`), `swap_rule`,
  `first_move_restriction`, `stake_bronze`. PK `(user_id, game_type)`.
- **`user_settings`** — общие настройки пользователя: `user_id` (PK),
  `messages_friends_only`.

#### Push-уведомления

- **`web_push_subscriptions`** — подписки Web Push (PWA): `user_id`,
  `endpoint` (UNIQUE), `p256dh`, `auth`, `user_agent`.
- **`web_push_preferences`** — категории уведомлений (по умолчанию всё вкл.):
  `user_id` (PK), `chat`, `friends`, `games`, `rewards`,
  `last_daily_reward_push_date`.
- **`device_push_tokens`** — FCM-токены нативных приложений: `user_id`,
  `token` (UNIQUE), `platform` (`android` / `ios`).

#### Логи

- **`app_logs`** — журнал событий фронта и бэка после импорта из файла:
  `event_id` (PK), `event_time`, `source` (`frontend`/`backend`),
  `method_name`, `http_method`, `path`, `status_code`, `duration_ms`,
  `user_id`, `ip`, `user_agent`, `level`, `message`, `metadata` (JSONB),
  `raw_payload` (JSONB), `created_at`.

---

## Redis

В Redis **нет таблиц** — только ключи и значения (строки, хэши, списки и
т.д.). Сервер использует Redis для **эфемерного состояния игр** и
**Pub/Sub**-бродкаста между инстансами.

### Ключевые шаблоны

| Шаблон                       | Тип      | Назначение                                            |
|------------------------------|----------|-------------------------------------------------------|
| `game:<id>`                  | hash     | Состояние партии (поле, ходы, чей ход, ставки, …)     |
| `lobby:<id>`                 | hash     | Состояние лобби (игроки, настройки, режим)            |
| `user:<id>:active_game`      | string   | ID активной игры пользователя                         |
| `user:<id>:active_lobby`     | string   | ID активного лобби пользователя                       |
| `tictactoe:matchmake:*`      | list     | Очередь матчмейкинга по параметрам игры                |
| `games:broadcast`            | pub/sub  | Канал бродкаста игровых событий между инстансами      |

> Состояние игр **не персистится** в Postgres — при очистке Redis активные
> партии пропадают. Результаты завершённых игр (монеты, статистика,
> достижения) записываются в Postgres в момент окончания партии.

### Подключение к Redis из контейнера (redis-cli)

```bash
docker exec -it multigames-redis redis-cli
```

В консоли:

| Команда        | Описание                |
|----------------|------------------------|
| `KEYS *`       | Все ключи              |
| `KEYS шаблон*` | Ключи по шаблону       |
| `HGETALL game:<id>` | Содержимое хэша партии |
| `TYPE ключ`    | Тип значения           |
| `QUIT`         | Выход                  |

Если установлен redis-cli на хосте (Chocolatey/Scoop):

```bash
redis-cli -h localhost -p 6379
```

### GUI для Redis

- **Redis Insight** — https://redis.io/insight/
- **Another Redis Desktop Manager** — бесплатный клиент

Подключение: host `localhost`, port `6379`, пароль по умолчанию не задан.

---

## Переменные окружения

Сервер читает URL подключения из окружения (или `.env`). Шаблон —
`.env.example` в корне.

| Переменная    | По умолчанию (Docker) |
|---------------|------------------------|
| `DATABASE_URL` | `postgres://multigames:multigames@localhost:5432/multigames?sslmode=disable` |
| `REDIS_URL`    | `redis://localhost:6379/0` (пусто = Redis выключен) |
| `JWT_SECRET`   | задать в продакшене |

Скопируй `.env.example` в `.env` и `server/.env`, при необходимости измени
значения. Полный список переменных (почта, OAuth, Web Push, логи) — в
`.env.example` и [README.md](../README.md).
