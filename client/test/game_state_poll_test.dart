import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';

class _FakeGamesRepo extends GamesRepository {
  _FakeGamesRepo() : super(authRepository: AuthRepository());

  int gets = 0;

  @override
  Future<GameStateItem> getGame(String gameId) async {
    gets++;
    return GameStateItem(
      id: gameId,
      board: List<String>.filled(9, ''),
      turn: 'X',
      status: 'active',
      xUserId: 'u1',
      oUserId: 'u2',
    );
  }
}

void main() {
  test('HTTP poll refreshes even when game_state invalidate is blocked', () async {
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
    await container.read(gameStateProvider('g1').future);
    expect(repo.gets, 1);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await container.read(gameStateProvider('g1').future);
    expect(repo.gets, greaterThan(1));
  });
}
