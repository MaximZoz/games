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

Как Fly-деплой, но только если затронут клиент (или сам workflow).  
Сервер-only merge в Play не уходит.

**Важно:** один package и один Internal track. Последний успешный upload  
перезаписывает то, что ставят тестировщики (DEV или prod API — смотри имя релиза `internal-dev-…` / `internal-prod-…`).

`versionCode` в CI: `10000 + github.run_number` (чтобы не конфликтовать с локальным `+1`).

### Секреты (Settings → Secrets and variables → Actions)

| Secret | Значение |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | base64 от `upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | `zozugames` |
| `PLAY_SERVICE_ACCOUNT_JSON` | весь JSON ключа service account |

#### Keystore → Base64 (PowerShell)

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("C:\myProject\client\android\upload-keystore.jks")
) | Set-Clipboard
```

Вставь из буфера в секрет `ANDROID_KEYSTORE_BASE64` (одна длинная строка, без переносов).

#### Service account для Play API

1. [Google Cloud Console](https://console.cloud.google.com/) → проект (или создай)  
2. **APIs & Services → Enable APIs** → включи **Google Play Android Developer API**  
3. **IAM → Service accounts → Create**  
4. Keys → Add key → JSON → скачай файл  
5. Содержимое JSON → секрет `PLAY_SERVICE_ACCOUNT_JSON`  
6. Play Console → **Users and permissions → Invite new users**  
   - email service account (`...@....iam.gserviceaccount.com`)  
   - права: минимум **View app information** + **Release to testing tracks**  
     (или Admin для приложения)  
7. Прими приглашение / дождись, пока аккаунт станет активным (иногда до часа)

Без первого ручного Internal-релиза API иногда отказывает — у тебя уже есть **Internal 1**, этого достаточно.

### Проверка

1. Заполни все 5 секретов.  
2. GitHub → Actions → **Android Play Internal** → **Run workflow** → `dev`.  
3. Дождись зелёного run; в Play Console → Internal появится новый выпуск.  
4. На телефоне обнови приложение из внутренней тестовой ссылки.

## 5. Локальный прогон на устройстве (до AAB)

```bash
cd client
flutter run -d android \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev
```

## 6. Чеклист перед первой загрузкой

- [x] `applicationId` = `com.zozugames.app`
- [x] label = `Zozu Games`
- [x] `INTERNET` permission в main manifest
- [ ] release keystore + `key.properties` (локально)
- [ ] GitHub secrets для Actions (см. §4)
- [ ] AAB собран с нужным `API_BASE`
- [ ] Internal testing track создан, ты в списке тестеров

## 7. Позже (не блокер для Internal)

- иконки/feature graphic для Store listing
- Privacy Policy URL
- Data safety form
- Content rating questionnaire
- KZ payments / IAP (отдельный этап)
