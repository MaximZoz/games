#!/usr/bin/env bash
# Создаёт внешний Upstash Redis (через Fly) и прописывает REDIS_URL в секреты app.
#
# Зачем: локальный Redis в контейнере приложения эфемерный (--save "", /tmp).
# После fly deploy лобби/матчмейкинг/активные партии сбрасываются.
# Внешний Upstash Redis переживает деплой приложения.
#
# Примеры:
#   ./launcher/setup_fly_redis.sh deploy.dev.env
#   ./launcher/setup_fly_redis.sh deploy.cursor.env
#   FLY_APP_NAME=multigameszozu FLY_API_TOKEN=... ./launcher/setup_fly_redis.sh
#
# Опционально в env-файле:
#   FLY_REDIS_NAME=multigameszozu-redis   # имя Upstash DB (по умолчанию <app>-redis)
#   FLY_REGION=ams
#   FLY_REDIS_PLAN=pay-as-you-go          # или free / и т.д. (fly redis plans)
#   FLY_ORG=personal
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-}"

if [[ -n "$ENV_FILE" ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    # relative to repo root
    if [[ -f "$ROOT_DIR/$ENV_FILE" ]]; then
      ENV_FILE="$ROOT_DIR/$ENV_FILE"
    else
      echo "Файл конфигурации не найден: $ENV_FILE"
      exit 1
    fi
  fi
  set -a
  # shellcheck disable=SC1090
  if ! source "$ENV_FILE"; then
    echo "Не удалось прочитать $ENV_FILE"
    echo 'Проверь FLY_API_TOKEN в кавычках: FLY_API_TOKEN="FlyV1 ...="'
    exit 1
  fi
  set +a
fi

required_vars=("FLY_API_TOKEN" "FLY_APP_NAME")
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Не задана обязательная переменная: $var_name"
    echo "Передай env-файл или экспортируй переменные."
    echo "Пример: ./launcher/setup_fly_redis.sh deploy.dev.env"
    exit 1
  fi
done

FLY_REGION="${FLY_REGION:-ams}"
FLY_REDIS_NAME="${FLY_REDIS_NAME:-${FLY_APP_NAME}-redis}"
FLY_REDIS_PLAN="${FLY_REDIS_PLAN:-pay-as-you-go}"
FLY_ORG="${FLY_ORG:-}"

if command -v fly >/dev/null 2>&1; then
  FLY_BIN="fly"
elif command -v flyctl >/dev/null 2>&1; then
  FLY_BIN="flyctl"
elif [[ -x "$HOME/.fly/bin/flyctl" ]]; then
  FLY_BIN="$HOME/.fly/bin/flyctl"
else
  echo "Не найден fly/flyctl. Установи: https://fly.io/docs/hands-on/install-flyctl/"
  exit 1
fi

export FLY_API_TOKEN

echo "==> App:        $FLY_APP_NAME"
echo "==> Redis name: $FLY_REDIS_NAME"
echo "==> Region:     $FLY_REGION"
echo "==> Plan:       $FLY_REDIS_PLAN"

echo "Проверяю доступ Fly..."
whoami_out="$("$FLY_BIN" auth whoami 2>&1 || true)"
echo "$whoami_out"

if ! "$FLY_BIN" status --app "$FLY_APP_NAME" >/dev/null 2>&1; then
  echo
  echo "Приложение $FLY_APP_NAME не найдено или токен не имеет к нему доступа."
  echo "Список app, которые видит этот FLY_API_TOKEN:"
  "$FLY_BIN" apps list 2>&1 || true
  echo
  echo "Что сделать:"
  echo "  1) Если DEV ещё не создавался:"
  echo "       ./launcher/setup_fly_dev.sh deploy.dev.env"
  echo "       ./launcher/setup_fly_redis.sh deploy.dev.env"
  echo "  2) Если app есть, но токен узкий — сделай org/deploy token с доступом к app:"
  echo "       fly tokens create deploy -a $FLY_APP_NAME -x 72h -n redis-setup"
  echo "     и обнови FLY_API_TOKEN в deploy.dev.env (в кавычках)."
  echo "  3) Проверка вручную:"
  echo "       fly status --app $FLY_APP_NAME"
  exit 1
fi

redis_exists=0
if "$FLY_BIN" redis status "$FLY_REDIS_NAME" >/dev/null 2>&1; then
  redis_exists=1
fi

if [[ "$redis_exists" -eq 0 ]]; then
  echo "Создаю Upstash Redis: $FLY_REDIS_NAME ..."
  create_args=(
    redis create
    --name "$FLY_REDIS_NAME"
    --region "$FLY_REGION"
    --plan "$FLY_REDIS_PLAN"
    --no-replicas
    --enable-eviction
  )
  if [[ -n "$FLY_ORG" ]]; then
    create_args+=(--org "$FLY_ORG")
  fi
  "$FLY_BIN" "${create_args[@]}"
else
  echo "Redis $FLY_REDIS_NAME уже есть — пропускаю create."
fi

echo "Читаю Private URL..."
status_out="$("$FLY_BIN" redis status "$FLY_REDIS_NAME" 2>&1 || true)"
echo "$status_out"

# Достаём redis:// или rediss:// из вывода status.
REDIS_URL="$(printf '%s\n' "$status_out" | grep -Eo 'rediss?://[^[:space:]]+' | head -n 1 || true)"
if [[ -z "$REDIS_URL" ]]; then
  echo "Не удалось вытащить REDIS_URL из 'fly redis status $FLY_REDIS_NAME'."
  echo "Скопируй Private URL вручную и выполни:"
  echo "  fly secrets set REDIS_URL='redis://...' --app $FLY_APP_NAME"
  exit 1
fi

# Маскируем пароль в логе.
masked="$(printf '%s' "$REDIS_URL" | sed -E 's#(rediss?://[^:/@]*:)[^@]*(@)#\1***\2#')"
echo "REDIS_URL: $masked"

echo "Ставлю секрет REDIS_URL на $FLY_APP_NAME ..."
"$FLY_BIN" secrets set "REDIS_URL=$REDIS_URL" --app "$FLY_APP_NAME"

echo
echo "Готово. После ротации секретов Fly перезапустит машины app."
echo "Локальный redis-server в контейнере больше НЕ поднимется (REDIS_URL не localhost)."
echo
echo "Проверка:"
echo "  fly secrets list --app $FLY_APP_NAME | grep REDIS"
echo "  # создать лобби → fly deploy → лобби должно остаться"
echo
echo "Важно: это Upstash Redis вне app-контейнера — он переживает деплой приложения."
