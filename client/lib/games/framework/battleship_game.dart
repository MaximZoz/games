import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/battleship_game_screen.dart';
import 'package:multigames_client/screens/battleship_lobby_screen.dart';
import 'package:multigames_client/screens/battleship_offline_screen.dart';

/// Дескриптор «Морского боя».
class BattleshipGame extends GameDescriptor {
  @override
  String get id => 'battleship';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesBattleship;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      '10×10';

  @override
  int get sortOrder => 30;

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
      BattleshipLobbyScreen(
        lobbyId: lobbyId,
        initialMode: initialMode,
      );

  @override
  Widget buildGameScreen({required String gameId}) =>
      BattleshipGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) =>
      const BattleshipOfflineScreen();
}
