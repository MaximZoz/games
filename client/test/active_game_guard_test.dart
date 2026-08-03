import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('isBusyWithOtherSession', () {
    test('blocks other lobby while in active game', () {
      final active = ActiveGameItem(type: 'game', gameId: 'g1');
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'lobby-other'),
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
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'L2'),
        isTrue,
      );
    });

    test('free when no active', () {
      expect(isBusyWithOtherSession(null, targetLobbyId: 'L1'), isFalse);
    });

    test('eliminated player is free to join another lobby', () {
      final active = ActiveGameItem(
        type: 'game',
        gameId: 'g1',
        isEliminated: true,
      );
      expect(
        isBusyWithOtherSession(active, targetLobbyId: 'lobby-other'),
        isFalse,
      );
      expect(hasBlockingActiveMatch(active), isFalse);
    });
  });

  group('gameIdFromLocation', () {
    test('parses game path', () {
      expect(
        gameIdFromLocation('/games/tictactoe/game/abc-123'),
        'abc-123',
      );
      expect(
        gameIdFromLocation('/games/tictactoe/game/abc-123?x=1'),
        'abc-123',
      );
    });

    test('ignores non-game paths', () {
      expect(gameIdFromLocation('/games/tictactoe/lobby/L1'), isNull);
      expect(gameIdFromLocation('/chats'), isNull);
      expect(gameIdFromLocation(null), isNull);
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
      expect(
        isFinishCurrentGameError(
          GamesException(409, 'Сначала завершите текущую игру'),
        ),
        isTrue,
      );
    });

    test('detects canonical error key from JSON', () {
      expect(
        isFinishCurrentGameError(
          GamesException(
            409,
            'Beenden Sie zuerst Ihr aktuelles Spiel',
            errorKey: finishCurrentGameErrorKey,
          ),
        ),
        isTrue,
      );
    });

    test('ignores other conflicts', () {
      expect(
        isFinishCurrentGameError(
          GamesException(409, 'game already started with another opponent'),
        ),
        isFalse,
      );
      expect(
        isFinishCurrentGameError(GamesException(404, 'lobby not found')),
        isFalse,
      );
    });
  });

  group('gameIdFromLocation with chat return', () {
    test('parses game query value', () {
      expect(
        gameIdFromLocation('/games/tictactoe/game/xyz'),
        'xyz',
      );
    });
  });
}
