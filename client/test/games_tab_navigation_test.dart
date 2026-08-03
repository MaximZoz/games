import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/widgets/app_shell.dart';

void main() {
  group('gameIdFromPath / activeGameUsable', () {
    test('parses game id from path', () {
      expect(
        gameIdFromPathForTest(
          '/games/tictactoe/game/abc-123',
        ),
        'abc-123',
      );
      expect(gameIdFromPathForTest('/games'), isNull);
      expect(gameIdFromPathForTest('/games/tictactoe/lobby/x'), isNull);
    });

    test('active game with id is usable', () {
      expect(
        activeGameUsableForTest(
          ActiveGameItem(type: 'game', gameId: 'g1'),
        ),
        isTrue,
      );
      expect(activeGameUsableForTest(null), isFalse);
      expect(
        activeGameUsableForTest(ActiveGameItem(type: 'game')),
        isFalse,
      );
    });
  });
}
