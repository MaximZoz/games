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
├── docs/                   # Документация
│   ├── ARCHITECTURE.md
│   ├── GITHUB_PLAN.md
│   └── API.md
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

```bash
docker compose up -d
```

---

## 🎯 План интеграции с GitHub

| Этап | Действие |
|------|----------|
| 1 | Создать репозиторий на GitHub (публичный или приватный) |
| 2 | `git init` в корне проекта, добавить remote |
| 3 | Первый коммит: каркас + README |
| 4 | Настроить ветки: `main` (prod), `develop` (dev), `feature/*` |
| 5 | Добавить GitHub Actions: CI для Flutter и Go |
| 6 | Включить Issues, Projects для трекинга |
| 7 | (Опционально) GitHub Discussions для обсуждений |

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
- [План GitHub](docs/GITHUB_PLAN.md)
