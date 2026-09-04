import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/nardy_game_screen.dart';
import 'package:multigames_client/screens/nardy_lobby_screen.dart';
import 'package:multigames_client/screens/nardy_offline_screen.dart';

/// Дескриптор «Нард».
class NardyGame extends GameDescriptor {
  @override
  String get id => 'nardy';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesNardy;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      nardyModeLabel(
        gameMode.isNotEmpty ? gameMode : variant,
        l10n,
      );

  @override
  int get sortOrder => 60;

  @override
  bool get supportsOffline => true;

  @override
  bool supportsDrawOffer(int playerCount) => false;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      NardyLobbyScreen(lobbyId: lobbyId, initialMode: initialMode);

  @override
  Widget buildGameScreen({required String gameId}) =>
      NardyGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) =>
      NardyOfflineScreen(
        gameMode: nardyNormalizeMode(query['mode']),
      );
}
