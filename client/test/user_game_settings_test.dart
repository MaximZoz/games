import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('UserGameSettings', () {
    test('defaults', () {
      const s = UserGameSettings.defaults;
      expect(s.gameType, 'tictactoe');
      expect(s.turnTimeSec, 0);
      expect(s.variant, 'classic');
      expect(s.gridSize, 3);
      expect(s.swapRule, isFalse);
      expect(s.firstMoveRestriction, isFalse);
      expect(s.stakeBronze, 2);
    });

    test('durak defaults', () {
      const s = UserGameSettings.durakDefaults;
      expect(s.gameType, 'durak');
      expect(s.turnTimeSec, 60);
      expect(s.deckSize, 36);
      expect(s.maxPlayers, 2);
      expect(s.gameMode, 'podkidnoi');
      expect(s.stakeBronze, 2);
    });

    test('fromJson clamps invalid turn/variant/stake', () {
      final s = UserGameSettings.fromJson({
        'game_type': 'tictactoe',
        'turn_time_sec': 15,
        'grid_size': 2,
        'variant': 'unknown',
        'swap_rule': true,
        'first_move_restriction': true,
        'stake_bronze': 0,
      });
      expect(s.turnTimeSec, 0);
      expect(s.variant, 'classic');
      expect(s.gridSize, 3);
      expect(s.stakeBronze, 2);
      expect(s.swapRule, isTrue);
      expect(s.firstMoveRestriction, isTrue);
    });

    test('fromJson accepts valid options', () {
      final s = UserGameSettings.fromJson({
        'turn_time_sec': 600,
        'variant': 'gomoku',
        'grid_size': 15,
        'stake_bronze': 10000,
        'swap_rule': false,
      });
      expect(s.turnTimeSec, 600);
      expect(s.variant, 'gomoku');
      expect(s.gridSize, 15);
      expect(s.stakeBronze, 10000);
    });

    test('fromJson durak fields', () {
      final s = UserGameSettings.fromJson({
        'game_type': 'durak',
        'turn_time_sec': 20,
        'stake_bronze': 50,
        'deck_size': 52,
        'max_players': 4,
        'game_mode': 'perevodnoi',
      });
      expect(s.gameType, 'durak');
      expect(s.turnTimeSec, 20);
      expect(s.deckSize, 52);
      expect(s.maxPlayers, 4);
      expect(s.gameMode, 'perevodnoi');
      expect(s.stakeBronze, 50);
    });

    test('toJson roundtrip', () {
      const original = UserGameSettings(
        turnTimeSec: 20,
        variant: 'multi3',
        swapRule: true,
        firstMoveRestriction: true,
        stakeBronze: 50,
      );
      final again = UserGameSettings.fromJson(original.toJson());
      expect(again.gameType, original.gameType);
      expect(again.turnTimeSec, original.turnTimeSec);
      expect(again.variant, original.variant);
      expect(again.stakeBronze, original.stakeBronze);
    });

    test('toJson durak roundtrip', () {
      const original = UserGameSettings(
        gameType: 'durak',
        turnTimeSec: 60,
        variant: 'podkidnoi',
        stakeBronze: 10,
        deckSize: 24,
        maxPlayers: 2,
        gameMode: 'podkidnoi',
      );
      final again = UserGameSettings.fromJson(original.toJson());
      expect(again, original);
    });

    test('toJson checkers roundtrip сохраняет все режимы', () {
      for (final mode in ['russian', 'english', 'giveaway', 'corners']) {
        final original = UserGameSettings(
          gameType: 'checkers',
          turnTimeSec: 60,
          variant: mode,
          gridSize: 8,
          stakeBronze: 10,
          maxPlayers: 2,
          gameMode: mode,
        );
        final again = UserGameSettings.fromJson(original.toJson());
        expect(again.gameMode, mode, reason: mode);
        expect(again.variant, mode, reason: mode);
      }
    });

    test('fromJson checkers читает english и corners из variant', () {
      final english = UserGameSettings.fromJson({
        'game_type': 'checkers',
        'variant': 'english',
        'stake_bronze': 10,
      });
      expect(english.gameMode, 'english');
      final corners = UserGameSettings.fromJson({
        'game_type': 'checkers',
        'game_mode': 'corners',
        'stake_bronze': 10,
      });
      expect(corners.gameMode, 'corners');
    });

    test('copyWith and equality', () {
      const a = UserGameSettings.defaults;
      final b = a.copyWith(variant: 'multi4', swapRule: true);
      expect(b.variant, 'multi4');
      expect(b.gridSize, 10);
      expect(b.swapRule, isTrue);
      expect(b.turnTimeSec, 0);
      expect(a == b, isFalse);
      expect(a.copyWith(), a);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
