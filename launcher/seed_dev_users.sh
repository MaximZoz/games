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

(
  cd "$ROOT_DIR/server"
  go run ./cmd/seed_dev_users >"$SQL_FILE"
)

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
