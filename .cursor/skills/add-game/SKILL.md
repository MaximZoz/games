---
name: add-game
description: >-
  Добавить новую игру в Zozu Games: движок, экран партии, карточка режимов,
  регистрация в GameRegistry и gameregistry. Использовать, когда просят новую
  игру, новый game type, лобби, инвайт, офлайн-бота или карточку на экране
  «Игры». Не использовать для правки правил уже существующей игры.
---

# Новая игра

Сначала прочитай [docs/ADDING_A_GAME.md](../../../docs/ADDING_A_GAME.md) и одну соседнюю игру того же вида (поле — шашки или шахматы, карты — дурак или UNO, стрельба — морской бой). Пиши только движок, экран и карточку. Лобби, поиск, инвайт по ссылке, сдача, ничья 1×1, таймер хода, ставки, статистика, наблюдение и пуш «ваш ход» уже общие.

## Не копировать

- Клиент: `GameLobbyWaitingLayout`, `GameScreenScaffold` + `GameChrome` (шапка, таймер своего хода, флаг и ничья), `GameOpponentPanel`, `forgetGameSession`, `handleGameScreenClose`, `GameRematchSection`, `GameCardShell`, `userGameSettingsProvider`, `GameCardStakeHelper`.
- Сервер: лобби в Redis `lobby:*`, `notifyYourTurnUser`, `store.RecordGameResult`, `/api/games/settings` и `/api/games/stats`.
- Роутер уже собирается из реестра (`_gameRoutesFromRegistry`). Отдельный `GoRoute` на лобби не добавляй.

## Клиент

1. Пакет `client/lib/games/<id>/`: движок, repository, provider, правила.
2. Экраны лобби и партии. Лобби собери на `GameLobbyWaitingLayout`. Шапка — `GameLobbyAppBarTitle` («Своя игра» / «Лобби»), не название игры.
3. Экран партии — `GameScreenScaffold(chrome: GameChrome(...), body: ...)` из `client/lib/games/framework/game_chrome.dart`. Свой `Scaffold`, `AppBar`, таймер, флаг и ничью не верстай: опиши их в `GameChrome` (`onClose`, `onShowRules`, `turn`, `onSurrender`, `draw`), каркас сам ставит таймер своего хода перед правилами и столбик действий под ними. Соперник — `GameOpponentPanel` (профиль, чат, рамка-таймер его хода). Цвета — только `GamePalette` (своих `Color(0x…)` не заводи, это проверяет `client/test/game_palette_usage_test.dart`; на тёмном сукне — `GameChrome(railOnDark: true)`), полёты фишек — `GameFlightStage` + `GameFlightController`, рука — `GameHandStrip` из пакета `multigames_game_kit`. Выход в каталог — `forgetGameSession`.
   Каркас оберни в `SwipeBackScope.gameBoard`. Обычный `SwipeBackScope` ставит непрозрачную полосу 48px слева и съедает тап по крайней клетке или карте. Рука вдоль низа — `bottomInset`, как у дурака и UNO.
4. `GameDescriptor` в `client/lib/games/framework/<id>_game.dart`. `id` совпадает с `game_type`. `localizedName` возвращает ключ из `.arb` (как `l10n.gamesDurak`), не сырой id. `visibleModeLabel` оставь пустым, если у игры нет настоящих режимов. Не подставляй «Классика».
5. Зарегистрируй дескриптор в `_builtinGames()` в `client/lib/games/framework/game_registry.dart`.
6. Карточка на экране «Игры»: чтение `userGameSettingsProvider('<id>')`, запись через `gameCardSettings` и `updateLocal`, ставки через `GameCardStakeHelper`.
7. В лобби «Своя игра» передай `LobbyShareLinkCard` с `gameType: id`.
8. Экран партии вызывает `pinBlockingGame(ref, gameId, gameType: id)`, чтобы возврат с «Сообщений» не открывал крестики-нолики.
9. Имя игры добавь во все `client/lib/l10n/app_*.arb` и сгенерируй `flutter gen-l10n`. Шаблон — `app_ru.arb`.

## Сервер

1. Движок: `server/internal/<id>/`.
2. Модуль `server/internal/gameregistry/<id>.go`: `ID`, режимы, `SupportsOffline`, `SupportsDrawOffer`, настройки по умолчанию.
3. `Registry.Register` в `gameregistry.Default()`.
4. HTTP Create/Join/Move/Forfeit/Timeout на `/api/games/<id>/…`.
5. В Redis на lobby и game всегда пиши поле `game_type` равным `<id>`.
6. После хода человека, бота или таймаута вызови `notifyYourTurnUser(gameID, nextUserID, "<id>")`.
7. Если ход или выбывание сложнее списка `player_ids` и `turn_actor_idx`, зарегистрируй `RegisterActiveReturn`. Иначе возврат на «Игры» попадёт в ветку крестиков.
8. Выбывший в multi получает `Observe: true` через `moveActiveToObserving`, не `Play`.
9. Финиш пишет монеты и `store.RecordGameResult` с этим `GameType`.
10. Настройки пройди через `normalizeGameSettings` / `gameSettingsToJSON`.

Движок, payload хода, стол и формулу выплат оставь в пакете игры.

## Офлайн

Если у дескриптора `supportsOffline` и на сервере `SupportsOffline`, сразу открой skill `offline-session` и заведи локальную партию с ботом тем же экраном, что и онлайн.

## Проверка

```bash
cd server && go test ./internal/gameregistry/... ./internal/<id>/... ./internal/api/ -count=1
cd client && flutter test test/game_registry_test.dart test/game_stake_test.dart test/game_chrome_test.dart
```

Плюс тест движка новой игры. `go vet ./...` в `server/` и `flutter analyze --no-fatal-infos` в `client/`.

Готово, когда игра есть в обоих реестрах, карточка открывает лобби, инвайт ведёт в этот `game_type`, а неизвестный тип по-прежнему не подменяет чужую партию на крестики.
