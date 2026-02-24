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

---

## Варианты запуска клиента

По умолчанию клиент запускается как **Web** (`flutter run -d chrome`).

Чтобы запускать другую платформу вручную:

- **Windows (Desktop):** в окне клиента замените команду на  
  `flutter run -d windows`
- **Android:** `flutter run -d android`
- **iOS:** `flutter run -d ios`

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

macOS / Linux
├── start.sh    # macOS / Linux
├── test.sh     # macOS / Linux — тесты
├── deploy_cursor.sh # macOS / Linux — деплой на Fly из deploy.cursor.env
├── deploy_develop.sh # macOS / Linux — деплой именно origin/develop
└── README.md   # этот файл
```

---

## См. также

- [Быстрый старт](../README.md#-быстрый-старт) в корневом README
- [База данных](../README.md) — при необходимости: `docker compose up -d` из корня
