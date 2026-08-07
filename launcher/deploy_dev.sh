#!/usr/bin/env bash
# Деплой текущего кода (или указанного worktree-корня) в Fly DEV.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/deploy.dev.env}"
FLY_CONFIG="$ROOT_DIR/fly.dev.toml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Файл конфигурации не найден: $ENV_FILE"
  echo "Создай его из шаблона: cp deploy.dev.env.example deploy.dev.env"
  exit 1
fi

if [[ ! -f "$FLY_CONFIG" ]]; then
  echo "Не найден $FLY_CONFIG"
  exit 1
fi

set -a
# shellcheck disable=SC1090
if ! source "$ENV_FILE"; then
  echo "Не удалось прочитать $ENV_FILE"
  echo 'FLY_API_TOKEN должен быть в кавычках: FLY_API_TOKEN="FlyV1 fm2_....="'
  exit 1
fi
set +a

required_vars=("FLY_API_TOKEN" "FLY_APP_NAME" "JWT_SECRET" "ADMIN_INIT_SECRET")
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Не задана обязательная переменная: $var_name"
    if [[ "$var_name" == "FLY_API_TOKEN" ]]; then
      echo 'Пример: FLY_API_TOKEN="FlyV1 fm2_....="'
    fi
    exit 1
  fi
done

if [[ "$FLY_APP_NAME" == "multigameszozu" ]]; then
  echo "Отказ: FLY_APP_NAME указывает на прод. Для DEV используй multigameszozu-dev."
  exit 1
fi

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

PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-https://${FLY_APP_NAME}.fly.dev}"
FRONTEND_URL="${FRONTEND_URL:-$PUBLIC_BASE_URL}"

echo "Используется DEV-приложение Fly: $FLY_APP_NAME"
echo "Конфиг: fly.dev.toml"
echo "Обновляю секреты..."

secret_args=(
  "JWT_SECRET=$JWT_SECRET"
  "ADMIN_INIT_SECRET=$ADMIN_INIT_SECRET"
  "PUBLIC_BASE_URL=$PUBLIC_BASE_URL"
  "FRONTEND_URL=$FRONTEND_URL"
)

optional_vars=(
  "REDIS_URL"
  "RESEND_API_KEY"
  "MAIL_FROM"
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

echo "Запускаю деплой DEV..."
(
  cd "$ROOT_DIR"
  # --depot=false: обход частых deadline_exceeded у Depot builder на тяжёлой сборке Flutter+Go.
  if ! "$FLY_BIN" deploy --config "$FLY_CONFIG" --app "$FLY_APP_NAME" --remote-only --depot=false --yes \
      --build-arg "BUILD_ID=$BUILD_ID"; then
    echo "Повтор деплоя без --depot=false..."
    "$FLY_BIN" deploy --config "$FLY_CONFIG" --app "$FLY_APP_NAME" --remote-only --yes \
      --build-arg "BUILD_ID=$BUILD_ID"
  fi
)

echo "DEV деплой завершен: https://$FLY_APP_NAME.fly.dev"
echo "Проверка: curl -sS https://$FLY_APP_NAME.fly.dev/api/start"
