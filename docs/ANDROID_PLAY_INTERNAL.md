# Android → Google Play Internal testing (Zozu Games)

Package / applicationId: **`com.zozugames.app`**  
(должен совпадать с приложением в Play Console)

## 1. Release keystore (один раз, сохрани навсегда)

Из каталога `client/android/`:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias zozugames
```

Создай `client/android/key.properties` из примера:

```bash
cp client/android/key.properties.example client/android/key.properties
# storeFile=../upload-keystore.jks  (если .jks в client/android/)
```

**Важно:** `upload-keystore.jks` и `key.properties` не коммитить. Потеря keystore = нельзя нормально обновлять то же приложение в Play.

## 2. Сборка AAB (локально)

```bash
cd client
flutter pub get
flutter build appbundle --release \
  --dart-define=API_BASE=https://multigameszozu.fly.dev
```

Файл:
`client/build/app/outputs/bundle/release/app-release.aab`

Для DEV API:
```bash
flutter build appbundle --release \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev
```

Каждый новый upload в Play должен иметь **больший** `versionCode`  
(`pubspec.yaml` → `0.1.0+N`, число после `+`).

## 3. Play Console → Internal testing (ручная загрузка)

1. Play Console → приложение **Zozu Games** (`com.zozugames.app`)
2. **Testing → Internal testing → Create new release**
3. Загрузи `app-release.aab`
4. Notes for testers: например `Internal build 1`
5. **Save → Review → Start rollout to Internal testing**
6. **Testers** → добавь свой Google-аккаунт / создай email list
7. Открой на телефоне ссылку copy link / join on the web → Install

## 4. GitHub Actions — полный авторелиз в Internal

Workflow: `.github/workflows/android-internal.yml`  
Имя в Actions: **Android Play Internal**

### Когда запускается

| Событие | API в AAB | Track |
|--------|-----------|--------|
| push в `develop` (изменения в `client/**`) | `https://multigameszozu-dev.fly.dev` | Internal |
| push в `main` (изменения в `client/**`) | `https://multigameszozu.fly.dev` | Internal |
| Actions → Run workflow | выбираешь `dev` / `prod` | Internal |

Один package / один Internal track — последний успешный upload видят тестировщики  
(имя релиза `internal-dev-…` / `internal-prod-…`).

`versionCode` в CI: `10000 + github.run_number`.

### Секреты (Settings → Secrets and variables → Actions)

Вкладка **Repository secrets** (не Environment):

| Secret | Значение |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | base64 от `upload-keystore.jks` (одна длинная строка) |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | `zozugames` |
| `PLAY_SERVICE_ACCOUNT_JSON` | весь JSON ключа service account |

#### Keystore → Base64 (PowerShell)

```powershell
$path = "C:\myProject\client\android\upload-keystore.jks"
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
$b64.Length
Set-Clipboard -Value $b64
```

#### Service account для Play API

1. Google Cloud → Enable **Google Play Android Developer API**
2. Service account → Keys → JSON
3. JSON → секрет `PLAY_SERVICE_ACCOUNT_JSON`
4. Play Console → Users and permissions → Invite `client_email`  
   с правом **Release apps to testing tracks**

### Проверка

1. Все 5 секретов на месте.  
2. Actions → **Android Play Internal** → **Run workflow** → `dev` или `prod`.  
3. Зелёный run → новый выпуск в Play Internal.

### Если run висит в Queued / «Failed to cancel»

1. Открой **конкретный** run → сверху **Cancel workflow** (не только «…» в списке).  
2. Или: репо **Settings → Actions → General** → **Disable Actions** → ~1 мин → снова **Enable**  
   (сбрасывает зависшие Queued).  
3. Не жми Run workflow много раз подряд — в workflow один активный релиз, новый отменяет старый.  
4. Deploy Fly может при этом работать — очередь часто только у Android-job.

## 5. In-app «Обновить» на Android

После установки **из Play Internal** (не sideload) приложение проверяет новую версию
через **Google Play In-App Updates**:

1. Новый AAB в Internal.  
2. Play отдаёт update → диалог / баннер «Доступно обновление».  
3. **Обновить** → immediate/flexible Play API; иначе страница в Store.

Не работает на `flutter run` / sideload APK.  
Web по-прежнему: `BUILD_ID` + reload.  
Код: `client/lib/core/app_play_update*.dart`, `app_update_provider.dart`.

## 6. Локальный прогон на устройстве (до AAB)

```bash
cd client
flutter run -d android \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev
```

## 7. Чеклист

- [x] `applicationId` = `com.zozugames.app`
- [x] label = `Zozu Games`
- [x] `INTERNET` в main manifest
- [ ] release keystore + `key.properties` (локально)
- [ ] GitHub secrets для Actions (см. §4)
- [ ] SA приглашён в Play Console
- [ ] Internal testing + ты в тестерах
- [ ] После второго Internal-релиза: in-app «Обновить» на телефоне

## 8. Позже (не блокер для Internal)

- иконки/feature graphic для Store listing
- Privacy Policy URL
- Data safety form
- Content rating questionnaire
- KZ payments / IAP (отдельный этап)
