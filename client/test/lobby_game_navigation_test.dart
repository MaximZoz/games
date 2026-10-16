import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/lobby_game_navigation.dart';

void main() {
  testWidgets('matching realtime lobby event navigates exactly once',
      (tester) async {
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final pendingLobby = Completer<LobbyItem>();
    final router = _router(pollInterval: const Duration(hours: 1));
    addTearDown(events.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realtimeEventsProvider.overrideWith((ref) => events.stream),
          lobbyDetailProvider.overrideWith(
            (ref, lobbyId) => pendingLobby.future,
          ),
          // Реальный recovery ходит в SharedPreferences и оставляет
          // двухсекундный таймер после ухода с лобби.
          lobbyGameRecoveryProvider.overrideWith((ref, lobbyId) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    events.add(const {
      'type': 'game_started',
      'lobby_id': 'other-lobby',
      'game_id': 'wrong-game',
    });
    await tester.pump();
    expect(_path(router), '/games/tictactoe/lobby/lobby-1');

    events.add(const {
      'type': 'game_started',
      'lobby_id': 'lobby-1',
      'game_id': 'game-1',
    });
    await tester.pump();
    await tester.pump();
    expect(_path(router), '/games/tictactoe/game/game-1');

    events.add(const {
      'type': 'lobby_updated',
      'lobby_id': 'lobby-1',
      'game_id': 'game-1',
    });
    await tester.pump();
    expect(_path(router), '/games/tictactoe/game/game-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('polling recovers when the realtime event is missed',
      (tester) async {
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final pendingLobby = Completer<LobbyItem>();
    var recoveryCalls = 0;
    final router = _router(pollInterval: const Duration(hours: 1));
    addTearDown(events.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realtimeEventsProvider.overrideWith((ref) => events.stream),
          lobbyDetailProvider.overrideWith(
            (ref, lobbyId) => pendingLobby.future,
          ),
          lobbyGameRecoveryProvider.overrideWith((ref, lobbyId) async {
            recoveryCalls++;
            return lobbyId == 'lobby-1' ? 'game-from-poll' : null;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Первый кадр + post-frame poll сразу уводит в игру без WS.
    await tester.pump();
    await tester.pump();

    expect(recoveryCalls, greaterThanOrEqualTo(1));
    expect(_path(router), '/games/tictactoe/game/game-from-poll');
    expect(tester.takeException(), isNull);
  });
}

GoRouter _router({required Duration pollInterval}) {
  return GoRouter(
    initialLocation: '/games/tictactoe/lobby/lobby-1',
    routes: [
      GoRoute(
        path: '/games/tictactoe/lobby/:lobbyId',
        builder: (_, state) => LobbyGameNavigationWatcher(
          lobbyId: state.pathParameters['lobbyId']!,
          pollInterval: pollInterval,
          child: const Text('waiting'),
        ),
      ),
      GoRoute(
        path: '/games/tictactoe/game/:gameId',
        builder: (_, state) => Text('game ${state.pathParameters['gameId']}'),
      ),
    ],
  );
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;
