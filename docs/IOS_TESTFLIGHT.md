# iOS → TestFlight без Mac (Zozu Games)

Mac не нужен. Сборку IPA и загрузку делает GitHub Actions (`macos-26` + Xcode 26 / iOS 26 SDK), как Android AAB заливается в Play Internal. С апреля 2026 App Store Connect не принимает SDK старше iOS 26.

На iPhone ставишь приложение **TestFlight** из App Store и ставишь сборку оттуда.

| Flavor | Bundle ID | Label | API | Когда CI заливает |
|--------|-----------|-------|-----|-------------------|
| **dev** | `com.zozugames.app.dev` | Zozu Games DEV | `https://multigameszozu-dev.fly.dev` | push в `develop` или Run workflow → dev |
| **prod** | `com.zozugames.app` | Zozu Games | `https://multigameszozu.fly.dev` | push в `main` или Run workflow → prod |

Два Bundle ID = две иконки на одном iPhone. Для DEV в App Store Connect нужно **отдельное** приложение.

Workflow: `.github/workflows/ios-testflight.yml`

Сначала заливай **DEV**. Прод — когда DEV открывается с телефона.

## 0. Что сделать с iPhone (один раз)

Всё в Safari / приложении GitHub. Потом Actions → Run workflow.

1. Два App ID в Apple Developer
2. Два приложения в App Store Connect
3. API-ключ App Store Connect (роль **Admin**) + Team ID
4. Пять секретов в GitHub
5. Запустить workflow **iOS TestFlight**, target `dev` (заливка IPA)
6. Взять код из **iOS TestFlight code** и Redeem в приложении TestFlight

## 1. Идентификаторы (один раз)

С iPhone, Safari: [Identifiers](https://developer.apple.com/account/resources/identifiers/list)

1. **+** → App IDs → App
2. Description: `Zozu Games`
3. Bundle ID → **Explicit**: `com.zozugames.app`
4. Register
5. То же для DEV: Description `Zozu Games DEV`, Bundle ID `com.zozugames.app.dev`

Capabilities (Push, Sign in with Apple) не нужны для первой установки.

Если такой Bundle ID уже есть у этого Team — не создавай второй.

## 2. Два приложения в App Store Connect (один раз)

[Apps](https://appstoreconnect.apple.com/apps) → **+** → New App

### Prod
- Platforms: **iOS**
- Name: **Zozu Games** (если имя занято в сторе — добавь суффикс)
- Primary Language: Russian или English
- Bundle ID: **`com.zozugames.app`**
- SKU: `zozugames`

### Dev (это тестируй первым)
- Platforms: **iOS**
- Name: **Zozu Games DEV**
- Bundle ID: **`com.zozugames.app.dev`**
- SKU: `zozugames-dev`

Пустой экран без сборки — так и должно быть.

## 3. API-ключ и Team ID (один раз)

Ключ нужен, чтобы CI подписал IPA и залил его **без твоего Mac**.

### Team ID
[Membership Details](https://developer.apple.com/account) — **Team ID**, ровно **10** символов (A–Z, 0–9). Это `APPLE_TEAM_ID`.

### Ключ
[App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)

1. Запомни **Issuer ID** (UUID сверху) — это `APP_STORE_CONNECT_ISSUER_ID`
2. **+** Generate API Key
3. Name: `github-testflight`
4. Access: **Admin** (без Admin match не создаст сертификат)
5. Generate
6. **Key ID** — это `APP_STORE_CONNECT_KEY_ID`
7. **Download** — файл `AuthKey_XXXX.p8`. Apple отдаёт его **один раз**
8. Открой файл в «Файлы» / текстовом редакторе и скопируй **весь** текст, включая
   `-----BEGIN PRIVATE KEY-----` и `-----END PRIVATE KEY-----`
   Это `APP_STORE_CONNECT_API_KEY`. Не Key ID и не Issuer ID.

   Если секрет уже создан не тем текстом: карандаш у `APP_STORE_CONNECT_API_KEY` →
   вставь файл заново → Update secret.

Ключ никуда не коммить и никому не слать.

## 4. Секреты GitHub (один раз)

Репозиторий → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Придумай пароль для шифрования сертификатов (любая длинная фраза). Его больше нигде нет — только этот секрет. Это `MATCH_PASSWORD`.

| Секрет | Откуда |
|--------|--------|
| `APP_STORE_CONNECT_KEY_ID` | Key ID ключа |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (UUID) |
| `APP_STORE_CONNECT_API_KEY` | весь текст `.p8` |
| `APPLE_TEAM_ID` | 10 символов Team ID |
| `MATCH_PASSWORD` | придумай сам, сохрани |

Сертификаты CI кладёт в ветку `match-certs` (зашифрованы `MATCH_PASSWORD`). Ветку не удаляй.

## 5. Запустить заливку

Пока секретов нет, workflow сразу упадёт с именем недостающего секрета.

1. GitHub → **Actions** → **iOS TestFlight**
2. **Run workflow**
3. Branch: эта ветка (пока не влито в `develop`) или `develop`
4. Flavor: **dev**
5. Run

Первый прогон создаёт Apple Distribution certificate и профиль, собирает IPA, заливает в TestFlight. Обычно 15–25 минут.  
macOS-минуты GitHub дороже Linux — не жми Run подряд.

Дальше само:

| Событие | Flavor |
|--------|--------|
| push `develop` (`client/**`) | `dev` |
| push `main` (`client/**`) | `prod` |
| Run workflow | выбор |

Если match/сертификат сломался: Run workflow → **force_match**.

## 6. Поставить на iPhone (только ссылка)

Список в TestFlight пустой, если на телефоне другой Apple ID — так и должно быть. Почту не добавляем.

**Не вводи код в TestFlight → Redeem.** Это поле для кодов App Store (только цифры/другой формат). Наш `3U9jPUVa` туда не вводится.

1. На iPhone открой **Safari** (не TestFlight)
2. Вставь ссылку вида `https://testflight.apple.com/join/…` из Actions → **iOS TestFlight code** → Summary
3. Safari предложит открыть TestFlight — Open
4. Install у **Zozu Games DEV**

Первая внешняя сборка идёт на **Beta Review** у Apple (обычно несколько часов). Код уже есть, но Install появится после одобрения. Если TestFlight пишет, что бета недоступна — подожди письмо.

Новый код без пересборки IPA: Actions → **iOS TestFlight code** → Run workflow → `dev`.

Первая сборка иногда спрашивает Export Compliance. В приложении уже стоит `ITSAppUsesNonExemptEncryption=false` (только обычный HTTPS). Если ASC всё равно спросит: encryption yes, only HTTPS / exempt.

## 7. Чеклист

- [x] Flavors `dev` / `prod`, разные Bundle ID
- [x] CI без Mac: `.github/workflows/ios-testflight.yml`
- [ ] Identifiers `com.zozugames.app` и `.dev`
- [ ] Два приложения в App Store Connect
- [ ] API-ключ Admin + 5 секретов GitHub
- [ ] Зелёный **iOS TestFlight** для `dev`
- [ ] DEV ставится из TestFlight и ходит на `https://multigameszozu-dev.fly.dev`

## 8. Если workflow красный

| Сообщение | Что сделать |
|-----------|-------------|
| `Нет секрета …` | добавь секрет из таблицы выше |
| `APPLE_TEAM_ID должен быть 10 символов` | скопируй Team ID из Membership, без пробелов |
| `BEGIN PRIVATE KEY` / слишком короткий | в секрет попал Key ID или кусок без `BEGIN PRIVATE KEY`. Открой `.p8` целиком и обнови секрет карандашом |
| `не может его создать` / `does not allow CREATE` | API-ключ не умеет New App. Создай вручную: App Store Connect → Apps → + → iOS, Bundle ID `com.zozugames.app.dev`, имя Zozu Games DEV, SKU `zozugames-dev` |
| `Could not create another … certificate` | в Developer → Certificates уже 3 Distribution; удали старый или Run с `force_match` |
| `readonly` / `No code signing identity` | не жми Re-run на старом прогоне `main`. Actions → iOS TestFlight → **Run workflow** с ветки `cursor/fix-lobby-search-size-27ec`, flavor **dev** |
| `Authentication credentials are missing` / 401 | неверный Key ID / Issuer / `.p8`, или ключ не Admin |
| `match` / git push | не удаляй ветку `match-certs`; у workflow есть `contents: write` |
| `SDK version issue` / `iOS 18.5` | Apple с апреля 2026 принимает только iOS 26 SDK. Нужен `macos-26` + Xcode 26. Не жми Re-run на старом прогоне — новый push на эту ветку |
| `Invalid MinimumOSVersion` / `App.framework` | в `client/ios/Flutter/AppFrameworkInfo.plist` должен быть `MinimumOSVersion` 13.0 |
| `CFBundleShortVersionString` / `at most three` | версия только три числа (`0.1.0`); номер сборки (`10010`) идёт отдельно в `CFBundleVersion` |

Лог Actions: job **release**, шаг **Build IPA and upload to TestFlight**.

## 9. Google Sign-In (не блокирует установку)

На iOS вход через Google — нативный `google_sign_in`.

В [Google Cloud](https://console.cloud.google.com/) того же проекта, что Web Client ID:

1. Credentials → **Create OAuth client ID** → тип **iOS**
2. Bundle ID: `com.zozugames.app` и отдельно `.dev`
3. `GoogleService-Info.plist` **не коммить**
4. `REVERSED_CLIENT_ID` потом в URL Types

Без этого кнопка Google на iOS не войдёт. Сборка и TestFlight от этого не зависят.

## 10. Если появится Mac

```bash
cd client
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Схемы `prod` / `dev`, Team, Automatic signing.  
`flutter run -d ios --flavor dev --dart-define=API_BASE=https://multigameszozu-dev.fly.dev`

Для стора всё равно удобнее CI, не локальный Transporter.
