/// Общая сессия лобби для всех игр.
///
/// **Сервер:** `LeaveLobby` общий — при выходе создателя, если остались
/// игроки, `creator_id` передаётся следующему (invite и matchmake).
/// Приглашать может любой участник лобби.
///
/// **UI-скелет ожидания:** [GameLobbyWaitingLayout] + [LobbyMultiPlayersCard]
/// + [LobbyFriendsInviteCard] в `ui/widgets/game_lobby_widgets.dart` —
/// чип ставки / карточка «Игроки N/M» со слотами аватаров и чатом, ссылка,
/// друзья с presence («Онлайн»). Игры инжектят данные.
///
/// **Правила:** [showGameRulesDialog] + `stakeBronze` из лобби/карточки создания.
///
/// **Реестр:** [GameRegistry] / [LobbyGameKind] — id и пути без хардкода.
library;

import 'package:multigames_client/games/framework/game_registry.dart';

/// Тип игры в путях `/games/<kind>/lobby/...`.
/// Делегирует в [gameRegistry] — при новой игре править реестр, не этот файл.
abstract final class LobbyGameKind {
  static const tictactoe = 'tictactoe';
  static const durak = 'durak';
  static const poker = 'poker';
  static const uno = 'uno';

  static String normalize(String? raw) => gameRegistry.normalizeId(raw);

  static String lobbyPath(String lobbyId, {required String gameType}) =>
      gameRegistry.lobbyPath(lobbyId, gameType: gameType);
}
