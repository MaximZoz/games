# MultiGames: Flutter Web + Go API в одном образе для Fly.io
# Контекст сборки: корень репозитория (client + server)

# --- Stage 1: Flutter Web (same-origin API, пустой API_BASE) ---
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_build
WORKDIR /app

# Кэш pub get: слой пересобирается только при изменении pubspec
COPY client/pubspec.yaml client/pubspec.lock ./
RUN flutter pub get

# Остальной код — build web
COPY client/ .
RUN flutter build web --release --dart-define=API_BASE= --no-source-maps

# --- Stage 2: Go binary с встроенной статикой ---
FROM golang:1.24-alpine AS go_build
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
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

# --- Stage 3: Минимальный образ для запуска ---
FROM alpine:3.20
WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata

COPY --from=go_build /server ./server
COPY server/migrations ./migrations

ENV PORT=8080
EXPOSE 8080

CMD ["./server"]
