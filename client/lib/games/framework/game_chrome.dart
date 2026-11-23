/// Общий UI-хром партии — что подключать в каждом game screen.
///
/// Каркас подключается одним виджетом и одинаков у всех игр:
///
/// - [GameScreenScaffold] + [GameChrome] — шапка: крестик, название, таймер
///   своего хода сразу перед кнопкой правил; под правилами столбиком
///   «сдаться» и «ничья». Игра передаёт только колбэки и [GameTurnClock].
/// - [GameOpponentPanel] + [GameOpponent] — карточка соперника: фиолетовая
///   рамка, которая в его ход становится таймером; профиль, чат и «в друзья»
///   подключены внутри.
/// - [forgetGameSession] — выход в каталог «Игры» без возврата на стол.
///
/// Компоненты стола (палитра, поверхность, полёты фишек, рука, россыпь) —
/// в пакете `multigames_game_kit`; токены и базовые виджеты — в
/// `multigames_ui`.
///
/// Остальное — из `ui/widgets/game_screen_widgets.dart`:
///
/// - [GameActionsOverlay] — флаг «сдаться» + рукопожатие «ничья»
/// - [handleGameScreenClose] / [confirmGameActionDialog] — крестик / свайп назад.
///   Сам экран — в `SwipeBackScope.gameBoard`: обычный `SwipeBackScope`
///   рисует непрозрачную полосу у левого края и съедает крайнюю кость.
/// - [GameTurnCountdown], [TurnTimerBorder], [TurnTimerAppFrame], [MyTurnAlert] / [MyTurnAlert.stackLeaf] — таймер и сигнал хода
/// - [GameActorHighlight] — чей ход: рамка с таймером или без лимита времени
/// - [GameRematchSection] — «Повторить» / «Другой соперник»
/// - [GameStatusWithReward], [GameRewardChip] — статус + монеты
/// - [GameConfettiOverlay] — салют призового места
///
/// Лобби — `ui/widgets/game_lobby_widgets.dart`:
/// [GameLobbyWaitingLayout], [LobbyMultiPlayersCard].
///
/// Карточка на «Игры» — `ui/widgets/game_card_widgets.dart`:
/// [GameCardShell], [showGameRulesDialog].
///
/// Политики (можно ли ничью при N игроках) — [GameDescriptor.supportsDrawOffer].
library;

export 'game_descriptor.dart' show GameSessionCapabilities, GameDescriptor;
export 'game_opponent_panel.dart';
export 'game_screen_scaffold.dart';
export 'game_session_exit.dart';
