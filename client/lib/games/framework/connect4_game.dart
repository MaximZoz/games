import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/screens/connect4_game_screen.dart';
import 'package:multigames_client/screens/connect4_lobby_screen.dart';
import 'package:multigames_client/screens/connect4_offline_screen.dart';

/// Дескриптор «Четыре в ряд».
class Connect4Game extends GameDescriptor {
  @override
  String get id => 'connect4';

  @override
  int get sortOrder => 80;

  @override
  bool get supportsOffline => true;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      Connect4LobbyScreen(lobbyId: lobbyId, initialMode: initialMode);

  @override
  Widget buildGameScreen({required String gameId}) =>
      Connect4GameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) =>
      Connect4OfflineScreen(
        gameMode: Connect4Engine.normalizeMode(query['mode']),
      );
}
