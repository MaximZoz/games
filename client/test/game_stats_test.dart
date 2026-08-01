import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('GameStats', () {
    test('fromJson parses aggregated stats and opponent lists', () {
      final json = {
        'wins': 5,
        'draws': 2,
        'losses': 3,
        'total_played': 10,
        'win_rate': 0.5,
        'total_duration_sec': 3600,
        'top_won': [
          {'opponent_id': 'u1', 'display_name': 'Alice', 'won': 4, 'drawn': 0, 'lost': 1},
        ],
        'top_lost': [
          {'opponent_id': 'u2', 'display_name': 'Bob', 'won': 0, 'drawn': 1, 'lost': 3},
        ],
      };
      final s = GameStats.fromJson(json);
      expect(s.wins, 5);
      expect(s.draws, 2);
      expect(s.losses, 3);
      expect(s.totalPlayed, 10);
      expect(s.winRate, 0.5);
      expect(s.totalDurationSec, 3600);
      expect(s.topWon, hasLength(1));
      expect(s.topWon.first.opponentId, 'u1');
      expect(s.topWon.first.won, 4);
      expect(s.topLost, hasLength(1));
      expect(s.topLost.first.lost, 3);
      expect(s.isEmpty, isFalse);
    });

    test('isEmpty is true when nothing played', () {
      const s = GameStats(
        wins: 0,
        draws: 0,
        losses: 0,
        totalPlayed: 0,
        winRate: 0,
        totalDurationSec: 0,
        topWon: [],
        topLost: [],
      );
      expect(s.isEmpty, isTrue);
    });

    test('win_rate 0.6 parses correctly', () {
      final s = GameStats.fromJson({'wins': 6, 'total_played': 10, 'win_rate': 0.6});
      expect(s.winRate, 0.6);
      expect(s.losses, 0);
      expect(s.topWon, isEmpty);
    });

    test('fromJson tolerates missing fields', () {
      final s = GameStats.fromJson({});
      expect(s.wins, 0);
      expect(s.totalPlayed, 0);
      expect(s.topWon, isEmpty);
    });
  });

  group('HeadToHead', () {
    test('fromJson parses score and show_stats_to_others', () {
      final h = HeadToHead.fromJson({
        'opponent_id': 'u1',
        'display_name': 'Alice',
        'won': 3,
        'drawn': 1,
        'lost': 2,
        'show_stats_to_others': true,
      });
      expect(h.opponentId, 'u1');
      expect(h.won, 3);
      expect(h.drawn, 1);
      expect(h.lost, 2);
      expect(h.showStatsToOthers, isTrue);
      expect(h.isEmpty, isFalse);
    });

    test('isEmpty when all zeros', () {
      final h = HeadToHead.fromJson({});
      expect(h.isEmpty, isTrue);
      expect(h.won, 0);
      expect(h.showStatsToOthers, isFalse);
    });
  });

  group('OpponentStat', () {
    test('total sums won+drawn+lost', () {
      const o = OpponentStat(
        opponentId: 'u1',
        displayName: 'Alice',
        won: 3,
        drawn: 1,
        lost: 2,
      );
      expect(o.total, 6);
    });

    test('fromJson falls back to empty name', () {
      final o = OpponentStat.fromJson({'opponent_id': 'u1', 'won': 1});
      expect(o.displayName, '');
      expect(o.won, 1);
      expect(o.drawn, 0);
    });
  });
}
