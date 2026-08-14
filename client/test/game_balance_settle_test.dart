import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  test('gameBalanceSettledIdsProvider remembers settled game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gameBalanceSettledIdsProvider), isEmpty);
    container.read(gameBalanceSettledIdsProvider.notifier).state = {'g1'};
    expect(container.read(gameBalanceSettledIdsProvider).contains('g1'), isTrue);
    expect(container.read(gameBalanceSettledIdsProvider).contains('g2'), isFalse);
  });

  test('observationGameProvider marks observe re-entry gameId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(observationGameProvider.notifier).state = ObservationItem(
      gameId: 'obs-1',
      lobbyId: 'lobby',
      gameType: 'poker',
    );
    expect(
      container.read(observationGameProvider)?.gameId,
      'obs-1',
    );
  });
}
