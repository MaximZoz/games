import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('isBusyWithOtherSession', () {
    test('blocks other lobby while in active game', () {
      final active = ActiveGameItem(type: 'game', gameId: 'g1');
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'L2'),
        isTrue,
      );
    });

    test('allows same game id', () {
      final active = ActiveGameItem(type: 'game', gameId: 'g1');
      expect(
        isBusyWithOtherSession(active, targetGameId: 'g1'),
        isFalse,
      );
    });

    test('allows same lobby id', () {
      final active = ActiveGameItem(type: 'lobby', lobbyId: 'L1');
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'L1'),
        isFalse,
      );
    });

    test('free when no active', () {
      expect(isBusyWithOtherSession(null, targetLobbyId: 'L1'), isFalse);
    });

    test('active game always blocks (observation is separate)', () {
      final active = ActiveGameItem(type: 'game', gameId: 'g1');
      expect(hasBlockingActiveMatch(active), isTrue);
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'L2'),
        isTrue,
      );
    });

    test('pinned live game blocks other lobby', () {
      final pinned = ActiveGameItem(type: 'game', gameId: 'live-1');
      expect(
        isBusyWithOtherSession(pinned, targetLobbyId: 'invite-lobby'),
        isTrue,
      );
    });
  });

  group('gameIdFromLocation', () {
    test('parses game path', () {
      expect(
        gameIdFromLocation('/games/tictactoe/game/abc-123'),
        'abc-123',
      );
      expect(
        gameIdFromLocation('/games/durak/game/d-1'),
        'd-1',
      );
    });

    test('ignores non-game paths', () {
      expect(gameIdFromLocation('/games'), isNull);
      expect(gameIdFromLocation('/games/tictactoe/lobby/x'), isNull);
      expect(gameIdFromLocation('/games/durak/lobby/x'), isNull);
    });

    test('with chat return parses game query value', () {
      expect(
        gameIdFromLocation('/games/tictactoe/game/g9?from=chat'),
        'g9',
      );
      expect(
        gameIdFromLocation('/games/durak/game/g9?from=chat'),
        'g9',
      );
    });
  });

  group('isFinishCurrentGameError', () {
    test('detects 409 finish message', () {
      expect(
        isFinishCurrentGameError(
          GamesException(409, 'finish your current game first'),
        ),
        isTrue,
      );
    });

    test('detects canonical error key from JSON', () {
      expect(
        isFinishCurrentGameError(
          GamesException(
            409,
            'Сначала завершите текущую игру',
            errorKey: finishCurrentGameErrorKey,
          ),
        ),
        isTrue,
      );
    });

    test('ignores other conflicts', () {
      expect(
        isFinishCurrentGameError(
          GamesException(409, 'lobby full'),
        ),
        isFalse,
      );
    });
  });
}
