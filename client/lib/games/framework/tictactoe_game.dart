import 'package:flutter/widgets.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/screens/offline_tictactoe_screen.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';
import 'package:multigames_client/screens/tictactoe_lobby_screen.dart';

/// Дескриптор крестиков-ноликов: экраны + пути. Карточка/режимы пока в
/// `games_screen.dart` (_TictactoeGameCard) — следующий шаг выноса UI.
class TicTacToeGame extends GameDescriptor {
  @override
  String get id => 'tictactoe';

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
