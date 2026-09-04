import 'package:flutter/widgets.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/offline_tictactoe_screen.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';
import 'package:multigames_client/screens/tictactoe_lobby_screen.dart';

/// Дескриптор крестиков-ноликов: экраны + пути. Карточка/режимы пока в
/// `games_screen.dart` (_TictactoeGameCard) — следующий шаг выноса UI.
class TicTacToeGame extends GameDescriptor {
  @override
  String get id => 'tictactoe';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesTicTacToe;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) {
    switch (parseVariant(variant)) {
      case variantGomoku:
        return l10n.gamesVariantGomoku;
      case variantUltimate:
        return l10n.gamesVariantUltimate;
      case variantMulti3:
        return l10n.gamesVariantMulti3;
      case variantMulti4:
        return l10n.gamesVariantMulti4;
      case variantClassic:
      default:
        return l10n.gamesVariantClassic;
    }
  }

  @override
  int get sortOrder => 10;

  @override
  bool get supportsOffline => true;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      TicTacToeLobbyScreen(
        lobbyId: lobbyId,
        initialMode: initialMode,
        fromMessageId: fromMessageId,
      );

  @override
  Widget buildGameScreen({required String gameId}) =>
      TicTacToeGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) {
    final grid = int.tryParse(query['grid'] ?? '') ?? 3;
    final variant = parseVariant(query['variant']);
    return OfflineTicTacToeScreen(
      variant: variant,
      gridSize: grid,
      swapRule: query['swap'] == '1',
      firstMoveRestriction: query['nocenter'] == '1',
    );
  }
}
