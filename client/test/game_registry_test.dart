import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/game_navigation.dart';

void main() {
  test('registry contains tictactoe, durak and battleship', () {
    expect(gameRegistry.contains('tictactoe'), isTrue);
    expect(gameRegistry.contains('durak'), isTrue);
    expect(gameRegistry.contains('battleship'), isTrue);
    expect(gameRegistry.contains('chess'), isFalse);
    expect(gameRegistry.contains(null), isFalse);
    expect(gameRegistry.all.map((g) => g.id).toList(),
        containsAll(['tictactoe', 'durak', 'battleship']));
  });

  test('normalize unknown falls back to tictactoe', () {
    expect(gameRegistry.normalizeId(null), 'tictactoe');
    expect(gameRegistry.normalizeId(''), 'tictactoe');
    expect(gameRegistry.normalizeId('nope'), 'tictactoe');
    expect(gameRegistry.normalizeId('durak'), 'durak');
    expect(gameRegistry.normalizeId('battleship'), 'battleship');
  });

  test('paths and parse round-trip via navigation helpers', () {
    expect(gamePathFor('abc', gameType: 'durak'), '/games/durak/game/abc');
    expect(gamePathFor('bs1', gameType: 'battleship'),
        '/games/battleship/game/bs1');
    expect(lobbyPathFor('L1', gameType: 'tictactoe'),
        '/games/tictactoe/lobby/L1');
    expect(gameIdFromGamePath('/games/durak/game/xyz?x=1'), 'xyz');
    expect(gameTypeFromGamePath('/games/durak/lobby/L'), 'durak');
    expect(gameTypeFromGamePath('/games/battleship/lobby/L2'), 'battleship');
    expect(normalizeGameType('durak'), 'durak');
    expect(normalizeGameType('battleship'), 'battleship');
  });

  test('draw offer policy', () {
    final ttt = gameRegistry['tictactoe']!;
    expect(ttt.supportsDrawOffer(2), isTrue);
    expect(ttt.supportsDrawOffer(3), isFalse);
    final bs = gameRegistry['battleship']!;
    expect(bs.supportsDrawOffer(2), isFalse);
  });

  test('offline supported for tictactoe, durak, battleship', () {
    expect(gameRegistry['tictactoe']!.supportsOffline, isTrue);
    expect(gameRegistry['durak']!.supportsOffline, isTrue);
    expect(gameRegistry['battleship']!.supportsOffline, isTrue);
    expect(gameRegistry['battleship']!.offlinePath, '/games/battleship/offline');
  });
}
