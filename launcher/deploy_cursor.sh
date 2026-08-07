#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/deploy.cursor.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Файл конфигурации не найден: $ENV_FILE"
  echo "Создай его из шаблона: cp deploy.cursor.env.example deploy.cursor.env"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

required_vars=("FLY_API_TOKEN" "FLY_APP_NAME" "JWT_SECRET" "ADMIN_INIT_SECRET")
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Не задана обязательная переменная: $var_name"
    exit 1
  fi
done

if command -v fly >/dev/null 2>&1; then
  FLY_BIN="fly"
elif command -v flyctl >/dev/null 2>&1; then
  FLY_BIN="flyctl"
elif [[ -x "$HOME/.fly/bin/flyctl" ]]; then
  FLY_BIN="$HOME/.fly/bin/flyctl"
else
  echo "Не найден fly/flyctl. Установи Fly CLI: https://fly.io/docs/hands-on/install-flyctl/"
  exit 1
fi

export FLY_API_TOKEN

echo "Используется приложение Fly: $FLY_APP_NAME"
echo "Обновляю секреты..."

secret_args=(
  "JWT_SECRET=$JWT_SECRET"
  "ADMIN_INIT_SECRET=$ADMIN_INIT_SECRET"
)

optional_vars=(
  "REDIS_URL"
  "APP_LOG_ENABLED"
  "APP_LOG_FILE"
  "APP_LOG_STATE_FILE"
  "APP_LOG_SYNC_INTERVAL_SECONDS"
  "APP_LOG_RETENTION_DAYS"
  "APP_LOG_CLEANUP_INTERVAL_SECONDS"
)
for var_name in "${optional_vars[@]}"; do
  value="${!var_name:-}"
  if [[ -n "$value" ]]; then
    secret_args+=("$var_name=$value")
  fi
done

"$FLY_BIN" secrets set "${secret_args[@]}" --app "$FLY_APP_NAME"

BUILD_ID="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
echo "BUILD_ID=$BUILD_ID"

echo "Запускаю деплой..."
"$FLY_BIN" deploy --app "$FLY_APP_NAME" --remote-only --yes \
  --build-arg "BUILD_ID=$BUILD_ID"

echo "Деплой завершен: https://$FLY_APP_NAME.fly.dev"
