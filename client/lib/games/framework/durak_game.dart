import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/screens/durak_game_screen.dart';
import 'package:multigames_client/screens/durak_lobby_screen.dart';
import 'package:multigames_client/screens/durak_offline_screen.dart';

/// Дескриптор Дурака. Движок/стол — в `games/durak/`; лобби и хром — общие.
class DurakGame extends GameDescriptor {
  @override
  String get id => 'durak';

  @override
  int get sortOrder => 20;

  @override
  bool get supportsOffline => true;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      DurakLobbyScreen(
        lobbyId: lobbyId,
        initialMode: initialMode,
      );

  @override
  Widget buildGameScreen({required String gameId}) =>
      DurakGameScreen(gameId: gameId);

  @override
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) {
    final size = int.tryParse(query['deck'] ?? '') ?? 36;
    final players = (int.tryParse(query['players'] ?? '') ?? 2).clamp(2, 4);
    final mode =
        query['mode'] == 'perevodnoi' ? 'perevodnoi' : 'podkidnoi';
    return DurakOfflineScreen(
      deckSize: size,
      playerCount: players,
      mode: mode,
    );
  }
}
