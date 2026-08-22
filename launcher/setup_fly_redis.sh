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
#   # прод без env-файла, если уже fly auth login:
#   FLY_APP_NAME=multigameszozu ./launcher/setup_fly_redis.sh
#
# Опционально в env-файле:
#   FLY_REDIS_NAME=multigameszozu-redis   # имя Upstash DB (по умолчанию <app>-redis)
#   FLY_REGION=ams
#   FLY_REDIS_PLAN=          # по умолчанию НЕ передаём --plan (Fly возьмёт default).
#                            # Список: fly redis plans
#   FLY_ORG=personal
#   FLY_API_TOKEN=...        # необязателен, если уже выполнен fly auth login
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-}"

# Если токен уже в окружении — не даём env-файлу его затереть битым значением.
PRESET_FLY_API_TOKEN="${FLY_API_TOKEN:-}"

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

if [[ -n "$PRESET_FLY_API_TOKEN" ]]; then
  FLY_API_TOKEN="$PRESET_FLY_API_TOKEN"
  export FLY_API_TOKEN
fi

if [[ -z "${FLY_APP_NAME:-}" ]]; then
  echo "Не задана обязательная переменная: FLY_APP_NAME"
  echo "Пример: FLY_APP_NAME=multigameszozu ./launcher/setup_fly_redis.sh"
  echo "   или: ./launcher/setup_fly_redis.sh deploy.cursor.env"
  exit 1
fi

FLY_REGION="${FLY_REGION:-ams}"
FLY_REDIS_NAME="${FLY_REDIS_NAME:-${FLY_APP_NAME}-redis}"
# Пусто = не передавать --plan, flyctl сам выберет актуальный default.
FLY_REDIS_PLAN="${FLY_REDIS_PLAN:-}"
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
echo "==> Plan:       ${FLY_REDIS_PLAN:-<default>}"

echo "Проверяю доступ Fly..."
whoami_out="$("$FLY_BIN" auth whoami 2>&1 || true)"
echo "$whoami_out"
if ! printf '%s\n' "$whoami_out" | grep -Eqi '@|user|email|Macaroon|authenticated'; then
  # whoami обычно печатает email; если явная ошибка auth — подсказка.
  if printf '%s\n' "$whoami_out" | grep -qi 'must be authenticated\|no access token\|not authenticated'; then
    echo
    echo "Нет рабочей Fly-аутентификации."
    echo "  unset FLY_API_TOKEN"
    echo "  fly auth login"
    echo "  # либо задай рабочий FLY_API_TOKEN и НЕ дай env-файлу его затереть"
    exit 1
  fi
fi

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
  echo "(ProdPack → No автоматически; $200/mo addon не нужен)"
  create_args=(
    redis create
    --name "$FLY_REDIS_NAME"
    --region "$FLY_REGION"
    --no-replicas
    --enable-eviction
  )
  if [[ -n "$FLY_REDIS_PLAN" ]]; then
    create_args+=(--plan "$FLY_REDIS_PLAN")
  fi
  if [[ -n "$FLY_ORG" ]]; then
    create_args+=(--org "$FLY_ORG")
  fi
  # Интерактивный вопрос ProdPack: всегда отвечаем No.
  if ! printf 'n\n' | "$FLY_BIN" "${create_args[@]}"; then
    echo "fly redis create не удался. Попробуй вручную:"
    echo "  unset FLY_API_TOKEN"
    echo "  fly auth login"
    echo "  printf 'n\\n' | fly redis create --name $FLY_REDIS_NAME --region $FLY_REGION --no-replicas --enable-eviction"
    exit 1
  fi
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
