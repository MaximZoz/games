import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('ActiveSessionResult', () {
    test('parses active game without observation', () {
      final session = ActiveSessionResult.fromJson({
        'type': 'game',
        'game_id': 'g1',
        'is_my_turn': true,
      });
      expect(session.active?.type, 'game');
      expect(session.active?.gameId, 'g1');
      expect(session.active?.isMyTurn, isTrue);
      expect(session.observation, isNull);
    });

    test('parses observation only', () {
      final session = ActiveSessionResult.fromJson({
        'observation': {
          'game_id': 'obs-1',
          'lobby_id': 'L1',
        },
      });
      expect(session.active, isNull);
      expect(session.observation?.gameId, 'obs-1');
      expect(session.observation?.lobbyId, 'L1');
    });

    test('parses active lobby + observation', () {
      final session = ActiveSessionResult.fromJson({
        'type': 'lobby',
        'lobby_id': 'new-lobby',
        'observation': {'game_id': 'old-game'},
      });
      expect(session.active?.type, 'lobby');
      expect(session.active?.lobbyId, 'new-lobby');
      expect(session.observation?.gameId, 'old-game');
    });

    test('applyActiveGameTurnFromEvent updates only this game', () {
      final current = ActiveGameItem(
        type: 'game',
        gameId: 'nardy-1',
        isMyTurn: false,
        gameType: 'nardy',
      );
      expect(
        applyActiveGameTurnFromEvent(current, {
          'type': 'game_state',
          'game_id': 'nardy-1',
          'is_my_turn': true,
        })?.isMyTurn,
        isTrue,
      );
      expect(
        applyActiveGameTurnFromEvent(current, {
          'type': 'game_state',
          'game_id': 'other',
          'is_my_turn': true,
        }),
        isNull,
      );
      expect(
        applyActiveGameTurnFromEvent(current, {
          'type': 'game_state',
          'game_id': 'nardy-1',
          'is_my_turn': false,
        }),
        isNull,
      );
    });

    test('ignores empty observation game_id', () {
      final session = ActiveSessionResult.fromJson({
        'type': 'lobby',
        'lobby_id': 'L',
        'observation': {'game_id': ''},
      });
      expect(session.observation, isNull);
    });
  });
}
