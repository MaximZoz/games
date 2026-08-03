#!/bin/sh
set -eu

# Локальный Redis в том же контейнере (лобби/матчмейкинг/realtime pubsub).
# Если REDIS_URL уже указывает на внешний Redis — всё равно поднимаем локальный
# только когда хост localhost/127.0.0.1; иначе внешний URL используется как есть.
REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379/0}"
export REDIS_URL

need_local=0
case "$REDIS_URL" in
  redis://localhost:*|redis://127.0.0.1:*|redis://\[::1\]:*|rediss://localhost:*|rediss://127.0.0.1:*)
    need_local=1
    ;;
  "")
    REDIS_URL="redis://127.0.0.1:6379/0"
    export REDIS_URL
    need_local=1
    ;;
esac

if [ "$need_local" = "1" ]; then
  redis-server \
    --daemonize yes \
    --bind 127.0.0.1 \
    --port 6379 \
    --protected-mode yes \
    --save "" \
    --appendonly no \
    --dir /tmp
  # Дождаться готовности (до ~3с).
  i=0
  while [ "$i" -lt 30 ]; do
    if redis-cli -h 127.0.0.1 -p 6379 ping >/dev/null 2>&1; then
      break
    fi
    i=$((i + 1))
    sleep 0.1
  done
fi

exec ./server
