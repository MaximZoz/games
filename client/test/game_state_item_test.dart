import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

GameStateItem _game({
  String turn = 'x',
  String status = 'active',
  String xUserId = 'user-x',
  String oUserId = 'user-o',
}) {
  return GameStateItem(
    id: 'game-1',
    board: List.filled(9, ''),
    turn: turn,
    status: status,
    xUserId: xUserId,
    oUserId: oUserId,
  );
}

void main() {
  group('GameStateItem turn authority', () {
    test('derives each player turn from full game state', () {
      expect(_game().isTurnOf('user-x'), isTrue);
      expect(_game().isTurnOf('user-o'), isFalse);
      expect(_game(turn: 'o').isTurnOf('user-o'), isTrue);
      expect(_game(turn: 'o').isTurnOf('user-x'), isFalse);
    });

    test('does not allow turns after the game ends or without a user', () {
      expect(_game(status: 'x_won').isTurnOf('user-x'), isFalse);
      expect(_game().isTurnOf(null), isFalse);
    });
  });

  group('GameStateItem PvP fallback eligibility', () {
    test('keeps fallback sync only for active human games', () {
      expect(_game().isActivePvp, isTrue);
      expect(_game(status: 'draw').isActivePvp, isFalse);
      expect(_game(oUserId: 'bot:medium').isActivePvp, isFalse);
      expect(_game(xUserId: 'bot:hard').isActivePvp, isFalse);
    });
  });
}
