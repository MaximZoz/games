import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/checkers_game_screen.dart';
import 'package:multigames_client/screens/checkers_lobby_screen.dart';
import 'package:multigames_client/screens/checkers_offline_screen.dart';

/// Дескриптор «Шашки».
class CheckersGame extends GameDescriptor {
  @override
  String get id => 'checkers';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesCheckers;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      checkersModeLabel(
        gameMode.isNotEmpty ? gameMode : variant,
        l10n,
      );

  @override
  int get sortOrder => 70;

  @override
  bool get supportsOffline => true;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      CheckersLobbyScreen(lobbyId: lobbyId, initialMode: initialMode);

  @override
  Widget buildGameScreen({required String gameId}) =>
      CheckersGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) =>
      CheckersOfflineScreen(
        gameMode: CheckersEngine.normalizeMode(query['mode']),
      );
}
