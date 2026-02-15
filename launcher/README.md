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
****
Скрипт завершит сервер на порту 8080 и заново запустит оба окна (сервер и клиент). Старые окна закройте вручную. Для клиента можно также использовать **Hot Restart** — в окне с Flutter нажать **R**.

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
├── start.ps1   # Windows — запуск
├── restart.ps1 # Windows — перезапуск (применить изменения)
├── start.sh    # macOS / Linux
└── README.md   # этот файл
```

---

## См. также

- [Быстрый старт](../README.md#-быстрый-старт) в корневом README
- [База данных](../README.md) — при необходимости: `docker compose up -d` из корня
