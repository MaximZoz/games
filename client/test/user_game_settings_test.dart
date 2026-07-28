import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('UserGameSettings', () {
    test('defaults', () {
      const s = UserGameSettings.defaults;
      expect(s.gameType, 'tictactoe');
      expect(s.turnTimeSec, 0);
      expect(s.gridSize, 3);
      expect(s.swapRule, isFalse);
      expect(s.firstMoveRestriction, isFalse);
      expect(s.stakeBronze, 1);
    });

    test('fromJson clamps invalid turn/grid/stake', () {
      final s = UserGameSettings.fromJson({
        'game_type': 'tictactoe',
        'turn_time_sec': 15,
        'grid_size': 2,
        'swap_rule': true,
        'first_move_restriction': true,
        'stake_bronze': 0,
      });
      expect(s.turnTimeSec, 0);
      expect(s.gridSize, 3);
      expect(s.stakeBronze, 1);
      expect(s.swapRule, isTrue);
      expect(s.firstMoveRestriction, isTrue);
    });

    test('fromJson accepts valid options', () {
      final s = UserGameSettings.fromJson({
        'turn_time_sec': 600,
        'grid_size': 8,
        'stake_bronze': 10000,
        'swap_rule': false,
      });
      expect(s.turnTimeSec, 600);
      expect(s.gridSize, 8);
      expect(s.stakeBronze, 10000);
    });

    test('toJson roundtrip', () {
      const original = UserGameSettings(
        turnTimeSec: 30,
        gridSize: 4,
        swapRule: true,
        firstMoveRestriction: true,
        stakeBronze: 50,
      );
      final again = UserGameSettings.fromJson(original.toJson());
      expect(again, original);
    });

    test('copyWith and equality', () {
      const a = UserGameSettings.defaults;
      final b = a.copyWith(gridSize: 5, swapRule: true);
      expect(b.gridSize, 5);
      expect(b.swapRule, isTrue);
      expect(b.turnTimeSec, 0);
      expect(a == b, isFalse);
      expect(a.copyWith(), a);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
