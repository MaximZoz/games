# iOS → TestFlight без Mac (Zozu Games)

Mac не нужен. Сборку IPA и загрузку делает GitHub Actions (`macos-26-intel` + Xcode 26 / iOS 26 SDK), как Android AAB заливается в Play Internal. С апреля 2026 App Store Connect не принимает SDK старше iOS 26. Метка `macos-26` — тот же образ, но очередь arm64; при нехватке машин GitHub отменяет job, не начиная сборку.

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
6. Ссылку взять из Summary у **iOS TestFlight** (job **link**) и открыть в Safari

## 1. Идентификаторы (один раз)

С iPhone, Safari: [Identifiers](https://developer.apple.com/account/resources/identifiers/list)

1. **+** → App IDs → App
2. Description: `Zozu Games`
3. Bundle ID → **Explicit**: `com.zozugames.app`
4. Register
5. То же для DEV: Description `Zozu Games DEV`, Bundle ID `com.zozugames.app.dev`

Capability **Sign in with Apple** включает CI через API (не `produce`: ему нужен Apple ID, которого в GitHub нет). Вручную: Identifier → Sign In with Apple → Enable.

Если такой Bundle ID уже есть у этого Team — не создавай второй.

## 2. Два приложения в App Store Connect (один раз)

Это **не** страница Identifiers. Другой сайт: [Apps](https://appstoreconnect.apple.com/apps) → **+** → New App.

API-ключ приложение не создаёт: `POST /v1/apps` отвечает `The resource 'apps' does not allow 'CREATE'`. Пока записи нет, TestFlight для этого Bundle ID падает сразу.

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

Сертификаты CI кладёт в ветку `match-certs` (зашифрованы `MATCH_PASSWORD`). Это не ветка с кодом: там единственная копия ключа Apple Distribution. Ветку не удаляй. Если удалить, следующий прогон не найдёт сертификат, попытается создать новый и упрётся в лимит Apple (3 Distribution). `force_match` старый сертификат не отзывает.

## 5. Запустить заливку

Пока секретов нет, workflow сразу упадёт с именем недостающего секрета.

1. GitHub → **Actions** → **iOS TestFlight**
2. **Run workflow**
3. Branch: `develop` (DEV) или `main` (прод)
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

После успешной заливки workflow записывает номер сборки на API (`fly ssh` → `/api/internal/ios-testflight`). Нужен уже задеплоенный сервер с этим endpoint и секрет `FLY_API_TOKEN`. Пока записи нет, iPhone не показывает «Обновить»: деплой сервера сам по себе новую сборку не означает.

## 6. Поставить на iPhone

### Свой Apple ID разработчика (без кода, без Review)

Кнопка **«Использовать код»** в пустом TestFlight — не для себя. Кода у разработчика нет.

1. Safari → [Zozu Games DEV / TestFlight](https://appstoreconnect.apple.com/apps/6822534284/testflight)
2. Слева **Внутреннее тестирование** (не Redeem)
3. Открой группу. Вкладка **Тестировщики** → **+** → свой пользователь App Store Connect
4. Вкладка **Сборки** → **+** → последняя **Completed** / «Готово к отправке» (например 10023)
5. Почта этого Apple ID: письмо TestFlight → открой ссылку из письма
6. На iPhone: Настройки → имя = тот же Apple ID. TestFlight потяни вниз → **Zozu Games DEV** → Install

Если в TestFlight всё ещё заставка «разработчик должен пригласить» — на телефоне другой Apple ID. Тогда либо войди в TestFlight тем же аккаунтом, что в App Store Connect, либо добавь телефонный Apple ID в Users and Access и снова в Тестировщики.

### Чужой телефон / публичная ссылка

Список в TestFlight пустой, если на телефоне другой Apple ID — так и должно быть. Почту не добавляем.

**Не вводи код в TestFlight → Redeem.** Это поле для кодов App Store (только цифры/другой формат). Наш `3U9jPUVa` туда не вводится.

1. На iPhone открой **Safari** (не TestFlight)
2. Вставь ссылку вида `https://testflight.apple.com/join/…` из Actions → **iOS TestFlight** → job **link** → Summary
3. Safari предложит открыть TestFlight — Open
4. Install у **Zozu Games DEV**

Если TestFlight пишет **«не принимает новых тестировщиков»** — ссылка верная, но Apple ещё не одобрил **внешнюю** сборку (Beta Review). Один раз в Safari:

1. https://appstoreconnect.apple.com/apps/6822534284/testflight
2. Слева **Test Information**
3. Contact Information → телефон (свой, настоящий)
4. Save
5. Если ссылку нужно снова напечатать: Actions → **iOS TestFlight** → Run workflow → включи **только ссылка**
6. Подожди письмо Ready to Test и открой ту же ссылку `testflight.apple.com/join/…`

Один workflow: job **release** собирает IPA, job **link** печатает ссылку. Новую IPA не жми без нужды.

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
| `нет приложения` / `does not allow CREATE` | Bundle ID в Identifiers уже может быть. Нужна запись на [appstoreconnect.apple.com/apps](https://appstoreconnect.apple.com/apps) → **+** → New App → iOS. DEV: Bundle ID `com.zozugames.app.dev`, имя Zozu Games DEV, SKU `zozugames-dev`. Prod: `com.zozugames.app`, имя Zozu Games, SKU `zozugames`. Ключ это сделать не может |
| `No value found for 'username'` у `produce` | старый прогон. `produce` из lane убран: в CI нет Apple ID |
| `Could not create another … certificate` / `maximum number of available Distribution` | лимит Apple — 3 Distribution. Не жми `force_match` и не удаляй сертификаты вслепую. Верни ветку `match-certs`: в ней уже есть `.cer` и `.p12`. CI без этой ветки сам останавливается |
| `readonly` / `No code signing identity` | не жми Re-run на старом прогоне. Actions → iOS TestFlight → **Run workflow** с `develop`, flavor **dev** |
| `Authentication credentials are missing` / 401 | неверный Key ID / Issuer / `.p8`, или ключ не Admin |
| `match` / git push | не удаляй ветку `match-certs`; у workflow есть `contents: write` |
| `SDK version issue` / `iOS 18.5` | Apple с апреля 2026 принимает только iOS 26 SDK. Нужен Xcode 26 на `macos-26-intel` (или `macos-26`). Не жми Re-run на старом прогоне — дождись вливания в `develop` / `main` |
| `not acquired by Runner` | GitHub не выдал машину. `macos-26` — очередь arm64; workflow собирает на `macos-26-intel`. Отмени зависший прогон и запусти workflow заново с ветки, где уже стоит `macos-26-intel` |
| `Invalid MinimumOSVersion` / `App.framework` | в `client/ios/Flutter/AppFrameworkInfo.plist` должен быть `MinimumOSVersion` 15.0 |
| `Deployment target too low` / `90068` | приложение целится в iOS 15.0 (с апреля 2027 Apple не примет ниже) |
| `CFBundleShortVersionString` / `at most three` | версия только три числа (`0.1.0`); номер сборки (`10010`) идёт отдельно в `CFBundleVersion` |
| `doesn't include the com.apple.developer.applesignin` | Bundle ID был создан раньше capability. CI включает Sign in with Apple и пересобирает профиль. Не жми Re-run старого прогона — дождись вливания в `develop` |
| `aps-environment` / Push | CI включает Push Notifications и пересобирает профиль. Если ошибка осталась — Identifiers → Push Notifications → Enable, затем Run workflow → `force_match` |
| `associated-domains` / Associated Domains | CI включает capability и пересобирает профиль. Домен в entitlement: `applinks:zozugames.com`. На Fly нужен `APPLE_TEAM_ID`, иначе `apple-app-site-association` отвечает 404 и ссылка остаётся в Safari |

Лог Actions: job **release**, шаг **Build IPA and upload to TestFlight**.

## 9. Вход на iPhone (Apple и Google)

**Sign in with Apple** — системный лист того же Apple ID, что в Настройках.
Канал в `AppDelegate` (`com.zozugames/apple_sign_in`), кнопка выше Google.
Сервер проверяет identity token через JWKS Apple
(`POST /api/auth/oauth/apple/id-token`). Web-секреты `APPLE_*` для этого не нужны.

**Google** — системный лист в приложении (схема `zozugames` или `zozugames-dev`), не уход на сайт. Плагин `google_sign_in` на iPhone не вызывается: без отдельного iOS OAuth client он падает сразу.

Если лоадер крутится и окно не открывается:

1. `SceneDelegate` должен прокидывать URL в `FlutterAppDelegate` (уже в репо)
2. На сервере должен быть `GOOGLE_CLIENT_ID` (Web client). Отдельный iOS OAuth client для этого листа не нужен.

## 10. Уведомления на iPhone

Пока приложение открыто или только что свёрнуто, баннер рисует само приложение (как на Android). Когда процесс убит, баннер приходит через FCM. Для этого нужны три вещи. Без `GoogleService-Info.plist` в IPA закрытое приложение молчит: токен на сервер не уходит.

В логе TestFlight строка `No GoogleService-Info.plist secret — closed-app FCM will be off in this IPA` значит, что эта сборка пуши при закрытом приложении не пришлёт. Android-секрет `ANDROID_GOOGLE_SERVICES_JSON` iPhone не заменяет.

| Что | Куда |
|-----|------|
| `GoogleService-Info.plist` с `BUNDLE_ID` этой сборки | секрет GitHub, CI кладёт его в IPA |
| Push Notifications на Bundle ID | CI включает сам и пересобирает профиль |
| `FCM_SERVICE_ACCOUNT_JSON` | уже на Fly, тот же секрет, что для Android |

Секреты Actions:

| Секрет | Файл |
|--------|------|
| `IOS_GOOGLE_SERVICE_INFO_PLIST` | plist прод, `BUNDLE_ID` = `com.zozugames.app` |
| `IOS_GOOGLE_SERVICE_INFO_PLIST_DEV` | plist DEV, `BUNDLE_ID` = `com.zozugames.app.dev` |

Firebase → тот же проект, что Android → Add app → iOS → скачать plist. В git файл не класть.

В файле должен быть ровно `<string>com.zozugames.app</string>` или `.dev`. Чужой Bundle ID CI не подставит.

После зелёного **iOS TestFlight** поставь сборку, войди, разреши уведомления. Свёрнутое приложение показывает баннер сразу. Закрытое — после того, как в логе сборки есть `Wrote ios/Runner/GoogleService-Info.plist`.

В Apple Developer у Bundle ID должен быть ключ APNs (Firebase → Cloud Messaging → Apple app → APNs Authentication Key). Без ключа FCM не доставит баннер на iPhone, хотя токен приложение получит.

## 11. Если появится Mac

```bash
cd client
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Схемы `prod` / `dev`, Team, Automatic signing.  
`flutter run -d ios --flavor dev --dart-define=API_BASE=https://multigameszozu-dev.fly.dev`

Для стора всё равно удобнее CI, не локальный Transporter.
