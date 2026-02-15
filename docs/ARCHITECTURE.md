# 🏗 Архитектура проекта

## Обзор

Проект разделён на два основных модуля: **client** (Flutter) и **server** (Go).

---

## Client (Flutter)

```
client/
├── lib/
│   ├── core/           # Конфиг, роутинг, утилиты, платформа
│   ├── features/       # Игры, рейтинг, профиль
│   ├── shared/         # Общие виджеты, анимации
│   └── main.dart
├── assets/             # Изображения, Rive, Lottie
└── pubspec.yaml
```

---

## Server (Go)

```
server/
├── cmd/
│   └── server/         # Entry point
├── internal/
│   ├── api/            # HTTP handlers
│   ├── game/           # Логика игр
│   ├── rating/         # ELO, matchmaking
│   └── ws/             # WebSocket hub
├── pkg/                # Публичные пакеты (если нужны)
└── go.mod
```

---

## Связь клиент ↔ сервер

- **REST** — авторизация, профиль, рейтинг, матчмейкинг
- **WebSocket** — состояние игры в реальном времени
