import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/chess_game_screen.dart';
import 'package:multigames_client/screens/chess_lobby_screen.dart';
import 'package:multigames_client/screens/chess_offline_screen.dart';

/// Дескриптор «Шахматы».
class ChessGame extends GameDescriptor {
  @override
  String get id => 'chess';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesChess;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      chessModeLabel(
        gameMode.isNotEmpty ? gameMode : variant,
        l10n,
      );

  @override
  int get sortOrder => 80;

  @override
  bool get supportsOffline => true;

  @override
  bool supportsDrawOffer(int playerCount) => playerCount == 2;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      ChessLobbyScreen(lobbyId: lobbyId, initialMode: initialMode);

  @override
  Widget buildGameScreen({required String gameId}) =>
      ChessGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) =>
      ChessOfflineScreen(
        gameMode: ChessEngine.normalizeMode(query['mode']),
      );
}
