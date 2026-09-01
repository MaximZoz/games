import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/live_game_sync.dart';

class _FakeGamesRepo extends GamesRepository {
  _FakeGamesRepo() : super(authRepository: AuthRepository());

  int gets = 0;
  List<String> board = List<String>.filled(9, '');

  @override
  Future<GameStateItem> getGame(String gameId) async {
    gets++;
    return GameStateItem(
      id: gameId,
      board: List<String>.from(board),
      turn: 'x',
      status: 'active',
      xUserId: 'u1',
      oUserId: 'u2',
    );
  }
}

void main() {
  test('HTTP reconcile still runs when leftover invalidate-block is set',
      () async {
    final repo = _FakeGamesRepo();
    final container = ProviderContainer(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(repo),
        realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);

    container.read(gameStateInvalidateBlockedProvider('g1').notifier).state =
        true;
    final sub = container.listen(gameStateProvider('g1'), (_, __) {});
    addTearDown(sub.close);
    await container.read(gameStateProvider('g1').future);
    expect(repo.gets, 1);

    await Future<void>.delayed(
      kGameStateReconcileInterval + const Duration(milliseconds: 300),
    );
    expect(repo.gets, greaterThan(1));
  });

  test('applies opponent move from WS without extra HTTP', () async {
    final repo = _FakeGamesRepo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(events.close);
    final container = ProviderContainer(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(repo),
        realtimeEventsProvider.overrideWith((ref) => events.stream),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(gameStateProvider('g1'), (_, __) {});
    addTearDown(sub.close);
    await container.read(gameStateProvider('g1').future);
    expect(repo.gets, 1);

    events.add({
      'type': 'game_state',
      'game_id': 'g1',
      'board': ['x', '', '', '', '', '', '', '', ''],
      'turn': 'o',
      'status': 'active',
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final view = container.read(gameStateProvider('g1')).valueOrNull;
    expect(view, isNotNull);
    expect(view!.board[0], 'x');
    expect(view.turn, 'o');
    expect(view.xUserId, 'u1');
    expect(repo.gets, 1);
  });

  test('stale HTTP does not roll back a newer WS board', () async {
    final repo = _FakeGamesRepo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(events.close);
    final container = ProviderContainer(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(repo),
        realtimeEventsProvider.overrideWith((ref) => events.stream),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(gameStateProvider('g1'), (_, __) {});
    addTearDown(sub.close);
    await container.read(gameStateProvider('g1').future);
    events.add({
      'type': 'game_state',
      'game_id': 'g1',
      'board': ['x', 'o', '', '', '', '', '', '', ''],
      'turn': 'x',
      'status': 'active',
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(gameStateProvider('g1')).valueOrNull!.filledCellCount,
      2,
    );

    repo.board = ['x', '', '', '', '', '', '', '', ''];
    await container.read(gameStateProvider('g1').notifier).reconcile();
    expect(
      container.read(gameStateProvider('g1')).valueOrNull!.filledCellCount,
      2,
    );
  });
}
