/// Общий UI-хром партии — что подключать в каждом game screen.
///
/// Импортируйте виджеты из `ui/widgets/game_screen_widgets.dart`:
///
/// - [GameActionsOverlay] — флаг «сдаться» + рукопожатие «ничья»
/// - [handleGameScreenClose] / [confirmGameActionDialog] — крестик / свайп назад
/// - [GameTurnCountdown], [TurnTimerBorder], [TurnTimerAppFrame] — таймер хода
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
