import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/screens/poker_game_screen.dart';
import 'package:multigames_client/screens/poker_lobby_screen.dart';
import 'package:multigames_client/screens/poker_offline_screen.dart';

/// Дескриптор Texas Hold'em Poker. Движок/стол — в `games/poker/`; хром — общий.
class PokerGame extends GameDescriptor {
  @override
  String get id => 'poker';

  @override
  int get sortOrder => 40;

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
      PokerLobbyScreen(
        lobbyId: lobbyId,
        initialMode: initialMode,
      );

  @override
  Widget buildGameScreen({required String gameId}) =>
      PokerGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) {
    final players = (int.tryParse(query['players'] ?? '') ?? 2).clamp(2, 6);
    return PokerOfflineScreen(playerCount: players);
  }
}
