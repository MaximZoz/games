import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/screens/battleship_game_screen.dart';
import 'package:multigames_client/screens/battleship_lobby_screen.dart';
import 'package:multigames_client/screens/battleship_offline_screen.dart';

/// Дескриптор «Морского боя».
class BattleshipGame extends GameDescriptor {
  @override
  String get id => 'battleship';

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
