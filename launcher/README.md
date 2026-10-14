# 🚀 Лаунчер MultiGames

Скрипты для одновременного запуска **клиента** (Flutter) и **сервера** (Go) из корня проекта.

---

## Требования

- Установлены [Flutter](https://flutter.dev) и [Go](https://go.dev)
- В корне проекта выполнено:
  - `cd client && flutter create .` (если ещё не созданы платформы)
  - `cd client && flutter pub get`
  - `cd server && go mod download`

---

## Windows (PowerShell)

Из **корня проекта**:

```powershell
.\launcher\start.ps1
```

Откроются **два окна PowerShell**:
1. **Сервер** — Go API (остановка: закрыть окно или Ctrl+C)
2. **Клиент** — Flutter Web в Chrome (остановка: закрыть окно или Ctrl+C)

**Перезапуск (применить изменения в коде):**

```powershell
.\launcher\restart.ps1
```

Скрипт завершит сервер на порту 8080 и заново запустит оба окна (сервер и клиент). Старые окна закройте вручную. Для клиента можно также использовать **Hot Restart** — в окне с Flutter нажать **R**.

**Запуск тестов (Go + Flutter):**

```powershell
.\launcher\test.ps1
```

Выполняются `go test ./...` в server и `flutter test` в client (если есть папка `test`). При ошибке в любом из шагов скрипт завершится с кодом 1.

**Деплой на Fly из конфига:**

```powershell
.\launcher\deploy_cursor.ps1
```

Скрипт читает `deploy.cursor.env` из корня проекта, обновляет секреты и запускает `fly deploy --remote-only --yes`.

**Деплой именно ветки `develop` (даже если ты на другой ветке):**

```powershell
.\launcher\deploy_develop.ps1
```

Скрипт подтягивает `origin/develop`, создаёт временный worktree и деплоит именно эту ветку.

**Создать / задеплоить отдельный Fly DEV** (`multigameszozu-dev`):

```powershell
Copy-Item deploy.dev.env.example deploy.dev.env
.\launcher\setup_fly_dev.ps1
.\launcher\deploy_dev.ps1
```

Если выполнение скриптов запрещено политикой:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## macOS / Linux

Из **корня проекта**:

```bash
chmod +x launcher/start.sh
./launcher/start.sh
```

Сервер и клиент запустятся в **текущем терминале** (сервер в фоне, клиент в фоне). Остановка: **Ctrl+C** (остановит оба процесса).

**Запуск тестов:**

```bash
chmod +x launcher/test.sh
./launcher/test.sh
```

**Деплой на Fly из конфига:**

```bash
chmod +x launcher/deploy_cursor.sh
./launcher/deploy_cursor.sh
```

Скрипт читает `deploy.cursor.env` из корня проекта, обновляет секреты и запускает `fly deploy --remote-only --yes`.

**Деплой именно ветки `develop` (даже если ты на другой ветке):**

```bash
chmod +x launcher/deploy_develop.sh
./launcher/deploy_develop.sh
```

Скрипт подтягивает `origin/develop`, создаёт временный worktree и деплоит именно эту ветку.

**Создать / задеплоить отдельный Fly DEV** (`multigameszozu-dev`):

```bash
cp deploy.dev.env.example deploy.dev.env
chmod +x launcher/setup_fly_dev.sh launcher/deploy_dev.sh
./launcher/setup_fly_dev.sh
./launcher/deploy_dev.sh
```

Прод остаётся в `fly.toml` / `deploy.cursor.env`. DEV — `fly.dev.toml` / `deploy.dev.env`.  
Автодеплой: push в `develop` → DEV, push в `main` → прод (см. `.github/workflows/deploy.yml`).
CI (analyze/test): автоматически при влитии в `main` (`.github/workflows/ci.yml`).  
Подробнее: [docs/DEPLOY_FLY_DEV.md](../docs/DEPLOY_FLY_DEV.md).

**Внешний Redis (лобби переживают `fly deploy`):**

```bash
chmod +x launcher/setup_fly_redis.sh
./launcher/setup_fly_redis.sh deploy.cursor.env   # прод
./launcher/setup_fly_redis.sh deploy.dev.env      # DEV
```

```powershell
.\launcher\setup_fly_redis.ps1 deploy.cursor.env
.\launcher\setup_fly_redis.ps1 deploy.dev.env
```

Без этого Redis крутится внутри app-контейнера без persistence и после деплоя
сбрасывает лобби/матчмейкинг/активные партии. См. [docs/DEPLOY_FLY.md](../docs/DEPLOY_FLY.md).

---

## Варианты запуска клиента

По умолчанию клиент запускается как **Web** (`flutter run -d chrome`).

Чтобы запускать другую платформу вручную:

- **Windows (Desktop):** в окне клиента замените команду на  
  `flutter run -d windows`
- **Android:** `flutter run -d android --flavor dev` (или `--flavor prod`) — см. `docs/ANDROID_PLAY_INTERNAL.md`
- **iOS:** `flutter run -d ios --flavor dev` (или `--flavor prod`) — см. `docs/IOS_TESTFLIGHT.md`

Или отредактируйте в скрипте строку с `flutter run -d ...` под нужное устройство.

---

## Структура

```
launcher/

Windows
├── start.ps1   # Windows — запуск
├── restart.ps1 # Windows — перезапуск (применить изменения)
├── test.ps1    # Windows — тесты Go + Flutter
├── deploy_cursor.ps1 # Windows — деплой на Fly из deploy.cursor.env
├── deploy_develop.ps1 # Windows — деплой именно origin/develop
├── setup_fly_redis.ps1 # Windows — Upstash Redis + REDIS_URL (лобби после deploy)

macOS / Linux
├── start.sh    # macOS / Linux
├── test.sh     # macOS / Linux — тесты
├── deploy_cursor.sh # macOS / Linux — деплой на Fly из deploy.cursor.env
├── deploy_develop.sh # macOS / Linux — деплой именно origin/develop
├── setup_fly_redis.sh # macOS / Linux — Upstash Redis + REDIS_URL
└── README.md   # этот файл
```

---

## См. также

- [Быстрый старт](../README.md#-быстрый-старт) в корневом README
- [База данных](../README.md) — при необходимости: `docker compose up -d` из корня
