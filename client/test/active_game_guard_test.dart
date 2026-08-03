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
  });
}
