import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/game_navigation.dart';

void main() {
  test('registry contains all built-in games', () {
    expect(gameRegistry.contains('tictactoe'), isTrue);
    expect(gameRegistry.contains('durak'), isTrue);
    expect(gameRegistry.contains('battleship'), isTrue);
    expect(gameRegistry.contains('poker'), isTrue);
    expect(gameRegistry.contains('uno'), isTrue);
    expect(gameRegistry.contains('nardy'), isTrue);
    expect(gameRegistry.contains('checkers'), isTrue);
    expect(gameRegistry.contains('connect4'), isTrue);
    expect(gameRegistry.contains('chess'), isFalse);
    expect(gameRegistry.contains(null), isFalse);
    expect(
        gameRegistry.all.map((g) => g.id).toList(),
        containsAll([
          'tictactoe',
          'durak',
          'battleship',
          'uno',
          'poker',
          'nardy',
          'checkers',
          'connect4',
        ]));
  });

  test('normalize unknown falls back to tictactoe', () {
    expect(gameRegistry.normalizeId(null), 'tictactoe');
    expect(gameRegistry.normalizeId(''), 'tictactoe');
    expect(gameRegistry.normalizeId('nope'), 'tictactoe');
    expect(gameRegistry.normalizeId('durak'), 'durak');
    expect(gameRegistry.normalizeId('battleship'), 'battleship');
    expect(gameRegistry.normalizeId('poker'), 'poker');
    expect(gameRegistry.normalizeId('uno'), 'uno');
  });

  test('paths and parse round-trip via navigation helpers', () {
    expect(gamePathFor('abc', gameType: 'durak'), '/games/durak/game/abc');
    expect(gamePathFor('bs1', gameType: 'battleship'),
        '/games/battleship/game/bs1');
    expect(
        lobbyPathFor('L1', gameType: 'tictactoe'), '/games/tictactoe/lobby/L1');
    expect(gameIdFromGamePath('/games/durak/game/xyz?x=1'), 'xyz');
    expect(gameTypeFromGamePath('/games/durak/lobby/L'), 'durak');
    expect(gameTypeFromGamePath('/games/battleship/lobby/L2'), 'battleship');
    expect(normalizeGameType('durak'), 'durak');
    expect(normalizeGameType('battleship'), 'battleship');
    expect(gamePathFor('u1', gameType: 'uno'), '/games/uno/game/u1');
    expect(normalizeGameType('uno'), 'uno');
  });

  test('draw offer policy', () {
    final ttt = gameRegistry['tictactoe']!;
    expect(ttt.supportsDrawOffer(2), isTrue);
    expect(ttt.supportsDrawOffer(3), isFalse);
    final bs = gameRegistry['battleship']!;
    expect(bs.supportsDrawOffer(2), isFalse);
    final poker = gameRegistry['poker']!;
    expect(poker.supportsDrawOffer(2), isTrue);
    expect(poker.supportsDrawOffer(6), isFalse);
    expect(gameRegistry['uno']!.supportsDrawOffer(2), isFalse);
    expect(gameRegistry['nardy']!.supportsDrawOffer(2), isFalse);
    expect(gameRegistry['checkers']!.supportsDrawOffer(2), isTrue);
    expect(gameRegistry['connect4']!.supportsDrawOffer(2), isTrue);
  });

  test('offline supported for tictactoe, durak, battleship, poker', () {
    expect(gameRegistry['tictactoe']!.supportsOffline, isTrue);
    expect(gameRegistry['durak']!.supportsOffline, isTrue);
    expect(gameRegistry['battleship']!.supportsOffline, isTrue);
    expect(
        gameRegistry['battleship']!.offlinePath, '/games/battleship/offline');
    expect(gameRegistry['poker']!.supportsOffline, isTrue);
    expect(gameRegistry['poker']!.offlinePath, '/games/poker/offline');
    expect(gameRegistry['uno']!.supportsOffline, isTrue);
    expect(gameRegistry['uno']!.offlinePath, '/games/uno/offline');
    expect(gameRegistry['nardy']!.supportsOffline, isTrue);
    expect(gameRegistry['checkers']!.supportsOffline, isTrue);
    expect(gameRegistry['connect4']!.supportsOffline, isTrue);
    expect(gameRegistry['checkers']!.offlinePath, '/games/checkers/offline');
    expect(gameRegistry['connect4']!.offlinePath, '/games/connect4/offline');
  });
}
