import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/game_navigation.dart';

void main() {
  group('GameNavigationCoordinator', () {
    test('does not suppress a retry before the target route is observed', () {
      final coordinator = GameNavigationCoordinator();

      expect(
        coordinator.targetForGame('game-1', currentPath: '/games'),
        '/games/tictactoe/game/game-1',
      );
      expect(
        coordinator.targetForGame('game-1', currentPath: '/games'),
        '/games/tictactoe/game/game-1',
      );
    });

    test('does not navigate when already in the target game', () {
      final coordinator = GameNavigationCoordinator();

      expect(
        coordinator.targetForGame(
          'game-1',
          currentPath: '/games/tictactoe/game/game-1',
        ),
        isNull,
      );
    });
  });

  testWidgets(
      'accept completion navigates and the matching event deduplicates by route',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/games',
      routes: [
        GoRoute(
          path: '/games',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(
          path: '/games/tictactoe/game/:gameId',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final coordinator = GameNavigationCoordinator();
    expect(navigateToGame(router, coordinator, 'game-1'), isTrue);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/games/tictactoe/game/game-1',
    );

    final eventNav = realtimeGameNavForEvent(
      const {'type': 'game_started', 'game_id': 'game-1'},
      currentPath: '/games',
    );
    expect(
      navigateToGame(router, coordinator, eventNav?.gameId),
      isFalse,
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/games/tictactoe/game/game-1',
    );
  });

  testWidgets('game event navigates the router when accept response is delayed',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/games',
      routes: [
        GoRoute(
          path: '/games',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(
          path: '/games/tictactoe/game/:gameId',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final nav = realtimeGameNavForEvent(
      const {'type': 'lobby_updated', 'game_id': 'game-2'},
      currentPath: router.routerDelegate.currentConfiguration.uri.path,
    );
    expect(
      navigateToGame(router, GameNavigationCoordinator(), nav?.gameId),
      isTrue,
    );
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/games/tictactoe/game/game-2',
    );
  });

  group('realtimeGameNavForEvent', () {
    test('accepts game_started and lobby_updated with a game id', () {
      expect(
        realtimeGameNavForEvent(
          const {'type': 'game_started', 'game_id': 'game-1'},
          currentPath: '/games',
        )?.gameId,
        'game-1',
      );
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'lobby_updated',
            'lobby_id': 'lobby-1',
            'game_id': 'game-2',
          },
          currentPath: '/games/tictactoe/lobby/lobby-1',
        )?.gameId,
        'game-2',
      );
    });

    test('navigates from chats/friends when a game starts', () {
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'game_started',
            'lobby_id': 'lobby-1',
            'game_id': 'game-1',
          },
          currentPath: '/chats',
        )?.gameId,
        'game-1',
      );
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'lobby_updated',
            'lobby_id': 'lobby-1',
            'game_id': 'game-2',
          },
          currentPath: '/friends',
          expectedLobbyId: 'lobby-1',
        )?.gameId,
        'game-2',
      );
    });

    test('ignores auth routes and lobby updates without a game', () {
      expect(
        realtimeGameNavForEvent(
          const {'type': 'game_started', 'game_id': 'game-1'},
          currentPath: '/login',
        ),
        isNull,
      );
      expect(
        realtimeGameNavForEvent(
          const {'type': 'lobby_updated', 'left': true},
          currentPath: '/games',
        ),
        isNull,
      );
    });

    test('ignores an event for a different lobby', () {
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'game_started',
            'lobby_id': 'lobby-2',
            'game_id': 'game-2',
          },
          currentPath: '/games/tictactoe/lobby/lobby-1',
          expectedLobbyId: 'lobby-1',
        ),
        isNull,
      );
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'game_started',
            'lobby_id': 'lobby-2',
            'game_id': 'game-2',
          },
          currentPath: '/chats',
          expectedLobbyId: 'lobby-1',
        ),
        isNull,
      );
    });

    test('keeps game_type from event when present', () {
      expect(
        realtimeGameNavForEvent(
          const {
            'type': 'game_started',
            'game_id': 'game-1',
            'game_type': 'durak',
          },
          currentPath: '/games',
        )?.gameType,
        'durak',
      );
    });
  });
}
