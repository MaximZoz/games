import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/game_navigation.dart';

void main() {
  test('registry contains tictactoe and durak', () {
    expect(gameRegistry.contains('tictactoe'), isTrue);
    expect(gameRegistry.contains('durak'), isTrue);
    expect(gameRegistry.contains('chess'), isFalse);
    expect(gameRegistry.contains(null), isFalse);
    expect(gameRegistry.all.map((g) => g.id).toList(),
        containsAll(['tictactoe', 'durak']));
  });

  test('normalize unknown falls back to tictactoe', () {
    expect(gameRegistry.normalizeId(null), 'tictactoe');
    expect(gameRegistry.normalizeId(''), 'tictactoe');
    expect(gameRegistry.normalizeId('nope'), 'tictactoe');
    expect(gameRegistry.normalizeId('durak'), 'durak');
  });

  test('paths and parse round-trip via navigation helpers', () {
    expect(gamePathFor('abc', gameType: 'durak'), '/games/durak/game/abc');
    expect(lobbyPathFor('L1', gameType: 'tictactoe'),
        '/games/tictactoe/lobby/L1');
    expect(gameIdFromGamePath('/games/durak/game/xyz?x=1'), 'xyz');
    expect(gameTypeFromGamePath('/games/durak/lobby/L'), 'durak');
    expect(normalizeGameType('durak'), 'durak');
  });

  test('draw offer policy', () {
    final ttt = gameRegistry['tictactoe']!;
    expect(ttt.supportsDrawOffer(2), isTrue);
    expect(ttt.supportsDrawOffer(3), isFalse);
  });
}
