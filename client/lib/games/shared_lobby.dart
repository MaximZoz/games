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
/// **Шапка:** [lobbyAppBarTitle] + `GameLobbyAppBarTitle` — везде «Своя игра»
/// или «Лобби», без названия конкретной игры.
///
/// **Правила:** [showGameRulesDialog] + `stakeBronze` из лобби/карточки создания.
///
/// **Реестр:** [GameRegistry] / [LobbyGameKind] — id и пути без хардкода.
library;

import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/framework/game_registry.dart';

/// Тип игры в путях `/games/<kind>/lobby/...`.
/// Делегирует в [gameRegistry] — при новой игре править реестр, не этот файл.
abstract final class LobbyGameKind {
  static const tictactoe = 'tictactoe';
  static const durak = 'durak';
  static const poker = 'poker';
  static const uno = 'uno';
  static const nardy = 'nardy';
  static const battleship = 'battleship';

  static String normalize(String? raw) => gameRegistry.normalizeId(raw);

  static String lobbyPath(String lobbyId, {required String gameType}) =>
      gameRegistry.lobbyPath(lobbyId, gameType: gameType);
}

/// `invite` | `matchmake` | пусто, если режим ещё неизвестен.
String normalizeLobbyMode(String? mode) {
  final v = (mode ?? '').trim();
  if (v == 'invite' || v == 'matchmake') return v;
  return '';
}

/// Заголовок AppBar лобби — один для всех игр.
///
/// Пока деталь не загружена, опираемся на [initialMode] из query
/// (`?mode=invite|matchmake`). Открытый поиск: mode=matchmake → «Лобби».
/// Своя игра: mode=invite → «Своя игра». Ссылки из чата ([fromInviteLink])
/// для гостя — «Войти в игру».
String lobbyAppBarTitle({
  String? status,
  String? initialMode,
  String? lobbyMode,
  bool fromInviteLink = false,
  bool isLobbyMember = false,
}) {
  final l10n = LocaleService.l10n;
  final mode = normalizeLobbyMode(
    (lobbyMode != null && lobbyMode.trim().isNotEmpty)
        ? lobbyMode
        : initialMode,
  );
  if (status == 'waiting_matchmake') return l10n.lobbyMatchmake;
  if (status == 'waiting_invite') {
    if (mode == 'matchmake') return l10n.lobbyMatchmake;
    if (isLobbyMember || !fromInviteLink) return l10n.lobbyPrivateGame;
    return l10n.lobbyEnterGame;
  }
  if (fromInviteLink && !isLobbyMember) return l10n.lobbyEnterGame;
  if (mode == 'matchmake') return l10n.lobbyMatchmake;
  if (mode == 'invite') return l10n.lobbyPrivateGame;
  return '';
}
