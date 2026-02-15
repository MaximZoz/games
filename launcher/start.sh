#!/usr/bin/env bash
# MultiGames Launcher — запуск клиента и сервера (macOS / Linux)
# Запуск из корня проекта: ./launcher/start.sh

set -e
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

echo "MultiGames Launcher"
echo "Корень проекта: $PROJECT_ROOT"
echo ""

# Запуск сервера в фоне
echo "Запуск сервера (Go)..."
(cd "$PROJECT_ROOT/server" && go run ./cmd/server) &
SERVER_PID=$!

# Даём серверу время подняться
sleep 2

# Запуск клиента (по умолчанию Chrome для web)
echo "Запуск клиента (Flutter Web)..."
(cd "$PROJECT_ROOT/client" && flutter run -d chrome) &
CLIENT_PID=$!

echo ""
echo "Сервер PID: $SERVER_PID | Клиент PID: $CLIENT_PID"
echo "Остановка: kill $SERVER_PID $CLIENT_PID"
echo ""

# Ждём завершения (Ctrl+C остановит оба через trap)
trap "kill $SERVER_PID $CLIENT_PID 2>/dev/null; exit" INT TERM
wait
