# iOS → TestFlight (Zozu Games)

Два приложения на одном iPhone (Flutter flavors), как Android `prod` / `dev`:

| Flavor | Bundle ID | Label | API |
|--------|-----------|-------|-----|
| **prod** | `com.zozugames.app` | Zozu Games | `https://multigameszozu.fly.dev` |
| **dev** | `com.zozugames.app.dev` | Zozu Games DEV | `https://multigameszozu-dev.fly.dev` |

В App Store Connect для DEV нужно **отдельное** приложение с Bundle ID `com.zozugames.app.dev`.  
Один Apple Developer Team, две схемы Xcode (`prod` / `dev`), два TestFlight.

Flutter ищет схему **с тем же именем**, что flavor: `--flavor prod` → `prod.xcscheme`.

## 1. Идентификаторы (один раз)

[Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list):

1. **+** → App IDs → App
2. Description: `Zozu Games`
3. Bundle ID → **Explicit**: `com.zozugames.app`
4. Capabilities позже (Push, Sign in with Apple) — не блокируют первую загрузку
5. То же для DEV: Description `Zozu Games DEV`, Bundle ID `com.zozugames.app.dev`

Если идентификатор уже занят этим Team — не создавай второй, бери существующий.

## 2. Два приложения в App Store Connect (один раз)

[App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **+** → New App:

### Prod
- Platforms: **iOS**
- Name: **Zozu Games** (уникальное в сторе; если занято — `Zozu Games` + суффикс)
- Primary Language: Russian или English
- Bundle ID: **`com.zozugames.app`**
- SKU: `zozugames`
- User Access: Full Access

### Dev
- Platforms: **iOS**
- Name: **Zozu Games DEV**
- Bundle ID: **`com.zozugames.app.dev`**
- SKU: `zozugames-dev`

Пока нет сборки, у приложения пустой экран — это нормально. Сначала заливай **DEV** в TestFlight.

## 3. Подпись в Xcode (один раз на Mac)

```bash
cd client
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

В Xcode:

1. Слева Runner → Signing & Capabilities
2. Team: твой Apple Developer
3. Signing: **Automatically manage signing**
4. Схема **prod** → Bundle ID `com.zozugames.app`
5. Схема **dev** → Bundle ID `com.zozugames.app.dev`
6. Для каждой схемы Xcode сам создаст Provisioning Profile

Не открывай `Runner.xcodeproj` — только `.xcworkspace` (CocoaPods).

Схема `Runner` = тот же prod (удобный дефолт в Xcode). Для Flutter всегда передавай `--flavor`.

## 4. Локальный run на iPhone / симуляторе

```bash
cd client

# DEV (рядом с prod на телефоне)
flutter run -d ios --flavor dev \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev

# Prod
flutter run -d ios --flavor prod \
  --dart-define=API_BASE=https://multigameszozu.fly.dev
```

Кабель / доверенный Mac, в Xcode выбран Team.  
Без `--flavor` Flutter не найдёт flavor-схему так же однозначно, как на Android.

На домашнем экране будут **две иконки**: `Zozu Games` и `Zozu Games DEV`.

## 5. Сборка IPA для TestFlight

Нужен Mac с Xcode. Каждый upload: больший `CFBundleVersion` (`--build-number` / число после `+` в `pubspec.yaml`).

**Dev (тестируй это первым):**
```bash
cd client
flutter build ipa --release --flavor dev \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev \
  --dart-define=BUILD_ID=local \
  --dart-define=APP_VERSION=0.1.0-dev-local+1 \
  --build-number=1
```
→ `client/build/ios/ipa/multigames_client.ipa`

**Prod:**
```bash
flutter build ipa --release --flavor prod \
  --dart-define=API_BASE=https://multigameszozu.fly.dev \
  --dart-define=BUILD_ID=local \
  --dart-define=APP_VERSION=0.1.0-prod-local+1 \
  --build-number=1
```

## 6. Загрузка в TestFlight

1. Открой [Transporter](https://apps.apple.com/app/transporter/id1450874784) или Xcode → Window → Organizer → Distribute App
2. Залей IPA в **своё** приложение (dev IPA → Zozu Games DEV)
3. App Store Connect → приложение → **TestFlight**
4. Дождись Processing (обычно 5–30 минут, иногда до пары часов)
5. Internal Testing → добавь свой Apple ID
6. На iPhone: приложение **TestFlight** → установить **Zozu Games DEV**

Первая сборка может запросить экспорт-комплаенс (шифрование). Для обычного HTTPS отвечай: uses encryption, only HTTPS / standard.

Missing Compliance в TestFlight: приложение → сборка → Provide Export Compliance Information.

## 7. Чеклист перед прод-релизом

- [x] Flavors `dev` / `prod`, разные Bundle ID (как Android `applicationId`)
- [ ] Identifiers `com.zozugames.app` и `.dev` в Apple Developer
- [ ] Два приложения в App Store Connect
- [ ] Team + Automatic signing в Xcode
- [ ] DEV IPA в TestFlight, ставится рядом с prod
- [ ] DEV стучится в `https://multigameszozu-dev.fly.dev`
- [ ] Store listing / Privacy Policy / возрастной рейтинг (для Review, не для Internal TestFlight)
- [ ] Google Sign-In: iOS OAuth clients на оба Bundle ID (см. ниже)

## 8. Google Sign-In (iOS)

На iOS кнопка «Войти через Google» — нативный `google_sign_in`, не браузер.

В [Google Cloud](https://console.cloud.google.com/) → тот же проект, что Web Client ID (`GOOGLE_CLIENT_ID`):

1. APIs & Services → Credentials → **Create OAuth client ID** → тип **iOS**
2. Bundle ID: `com.zozugames.app` (и отдельно `.dev`)
3. Скачай `GoogleService-Info.plist` **не коммить**
4. iOS client даёт `REVERSED_CLIENT_ID` — его нужно добавить в URL Types (Xcode → Runner → Info → URL Types) **для каждого flavor**, либо через xcconfig позже

Без iOS OAuth client на нужный Bundle ID нативная кнопка падает.  
Браузерный fallback на iOS для Google отключён специально.

## 9. Позже

- разные иконки для DEV
- CI: `flutter build ipa` на `macos-latest` (develop → dev, main → prod)
- Push (APNs) + Sign in with Apple
- App Store Review для prod
