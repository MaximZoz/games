import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/domino_game_screen.dart';
import 'package:multigames_client/screens/domino_lobby_screen.dart';
import 'package:multigames_client/screens/domino_offline_screen.dart';

class DominoGame extends GameDescriptor {
  @override
  String get id => 'domino';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesDomino;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      dominoModeLabel(gameMode.isNotEmpty ? gameMode : variant, l10n);

  @override
  int get sortOrder => 45;

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
      DominoLobbyScreen(lobbyId: lobbyId, initialMode: initialMode);

  @override
  Widget buildGameScreen({required String gameId}) =>
      DominoGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) {
    final players = (int.tryParse(query['players'] ?? '') ?? 2).clamp(2, 4);
    return DominoOfflineScreen(
      playerCount: players,
      gameMode: dominoNormalizeMode(query['mode']),
    );
  }
}
