# Как добавить новую игру

Цель: написать **только игру** (движок + экран партии + карточка режимов),
подключить её в реестр — и получить лобби, поиск, инвайты (в т.ч. по ссылке),
флажок сдачи, ничью (1×1), крестик выхода, таймер хода, ставки, статистику,
наблюдение, пуш «ваш ход», WS-навигацию.

## Уже общее (не копировать)

| Слой | Что |
|------|-----|
| Клиент UI | `GameLobbyWaitingLayout`, `LobbyMultiPlayersCard`, `GameActionsOverlay` (флаг/ничья), `handleGameScreenClose`, таймеры хода, `GameRematchSection`, `GameStatusWithReward`, `GameCardShell`, `GameObservationCard` |
| Клиент навигация | `GameRegistry` → пути лобби/партии/оффлайн; `active_game_guard`, `LobbyGameNavigationWatcher` |
| Клиент сессия | `GameSessionApi` (leave/forfeit/draw/resolve type) |
| Клиент настройки | `userGameSettingsProvider(gameType)` + `gameCardSettings(...)` / `GameCardStakeHelper` — кеш + БД |
| Клиент ставки | `game_stake.dart` (банк, места, clamp по балансу) |
| Сервер лобби | `LeaveLobby`, invite/decline/cancel, `GetLobby`, Redis `lobby:*` + `game_type` |
| Сервер итог | observation (`moveActiveToObserving`), WS `game_started` / `game_state`, stats API |
| Сервер ход | `notifyYourTurnUser(gameID, userID, gameType)` — пуш при смене хода |
| Ставки/статы | `/api/games/settings`, `/api/games/stats`, `store.RecordGameResult` |

## Шаги (клиент)

1. Пакет `client/lib/games/<id>/` — движок, repository, providers, rules.
2. Экраны `*_lobby_screen.dart`, `*_game_screen.dart` (+ offline при необходимости).
   - Лобби: собрать на `GameLobbyWaitingLayout`.
   - Шапка: `GameLobbyAppBarTitle` + `lobbyAppBarTitle` — везде «Своя игра» /
     «Лобби», не название игры.
   - Партия: хром через `GameActionsOverlay` + `handleGameScreenClose` + таймеры.
   - Экран партии оборачивать в `SwipeBackScope.gameBoard`, не в обычный
     `SwipeBackScope`. Непрозрачная полоса 48px у левого края перехватывает
     тап по крайней левой кости, карте или клетке. Если рука вдоль низа —
     передать `bottomInset` (как в дураке и Уно, около 42% высоты).
   - Выбывание multi: `enterGameObservation(ref, gameId, gameType: id)`.
3. `GameDescriptor` в `client/lib/games/framework/<id>_game.dart`
   (`id`, `localizedName`, `visibleModeLabel`, экраны).
   - `localizedName` — тот же `.arb`-ключ, что на карточке игры. Статистика,
     список лобби, инвайты и чат берут имя через `localizedGameTypeName`.
   - `visibleModeLabel` — чип режима на карточке лобби. По умолчанию пусто:
     не подставлять «Классика». Переопределять, только если у игры есть
     реальные пользовательские режимы (как короткие/длинные нарды).
4. Зарегистрировать в `GameRegistry` (`_builtinGames` в `game_registry.dart`).
   Имя и режим подхватятся везде, где уже стоит `localizedGameTypeName` /
   `localizedGameModeLabel`.
5. Карточку на «Игры»:
   - hydrate из `userGameSettingsProvider('<id>')`;
   - persist через `gameCardSettings(gameType: '<id>', …)` + `updateLocal`;
   - ставки — `GameCardStakeHelper.availableStakes` / `clampOrKeep`.
6. В `GameSessionApi` — ветки leave/forfeit/draw (или общий HTTP-контракт).
7. В лобби «Своя игра» передать `LobbyShareLinkCard` с `gameType: id` —
   парсер ссылок (`parseInviteLobbyShareUrl`) уже смотрит в `GameRegistry`.

Роутер **уже** строится из реестра (`_gameRoutesFromRegistry`).
Карточка «Наблюдение» уже на вкладке **Лобби** (`GameObservationCard`).

## Шаги (сервер)

1. Движок: `server/internal/<id>/` (как `durak` / `gameengine`).
2. Модуль `server/internal/gameregistry/<id>.go` — `ID`, `Modes`,
   `SupportsOffline`, `SupportsDrawOffer`, `DefaultSettings`.
3. `Registry.Register` в `gameregistry.Default()`.
4. HTTP: handlers Create/Join/Move/Forfeit/Timeout (пока рядом с
   `api/games.go` / отдельный файл; маршрутизация по `/api/games/<id>/…`).
5. В Redis всегда писать `"game_type", "<id>"` на lobby и game.
6. После хода человека/бота/таймаута: `h.notifyYourTurnUser(gameID, nextUserID, "<id>")`.
7. Возврат на вкладку «Игры» (GetActive) не должен попадать в ветку крестиков.
   Игра с `player_ids` и `turn_actor_idx` подхватывается сама: `game_type` из Redis
   сохраняется. Если ход или выбывание сложнее списка мест — в `init()` вызвать
   `RegisterActiveReturn(id, fn)`. Таймаут крестиков к чужому `game_type` не применяется.
   На клиенте экран партии вызывает `pinBlockingGame(ref, gameId, gameType: id)`:
   возврат с «Сообщений» берёт тип из пина и пути реестра (`/games/<id>/game/...`),
   а не из дефолта `tictactoe`.
8. Выбывание multi: `moveActiveToObserving` + observation в GetActive.
   В `ActiveReturn` для выбывшего вернуть `Observe: true`, не `Play`.
9. Финиш: монеты + `store.RecordGameResult` с нужным `GameType`.
10. Settings: ветка в `normalizeGameSettings` / `gameSettingsToJSON`.

## Контракт партии (минимум)

- Участник / выбыл / ход мой — чтобы работали крестик и флажки.
- Таймаут хода (или `turn_time_sec=0`).
- Forfeit; draw только если `SupportsDrawOffer(n)`.
- JSON view для клиента + broadcast `game_state`.

## Чего не обобщать

Движок, payload хода, стол/поле, оффлайн-бот, формулы выплат мест —
остаются в пакете игры.

## Проверка

```bash
cd server && go test ./internal/gameregistry/... ./internal/api/ -count=1
cd client && flutter test test/game_registry_test.dart test/game_stake_test.dart
```
