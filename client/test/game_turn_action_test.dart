import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('GameTurnActionLock', () {
    test('второй acquire в том же ходе не проходит', () {
      final lock = GameTurnActionLock();
      expect(lock.held, isFalse);
      expect(lock.tryAcquire(), isTrue);
      expect(lock.held, isTrue);
      expect(lock.tryAcquire(), isFalse);
      lock.release();
      expect(lock.held, isFalse);
      expect(lock.tryAcquire(), isTrue);
    });
  });

  group('isStaleNotYourTurnError', () {
    test('ловит ключ и русский текст', () {
      expect(
        isStaleNotYourTurnError(
          GamesException(400, 'Сейчас не ваш ход', errorKey: 'not your turn'),
        ),
        isTrue,
      );
      expect(
        isStaleNotYourTurnError(GamesException(400, 'lobby full')),
        isFalse,
      );
    });
  });

  group('isStaleGameOverError', () {
    test('ловит ключ и русский текст', () {
      expect(
        isStaleGameOverError(
          GamesException(400, 'Игра окончена', errorKey: 'game is over'),
        ),
        isTrue,
      );
      expect(
        isStaleGameOverError(
          GamesException(400, 'Эта игра уже закончилась.'),
        ),
        isTrue,
      );
      expect(isStaleGameOverError(GamesException(400, 'not your turn')), isFalse);
    });
  });
}
