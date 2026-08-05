/// Общая сессия лобби для всех игр (крестики-нолики и дурак).
///
/// **Сервер:** `LeaveLobby` общий — при выходе создателя, если остались
/// игроки, `creator_id` передаётся следующему (invite и matchmake).
/// Приглашать может любой участник лобби.
///
/// **UI-скелет ожидания:** [GameLobbyWaitingLayout] в
/// `ui/widgets/game_lobby_widgets.dart` — чип ставки / карточка «Игроки N/M»,
/// ссылка, друзья. Дурак уже на нём; крестики подключают те же виджеты
/// (stake chip, share link, leave dialog, rules dialog).
///
/// **Правила:** [showGameRulesDialog] + `stakeBronze` из лобби/карточки создания.
library;

/// Тип игры в путях `/games/<kind>/lobby/...`.
abstract final class LobbyGameKind {
  static const tictactoe = 'tictactoe';
  static const durak = 'durak';

  static String normalize(String? raw) {
    final v = raw?.trim() ?? '';
    if (v == durak) return durak;
    return tictactoe;
  }

  static String lobbyPath(String lobbyId, {required String gameType}) {
    final kind = normalize(gameType);
    return '/games/$kind/lobby/${lobbyId.trim()}';
  }
}
