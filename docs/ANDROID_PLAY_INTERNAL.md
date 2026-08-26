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

## 2. Сборка AAB

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

## 3. Play Console → Internal testing

1. Play Console → приложение **Zozu Games** (`com.zozugames.app`)
2. **Testing → Internal testing → Create new release**
3. Загрузи `app-release.aab`
4. Notes for testers: например `Internal build 1`
5. **Save → Review → Start rollout to Internal testing**
6. **Testers** → добавь свой Google-аккаунт / создай email list
7. Открой на телефоне ссылку copy link / join on the web → Install

## 4. In-app «Обновить» на Android

После установки **из Play Internal** (не sideload) приложение само проверяет
наличие новой версии через **Google Play In-App Updates**:

1. Новый AAB попал в Internal (ручная загрузка или CI).
2. Через некоторое время Play отдаёт update → в приложении диалог / баннер
   «Доступно обновление» (тот же UX, что на вебе).
3. Кнопка **«Обновить»** → immediate/flexible update Play API;
   если API недоступен — открывается страница приложения в Play Store.

**Ограничения**

- Работает только если приложение установлено из Play (Internal/Production).
- `flutter run` / APK с ПК — `checkForUpdate` обычно молчит (это нормально).
- На web по-прежнему сверка `BUILD_ID` с `/api/version` + reload страницы.

Код: `client/lib/core/app_play_update*.dart`, `app_update_provider.dart`.

## 5. Локальный прогон на устройстве (до AAB)

```bash
cd client
flutter run -d android \
  --dart-define=API_BASE=https://multigameszozu-dev.fly.dev
```

## 6. Чеклист перед первой загрузкой

- [ ] `applicationId` = `com.zozugames.app`
- [ ] label = `Zozu Games`
- [ ] `INTERNET` permission в main manifest
- [ ] release keystore + `key.properties`
- [ ] AAB собран с нужным `API_BASE`
- [ ] Internal testing track создан, ты в списке тестеров
- [ ] После второго Internal-релиза: in-app диалог «Обновить» на телефоне

## 7. Позже (не блокер для Internal)

- иконки/feature graphic для Store listing
- Privacy Policy URL
- Data safety form
- Content rating questionnaire
- KZ payments / IAP (отдельный этап)
