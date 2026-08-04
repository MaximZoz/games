#!/usr/bin/env bash
# Сидирует DEV Postgres: max591018@gmail.com → admin, player1..player20.
# Только для multigameszozu-dev. НЕ запускать против прода.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/deploy.dev.env}"

FLY_APP_NAME="${FLY_APP_NAME:-multigameszozu-dev}"
FLY_DEV_DB_NAME="${FLY_DEV_DB_NAME:-multigameszozu-dev-db}"
FLY_DEV_DB_DATABASE="${FLY_DEV_DB_DATABASE:-multigameszozu_dev}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ "${FLY_APP_NAME}" == "multigameszozu" || "${FLY_DEV_DB_NAME}" == "multigameszozu-db" ]]; then
  echo "Отказ: скрипт только для DEV, не для прода."
  exit 1
fi

if command -v fly >/dev/null 2>&1; then
  FLY_BIN="fly"
elif command -v flyctl >/dev/null 2>&1; then
  FLY_BIN="flyctl"
elif [[ -x "$HOME/.fly/bin/flyctl" ]]; then
  FLY_BIN="$HOME/.fly/bin/flyctl"
else
  echo "Не найден fly/flyctl"
  exit 1
fi

if [[ -n "${FLY_API_TOKEN:-}" ]]; then
  export FLY_API_TOKEN
fi

echo "Генерирую SQL (bcrypt)..."
SQL_FILE="$(mktemp)"
cleanup() { rm -f "$SQL_FILE"; }
trap cleanup EXIT

resolve_go() {
  if command -v go >/dev/null 2>&1; then
    command -v go
    return 0
  fi
  for candidate in \
    /usr/local/go/bin/go \
    "$HOME/go/bin/go" \
    /usr/lib/go-1.24/bin/go \
    /usr/lib/go/bin/go; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

generate_sql() {
  local go_bin=""
  if go_bin="$(resolve_go)"; then
    echo "Использую Go: $go_bin"
    (
      cd "$ROOT_DIR/server"
      "$go_bin" run ./cmd/seed_dev_users
    ) >"$SQL_FILE"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    echo "Go не найден локально — генерирую SQL через Docker (golang:1.24-alpine)..."
    docker run --rm \
      -v "$ROOT_DIR/server:/app" \
      -w /app \
      golang:1.24-alpine \
      go run ./cmd/seed_dev_users >"$SQL_FILE"
    return 0
  fi

  echo "Не найден Go и Docker."
  echo "Установи Go: https://go.dev/dl/  или Docker, затем повтори."
  echo "Быстрый вариант в WSL:"
  echo "  sudo apt-get update && sudo apt-get install -y golang-go"
  echo "  ./launcher/seed_dev_users.sh"
  return 1
}

generate_sql

echo "Применяю к Postgres DEV: $FLY_DEV_DB_NAME / db=$FLY_DEV_DB_DATABASE"
echo "App: $FLY_APP_NAME"
echo

# fly postgres connect открывает psql; кормим SQL через stdin.
"$FLY_BIN" postgres connect \
  --app "$FLY_DEV_DB_NAME" \
  --database "$FLY_DEV_DB_DATABASE" <"$SQL_FILE"

echo
echo "Готово."
echo "Админ: max591018@gmail.com (если не было — создан с паролем admin-dev-temp; лучше войти через Google)"
echo "Тестовые: player1@player.com / player1 ... player20@player.com / player20"
echo "URL: https://$FLY_APP_NAME.fly.dev/login"
