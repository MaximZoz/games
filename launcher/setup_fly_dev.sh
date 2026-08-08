#!/usr/bin/env bash
# Создаёт на Fly отдельное DEV-окружение (приложение + Postgres + секреты),
# по форме как прод, но с другими именами/БД/секретами.
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
  echo "Проверь строку FLY_API_TOKEN: значение должно быть в кавычках, одной строкой:"
  echo '  FLY_API_TOKEN="FlyV1 fm2_....="'
  exit 1
fi
set +a

required_vars=("FLY_API_TOKEN" "FLY_APP_NAME" "FLY_DEV_DB_NAME" "JWT_SECRET" "ADMIN_INIT_SECRET")
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Не задана обязательная переменная: $var_name"
    if [[ "$var_name" == "FLY_API_TOKEN" ]]; then
      echo 'Пример: FLY_API_TOKEN="FlyV1 fm2_....="'
    fi
    exit 1
  fi
done

FLY_REGION="${FLY_REGION:-ams}"
PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-https://${FLY_APP_NAME}.fly.dev}"
FRONTEND_URL="${FRONTEND_URL:-$PUBLIC_BASE_URL}"

if [[ "$FLY_APP_NAME" == "multigameszozu" ]]; then
  echo "Отказ: FLY_APP_NAME указывает на прод (multigameszozu). Для DEV используй multigameszozu-dev."
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

echo "==> DEV app: $FLY_APP_NAME"
echo "==> DEV db:  $FLY_DEV_DB_NAME"
echo "==> region:  $FLY_REGION"

app_exists=0
if "$FLY_BIN" status --app "$FLY_APP_NAME" >/dev/null 2>&1; then
  app_exists=1
fi

if [[ "$app_exists" -eq 0 ]]; then
  echo "Создаю приложение $FLY_APP_NAME..."
  "$FLY_BIN" apps create "$FLY_APP_NAME" --org personal 2>/dev/null \
    || "$FLY_BIN" apps create "$FLY_APP_NAME"
else
  echo "Приложение $FLY_APP_NAME уже есть — пропускаю create."
fi

db_exists=0
if "$FLY_BIN" status --app "$FLY_DEV_DB_NAME" >/dev/null 2>&1; then
  db_exists=1
fi

if [[ "$db_exists" -eq 0 ]]; then
  echo "Создаю Postgres $FLY_DEV_DB_NAME (это займёт несколько минут)..."
  # У fly postgres create нет флага --yes; при полных флагах идёт без лишних вопросов.
  "$FLY_BIN" postgres create \
    --name "$FLY_DEV_DB_NAME" \
    --region "$FLY_REGION" \
    --initial-cluster-size 1 \
    --vm-size shared-cpu-1x \
    --volume-size 1
else
  echo "Postgres $FLY_DEV_DB_NAME уже есть — пропускаю create."
fi

echo "Привязываю Postgres к приложению (DATABASE_URL)..."
# Повторный attach безопаснее с || true: если уже привязан — Fly сообщит об этом.
"$FLY_BIN" postgres attach "$FLY_DEV_DB_NAME" --app "$FLY_APP_NAME" --yes \
  || echo "Attach пропущен/уже выполнен — проверь: fly secrets list --app $FLY_APP_NAME"

echo "Ставлю секреты DEV..."
secret_args=(
  "JWT_SECRET=$JWT_SECRET"
  "ADMIN_INIT_SECRET=$ADMIN_INIT_SECRET"
  "PUBLIC_BASE_URL=$PUBLIC_BASE_URL"
  "FRONTEND_URL=$FRONTEND_URL"
  "APP_LOG_ENABLED=${APP_LOG_ENABLED:-false}"
)

optional_vars=(
  "REDIS_URL"
  "RESEND_API_KEY"
  "MAIL_FROM"
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

echo
echo "DEV-окружение готово (ресурсы созданы, секреты выставлены)."
echo "Дальше задеплой код:"
echo "  ./launcher/deploy_dev.sh"
echo "URL: $PUBLIC_BASE_URL"
echo
echo "Важно: это чистая БД (миграции применятся при старте приложения)."
echo "Данные прода НЕ копируются. Чтобы склонировать данные — см. docs/DEPLOY_FLY_DEV.md"
