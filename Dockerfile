# MultiGames: Flutter Web + Go API в одном образе для Fly.io
# Контекст сборки: корень репозитория (client + server)
# BUILD_ID — короткий git sha (передаётся --build-arg BUILD_ID=...).

# --- Stage 1: Flutter Web (same-origin API, пустой API_BASE) ---
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_build
ARG BUILD_ID=dev
WORKDIR /app

# Кэш pub get: слой пересобирается только при изменении pubspec.
# pubspec.* — чтобы сборка не падала, если локально нет lock (gitignore / забыли pull).
# В репозитории lock всё равно должен быть закоммичен для воспроизводимых сборок.
COPY client/pubspec.* ./
RUN flutter pub get

# Остальной код — build web
COPY client/ .
RUN flutter build web --release \
  --dart-define=API_BASE= \
  --dart-define=BUILD_ID=${BUILD_ID} \
  --no-source-maps

# --- Stage 2: Go binary с встроенной статикой ---
FROM golang:1.24-alpine AS go_build
ARG BUILD_ID=dev
WORKDIR /app

# Кэш go mod: слой пересобирается только при изменении go.mod/go.sum
COPY server/go.mod server/go.sum ./server/
WORKDIR /app/server
RUN go mod download

# Исходники и статика
WORKDIR /app
COPY server/ ./server/
# Подставляем собранный Flutter web в каталог для embed
COPY --from=flutter_build /app/build/web ./server/cmd/server/web/

WORKDIR /app/server
RUN CGO_ENABLED=0 GOOS=linux go build \
  -ldflags="-s -w -X main.buildID=${BUILD_ID}" \
  -o /server ./cmd/server

# --- Stage 3: Минимальный образ для запуска ---
FROM alpine:3.20
WORKDIR /app

# redis: лобби/матчмейкинг живут в Redis; при REDIS_URL=localhost
# поднимаем redis-server в том же контейнере (см. docker-entrypoint.sh).
RUN apk add --no-cache ca-certificates tzdata redis

COPY --from=go_build /server ./server
COPY server/migrations ./migrations
COPY scripts/docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

ENV PORT=8080
ENV REDIS_URL=redis://127.0.0.1:6379/0
EXPOSE 8080

CMD ["./docker-entrypoint.sh"]
