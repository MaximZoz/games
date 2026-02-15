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

Сервер подключается к ним по умолчанию (`localhost:5432`, `localhost:6379`). Чтобы задать свои URL — скопируйте `.env.example` в `.env` и измените `DATABASE_URL`, `REDIS_URL` и при необходимости `JWT_SECRET`.

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

### Запуск из IDE (Cursor / VS Code)

В `.vscode/` настроены:

- **Задача «Docker: Compose Up»** — поднимает Postgres и Redis (`docker compose up -d`).
- **Конфигурация «Go: Server»** — перед отладкой сервера автоматически запускает Docker.
- **«MultiGames: Server + Client»** — compound: сначала Docker, затем Go-сервер и Flutter Web.

Выбери нужную конфигурацию в списке Run and Debug и нажми Run.

---

## ✅ Реализовано

- **Docker Compose** — PostgreSQL 16 и Redis 7 с healthcheck и томами.
- **Миграции БД** — таблицы `users` и `sessions` (применяются при старте сервера).
- **Авторизация** — регистрация, вход, JWT (access + refresh), эндпоинт `GET /api/me`.
- **Клиент (Flutter)** — экраны входа и регистрации, Riverpod, go_router, сохранение токена в SharedPreferences.
- **Документация** — [API](docs/API.md), [базы данных (таблицы, Redis)](docs/DATABASE.md).
- **Тесты** — Go: `cd server && go test ./...`; Flutter: `cd client && flutter test`.

---

## 🎯 План

| Этап | Действие |
|------|----------|
| 1 | Развернуть Go на Railway (или Fly.io) и Postgres там же |
| 2 | Задеплоить Flutter Web на Vercel и настроить URL API |
| 3 | Сделать админку: смена паролей и удаление пользователей |

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
- [План GitHub](docs/GITHUB_PLAN.md)
- [Лаунчер (клиент + сервер)](launcher/README.md)
