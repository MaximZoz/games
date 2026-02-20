# Базы данных: PostgreSQL и Redis

В проекте используются **PostgreSQL** (таблицы, пользователи, сессии) и **Redis** (кеш, очереди — ключи и значения). Оба сервиса запускаются через Docker Compose.

---

## Docker Compose

Контейнеры описаны в корне проекта в `docker-compose.yml`.

| Сервис    | Контейнер           | Порт  | Назначение        |
|-----------|---------------------|-------|-------------------|
| PostgreSQL | `multigames-postgres` | 5432 | Основная БД       |
| Redis     | `multigames-redis`  | 6379  | Кеш, сессии       |

Поднять контейнеры из корня проекта:

```bash
docker compose up -d
```

Остановить:

```bash
docker compose down
```

---

## PostgreSQL: таблицы

В PostgreSQL хранятся **таблицы** (пользователи, сессии). Миграции лежат в `server/migrations/` и применяются при старте Go-сервера.

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

Используй их в DBeaver, pgAdmin, DataGrip и т.п.

### Текущие таблицы

- **users** — пользователи (id, email, password_hash, display_name, created_at, updated_at)
- **sessions** — сессии/refresh-токены (id, user_id, refresh_token_hash, expires_at, created_at)
- **app_logs** — журнал методов фронта и бэка после импорта из файла логов (event_id, event_time, source, method_name, http_method, path, status_code, duration_ms, user_id, metadata, raw_payload, created_at)

---

## Redis: ключи (таблиц нет)

В Redis **нет таблиц** — только ключи и значения (строки, хеши, списки, множества и т.д.). Сервер использует Redis для кеша или очередей по мере необходимости.

### Подключение к Redis из контейнера (redis-cli)

```bash
docker exec -it multigames-redis redis-cli
```

В консоли:

| Команда        | Описание                |
|----------------|------------------------|
| `KEYS *`       | Все ключи              |
| `KEYS шаблон*` | Ключи по шаблону       |
| `GET ключ`     | Значение (строка)      |
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

Сервер читает URL подключения из окружения (или `.env`). Пример в корне: `.env.example`.

| Переменная    | По умолчанию (Docker) |
|---------------|------------------------|
| `DATABASE_URL` | `postgres://multigames:multigames@localhost:5432/multigames?sslmode=disable` |
| `REDIS_URL`    | `redis://localhost:6379/0` |
| `JWT_SECRET`   | задать в продакшене |

Скопируй `.env.example` в `.env` и при необходимости измени значения.
