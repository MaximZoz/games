# AGENTS.md

## Cursor Cloud specific instructions

### Architecture

MultiGames is a monorepo with two services:
- **Go API Server** (`server/`) — REST + WebSocket API on port 8080
- **Flutter Web Client** (`client/`) — SPA that talks to the API

Infrastructure: PostgreSQL 16 (required), Redis 7 (optional, graceful degradation).

### Prerequisites (system-level, installed once)

- Go 1.24+ at `/usr/local/go/bin`
- Flutter 3.27.4 at `/opt/flutter-sdk/bin`
- Docker (for PostgreSQL/Redis via `docker-compose.yml`)
- `fuse-overlayfs` + `iptables-legacy` for nested Docker
- PATH must include both: `export PATH="/usr/local/go/bin:/opt/flutter-sdk/bin:$PATH"`

### Starting infrastructure

```bash
sudo dockerd &>/tmp/dockerd.log &   # if Docker daemon not running
sudo docker compose up -d            # starts Postgres + Redis
```

### Environment file

Copy `.env.example` to both `.env` and `server/.env`. The Go server reads from `server/.env` or the repo root.

### Running services

See `README.md` "Быстрый старт" section. Summary:
- **Server:** `cd server && go run ./cmd/server` (port 8080, auto-applies migrations)
- **Client:** `cd client && flutter run -d chrome` (connects to `http://localhost:8080`)

### Tests and lint

See `README.md` "Тесты и проверки" section. Summary:
- **Go:** `cd server && go test ./...` and `go vet ./...`
- **Flutter:** `cd client && flutter analyze --no-fatal-infos` and `flutter test`
- Combined: `./launcher/test.sh`

### Known issues

None known at this time. The client and server build and analyze cleanly
(`flutter analyze --no-fatal-infos`, `go build ./...`). If `flutter analyze`
shows a few `info`-level `deprecated_member_use` hints in
`admin_screen.dart` (`DropdownButtonFormField` `value:`) or
`profile_screen.dart` (`Matrix4.translate`), those are non-fatal and
suppressed by `--no-fatal-infos`; they are forward-looking lints, not build
errors.

> **Historical note.** Earlier versions of this file listed 3 hard
> compilation errors (`DropdownButtonFormField.initialValue`,
> `Matrix4.translateByDouble()`). They have since been fixed in the codebase
> (see `admin_screen.dart`, `profile_screen.dart`).

### Gotchas

- Docker daemon must be started manually with `sudo dockerd` — it does not auto-start in this environment.
- The Go server must find `.env` in `server/` or the repo root — copy `.env.example` to both locations.
- Redis is optional; the server logs a warning but continues without it.
  Without Redis, games (`/api/games/*`), game matchmaking and the
  cross-instance realtime broadcaster are disabled; everything else (auth,
  friends, chats, shop, coins, admin, presence) keeps working.
- The Go server embeds `client/build/web/` for production — but in dev mode, client and server run separately.
- Web Push (PWA notifications) is off until `VAPID_PUBLIC_KEY` /
  `VAPID_PRIVATE_KEY` are set; otherwise the server starts with a warning.
- Android closed-app push needs `FCM_SERVICE_ACCOUNT_JSON` on Fly and
  `google-services.json` in the Android build (see
  `docs/ANDROID_PLAY_INTERNAL.md` §9).
- Email verification / password reset require a mailer (Resend via
  `RESEND_API_KEY`, or SMTP via `SMTP_*`). Without it, verification codes
  are only logged server-side.
- OAuth login buttons (Google / Apple / Yandex / VK) are hidden unless the
  respective `*_CLIENT_ID` / `*_CLIENT_SECRET` env vars are set. Redirect
  URI pattern: `{PUBLIC_BASE_URL}/api/auth/oauth/{provider}/callback`.
  On Android/iOS, Google uses native Google Sign-In (`google_sign_in`) with
  the Web client ID as `serverClientId` and `POST .../google/id-token`;
  Android OAuth clients (package + SHA-1) must exist in the same Google Cloud
  project — see `docs/ANDROID_PLAY_INTERNAL.md` §8.
- The server reports messages via the internal i18n package
  (`internal/i18n`); error strings are localized by `Accept-Language`.
