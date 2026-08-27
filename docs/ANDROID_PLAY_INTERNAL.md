# Android → Google Play Internal testing (Zozu Games)

Два приложения на одном телефоне (product flavors):

| Flavor | applicationId | Label | API |
|--------|---------------|-------|-----|
| **prod** | `com.zozugames.app` | Zozu Games | `https://multigameszozu.fly.dev` |
| **dev** | `com.zozugames.app.dev` | Zozu Games DEV | `https://multigameszozu-dev.fly.dev` |

В Play Console для DEV нужно **отдельное** приложение с package `com.zozugames.app.dev`  
(тот же upload keystore; SA с правом Release to testing tracks на оба приложения).

## 1. Release keystore (один раз, сохрани навсегда)

Из каталога `client/android/`:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias zozugames
```

```bash
cp client/android/key.properties.example client/android/key.properties
# storeFile=../upload-keystore.jks
```

**Важно:** `upload-keystore.jks` и `key.properties` не коммитить.

## 2. Сборка AAB (локально)

**Prod:**
```bash
cd client
flutter build appbundle --release --flavor prod \
  --dart-define=API_BASE=https://multigameszozu.fly.dev \
  --dart-define=ANDROID_APPLICATION_ID=com.zozugames.app \
  --dart-define=BUILD_ID=local \
  --dart-define=APP_VERSION=0.1.0-prod-local+1
```
→ `client/build/app/outputs/bundle/prodRelease/app-prod-release.aab`

**Dev:**
```bash
flutter build appbundle --release --flavor dev \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev \
  --dart-define=ANDROID_APPLICATION_ID=com.zozugames.app.dev \
  --dart-define=BUILD_ID=local \
  --dart-define=APP_VERSION=0.1.0-dev-local+1
```
→ `client/build/app/outputs/bundle/devRelease/app-dev-release.aab`

Каждый upload в Play: больший `versionCode` (`--build-number` / число после `+` в pubspec).

## 3. Play Console

### Prod (уже есть)
**ZozuGames** / `com.zozugames.app` → Internal testing → залей `app-prod-release.aab`.

### Dev (создай один раз)
1. Play Console → **Создать приложение**
2. Package name: **`com.zozugames.app.dev`**
3. Название: например **Zozu Games DEV**
4. Internal testing → залей `app-dev-release.aab`
5. Testers: тот же email-список
6. Users/API access: дай SA `play-uploader@…` права Release to testing на **это** приложение тоже

Без второго приложения CI для `develop` соберёт AAB (artifact), но Upload to Play упадёт с package not found / permission.

## 4. GitHub Actions

Workflow: `.github/workflows/android-internal.yml`

| Событие | Flavor | Package | API |
|--------|--------|---------|-----|
| push `develop` (`client/**`) | `dev` | `com.zozugames.app.dev` | DEV |
| push `main` (`client/**`) | `prod` | `com.zozugames.app` | prod |
| Run workflow | выбор | см. выше | см. выше |

Секреты те же (`ANDROID_KEYSTORE_*`, `PLAY_SERVICE_ACCOUNT_JSON`).

### Если Queued / Failed to cancel

Settings → Actions → Disable → Enable; не спамь Run workflow.

## 5. In-app «Обновить»

Работает **отдельно** в каждом приложении (свой package / свой Internal track).  
Установка только из Play (не `flutter run`).

## 6. Локальный run на устройстве

```bash
cd client
# DEV (рядом с prod на телефоне)
flutter run -d android --flavor dev \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev \
  --dart-define=ANDROID_APPLICATION_ID=com.zozugames.app.dev

# Prod
flutter run -d android --flavor prod \
  --dart-define=API_BASE=https://multigameszozu.fly.dev \
  --dart-define=ANDROID_APPLICATION_ID=com.zozugames.app
```

Без `--flavor` сборка Android не пройдёт (нужен product flavor).

## 7. Чеклист

- [x] Flavors `dev` / `prod`, разные applicationId
- [ ] Play app для `com.zozugames.app.dev`
- [ ] SA права на оба приложения
- [ ] Internal + тестеры на обоих
- [ ] CI зелёный для develop (dev) и main (prod)

## 8. Google Sign-In (Android) — аккаунт Play / устройства

На Android кнопка «Войти через Google» использует **нативный Google Sign-In**
(тот же Google-аккаунт, что в Play Market), а не браузерный OAuth.

Поток: `id_token` (или Android `server_auth_code`) →
`POST /api/auth/oauth/google/id-token`  
(`GOOGLE_CLIENT_ID` на сервере = **Web** OAuth Client ID).

Клиент читает `id_token` / `server_auth_code` из результата platform
`signIn()` (без `getTokens`). Если токены пустые — браузерный OAuth
без блокирующего poll на 5 минут.

### Ошибка `sign_in_failed` / `d 10` / `ApiException: 10`

Это **DEVELOPER_ERROR**: в Google Cloud нет Android OAuth client с нужным
**package name + SHA-1** (или SHA не от того ключа).

Для билдов **из Play Internal** нужен SHA-1 **App signing key**, не upload:

1. [Play Console](https://play.google.com/console) → приложение
   (`com.zozugames.app` или `.dev`)
2. **Release** → **Setup** → **App integrity** / **App signing**
3. Скопируй **SHA-1** у **App signing key certificate**
4. [Google Cloud Console](https://console.cloud.google.com/) → тот же проект,
   где Web Client ID (`GOOGLE_CLIENT_ID` /
   `576062919624-….apps.googleusercontent.com`)
5. APIs & Services → Credentials → **Create OAuth client ID** → тип **Android**
   - Package name: `com.zozugames.app` (и отдельно `.dev`)
   - SHA-1: вставь из шага 3
6. Подожди 5–15 минут, переустанови / обнови приложение, попробуй снова

Дополнительно можно добавить SHA-1 **upload** keystore и **debug** keystore
в те же Android clients (для локальных сборок).

Без этого native Google на телефоне **не заработает**; браузерный fallback
может открыться, но native picker будет с кодом 10.

### Google Cloud Console (чеклист)

1. Web application client → уже в Fly как `GOOGLE_CLIENT_ID`
2. Android clients в **том же** GCP-проекте:
   - `com.zozugames.app` + SHA-1 App signing (+ upload, debug)
   - `com.zozugames.app.dev` + те же SHA-1
3. Проверка upload/debug SHA:
   ```bash
   keytool -list -v -keystore client/android/upload-keystore.jks -alias zozugames
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
     -storepass android -keypass android
   ```

Play Games Services **не** нужны — достаточно Google Sign-In.

## 9. Позже

- разные иконки для DEV
- Store listing / Privacy / Data safety
- KZ payments / IAP
