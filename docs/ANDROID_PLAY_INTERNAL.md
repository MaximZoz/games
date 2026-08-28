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
`signIn()` (без `getTokens`). На Android/iOS **браузер не открываем**:
только нативный Google Sign-In. Браузерный OAuth уводил в веб-версию.

Если видишь код **10** / DEVELOPER_ERROR — не хватает Android OAuth client
с SHA-1. После добавления SHA-1 вход снова только через системный picker
(без браузера).

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

Без этого native Google на телефоне **не заработает** (ошибка 10).
Браузерный fallback на Android для Google отключён специально —
он открывал веб-приложение вместо нативного.

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

## 9. Android FCM (уведомления при закрытом приложении)

Нужны **три вещи**. Без любой из них закрытое приложение молчит.

| Что | Зачем | Куда кладём |
|-----|--------|-------------|
| `google-services.json` | Телефон понимает «я приложение Zozu в проекте Google» и умеет получить токен | в AAB (через секрет GitHub) |
| `FCM_SERVICE_ACCOUNT_JSON` | Сервер имеет право сказать Google: «покажи баннер этому телефону» | секрет Fly |
| Новая сборка + деплой сервера | Старое приложение и старый сервер об FCM не знают | Play Internal + Fly |

Это **один раз**. Потом пуш идёт сам.

Ниже — если смотришь только прод (приложение из Play **Zozu Games**, не DEV).
DEV — те же шаги, пакет `com.zozugames.app.dev`.

### 9.1. Открыть тот же Google-проект, что для входа

Вход через Google уже заведён: в Fly лежит `GOOGLE_CLIENT_ID`
(`576062919624-….apps.googleusercontent.com`).

1. [Google Cloud Console](https://console.cloud.google.com/) → сверху
   выбери **тот проект**, где этот OAuth client.
2. Открой [Firebase Console](https://console.firebase.google.com/).
3. **Add project** / **Add Firebase to Google Cloud project** → выбери
   **этот же** проект. Не создавай второй с нуля.

Если Firebase-проект уже есть на этом GCP — просто открой его.

### 9.2. Зарегистрировать Android-пакеты

В Firebase: шестерёнка рядом с **Project overview** → **Project settings**
→ вкладка **General** → **Your apps**.

**Первое приложение (прод):**

1. **Add app** → иконка Android.
2. **Android package name:** `com.zozugames.app`  
   (ровно так, без пробелов).
3. **App nickname:** `Zozu Games` (как удобно).
4. **SHA-1** — тот же, что для Google Sign-In (Play Console → App signing
   → **App signing key certificate**). Можно добавить сразу, можно позже.
5. **Register app**.
6. Скачай **`google-services.json`**. Сохрани как
   `google-services-prod.json` на компьютер. **В git не клади.**

**Второе приложение (DEV), если ставишь DEV-сборку:**

Те же шаги, package name: `com.zozugames.app.dev`.  
Скачанный файл сохрани как `google-services-dev.json`.

Если оба пакета в одном Firebase-проекте, в одном `google-services.json`
могут быть оба клиента — тогда один файл годится и для prod, и для dev.

### 9.3. Включить Cloud Messaging API

1. [Google Cloud → APIs & Services → Library](https://console.cloud.google.com/apis/library)
2. Найди **Firebase Cloud Messaging API**.
3. Если не Enabled — **Enable**.

### 9.4. Ключ, которым сервер шлёт пуш

Это **не** `google-services.json`. Это другой JSON — сервис-аккаунт.

1. Firebase → Project settings → вкладка **Service accounts**.
2. **Generate new private key** → подтверди → скачается файл вида
   `*-firebase-adminsdk-*.json`.
3. Открой его блокнотом: внутри должны быть `"type": "service_account"`
   и `"project_id": "..."`.
4. Сохрани. **В git не клади.** Этот файл = полный доступ слать пуш
   от имени проекта.

### 9.5. Положить ключ сервера на Fly

Сервер читает секрет `FCM_SERVICE_ACCOUNT_JSON`.

**Прод** (`https://multigameszozu.fly.dev`):

```bash
fly secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat *-firebase-adminsdk-*.json)" --app multigameszozu
```

**DEV** (`https://multigameszozu-dev.fly.dev`):

```bash
fly secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat *-firebase-adminsdk-*.json)" --app multigameszozu-dev
```

`cat ...` подставь реальное имя скачанного файла.

Без `fly` в терминале: [Fly Dashboard](https://fly.io/dashboard) →
приложение `multigameszozu` → **Secrets** → имя
`FCM_SERVICE_ACCOUNT_JSON` → значение = **весь** JSON одной строкой
(скопируй содержимое файла целиком).

После `secrets set` Fly сам перезапустит машины. В логах должно быть
`FCM: enabled`. Если `FCM: disabled` — секрет пустой или это не JSON
сервис-аккаунта.

Код с эндпоинтами `/api/push/device` должен быть **задеплоен**
(ветка `main` → прод, `develop` → DEV). Старый сервер секрета не поймёт.

### 9.6. Положить `google-services.json` в GitHub Actions

CI кладёт файл внутрь AAB перед сборкой. В репозиторий файл не коммитим.

1. Открой репозиторий на GitHub → **Settings** → **Secrets and variables**
   → **Actions** → **New repository secret**.
2. Имя: `ANDROID_GOOGLE_SERVICES_JSON`
3. Value: **весь** текст `google-services-prod.json` (или общего файла
   на оба пакета).
4. Если DEV-файл **другой**: ещё секрет
   `ANDROID_GOOGLE_SERVICES_JSON_DEV` с текстом `google-services-dev.json`.

Проверка: в логе Android Play Internal должно быть
`Wrote android/app/src/.../google-services.json`.
Если `No google-services.json secret` — секрет не увидели, в AAB FCM нет.

### 9.7. Новая сборка на телефон

1. Дождись зелёного workflow **Android Play Internal**
   (`develop` = DEV-приложение, `main` = прод).
2. Play Console → Internal testing → дождись, пока сборка станет доступна.
3. На телефоне обнови Zozu из Internal track (не старый APK/`flutter run`).
4. Открой приложение, войди в аккаунт, разреши уведомления (Android 13+).
5. Выйди из приложения (свайп из недавних). С другого аккаунта напиши
   в чат / кинь инвайт.
6. Должен прийти системный баннер.

После **Выйти** в приложении токен снимается — на этот телефон пуш
больше не должен приходить, пока снова не войдёшь.

### Если что-то не так

| Симптом | Что проверить |
|---------|----------------|
| В логах Fly `FCM: disabled` | секрет не тот файл или пустой |
| Баннера нет, приложение закрыто | новая AAB с `google-services.json` + новый сервер с FCM + разрешение в настройках Android |
| Баннер только пока игра открыта в фоне | стоит старая сборка без FCM, работает только сокет |
| После logout пуш ещё приходит | не обновился сервер/клиент, токен не сняли |

## 10. Позже

- разные иконки для DEV
- Store listing / Privacy / Data safety
- KZ payments / IAP
