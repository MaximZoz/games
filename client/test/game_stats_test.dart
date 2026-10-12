import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/stats_modes.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';

import 'test_locale.dart';

void _unit() {
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
        'top_drawn': [
          {'opponent_id': 'u3', 'display_name': 'Cara', 'won': 0, 'drawn': 5, 'lost': 0},
        ],
        'top_lost': [
          {'opponent_id': 'u2', 'display_name': 'Bob', 'won': 0, 'drawn': 1, 'lost': 3},
        ],
        'games': [
          {
            'game_type': 'tictactoe',
            'won': 5,
            'drawn': 2,
            'lost': 3,
            'total_duration_sec': 900,
            'top_won': [
              {'opponent_id': 'u1', 'display_name': 'Alice', 'won': 4, 'drawn': 0, 'lost': 1},
            ],
            'top_drawn': [
              {'opponent_id': 'u3', 'display_name': 'Cara', 'won': 0, 'drawn': 2, 'lost': 0},
            ],
            'top_lost': [
              {'opponent_id': 'u2', 'display_name': 'Bob', 'won': 0, 'drawn': 1, 'lost': 3},
            ],
          },
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
      expect(s.topDrawn, hasLength(1));
      expect(s.topDrawn.first.drawn, 5);
      expect(s.topLost, hasLength(1));
      expect(s.topLost.first.lost, 3);
      expect(s.games, hasLength(1));
      expect(s.games.first.gameType, 'tictactoe');
      expect(s.games.first.totalDurationSec, 900);
      expect(s.games.first.topWon, hasLength(1));
      expect(s.games.first.topDrawn.first.displayName, 'Cara');
      expect(s.games.first.topLost.first.displayName, 'Bob');
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
        topDrawn: [],
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
      expect(s.recent, isEmpty);
      expect(s.modes, isEmpty);
    });

    test('fromJson parses recent games and modes', () {
      final s = GameStats.fromJson({
        'wins': 1,
        'total_played': 1,
        'modes': [
          {
            'game_type': 'durak',
            'mode': '2:36',
            'won': 1,
            'drawn': 0,
            'lost': 0,
          },
        ],
        'recent': [
          {
            'game_type': 'durak',
            'mode': '2:36',
            'outcome': 'win',
            'opponents': [
              {'opponent_id': 'u1', 'display_name': 'Анна'},
              {'display_name': 'Бот', 'bot': true},
            ],
          },
        ],
      });
      expect(s.modes, hasLength(1));
      expect(s.modes.first.mode, '2:36');
      expect(s.recent, hasLength(1));
      expect(s.recent.first.outcome, 'win');
      expect(s.recent.first.opponents.last.bot, isTrue);
    });
  });

  test('statsModeOptions keeps canonical durak chips and extra played mode', () {
    final modes = statsModeOptions('durak', ['9:52']);
    expect(modes, contains('2:36'));
    expect(modes, contains('9:52'));
    expect(statsModeOptions('uno', const []), isEmpty);
  });

  test('statsModeLabel uses players and deck', () {
    final l10n = lookupAppLocalizations(const Locale('ru'));
    expect(statsModeLabel('durak', '3:52', l10n), '3 · 52');
    expect(statsModeLabel('chess', 'blitz', l10n), 'Блиц');
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
        'games': [
          {
            'game_type': 'tictactoe',
            'won': 3,
            'drawn': 1,
            'lost': 2,
          },
        ],
      });
      expect(h.opponentId, 'u1');
      expect(h.won, 3);
      expect(h.drawn, 1);
      expect(h.lost, 2);
      expect(h.showStatsToOthers, isTrue);
      expect(h.isEmpty, isFalse);
      expect(h.games, hasLength(1));
      expect(h.games.first.gameType, 'tictactoe');
      expect(h.games.first.won, 3);
    });

    test('fromJson falls back to tictactoe when games missing', () {
      final h = HeadToHead.fromJson({
        'won': 1,
        'drawn': 0,
        'lost': 2,
      });
      expect(h.games, hasLength(1));
      expect(h.games.first.gameType, 'tictactoe');
      expect(h.games.first.lost, 2);
    });

    test('isEmpty when all zeros', () {
      final h = HeadToHead.fromJson({});
      expect(h.isEmpty, isTrue);
      expect(h.won, 0);
      expect(h.games, isEmpty);
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

void main() {
  setUp(setUpTestLocaleRu);

  _unit();

  testWidgets('лента исходов и чип режима на одной карточке', (tester) async {
    const stats = GameStats(
      wins: 2,
      draws: 1,
      losses: 1,
      totalPlayed: 4,
      winRate: 0.5,
      totalDurationSec: 120,
      topWon: [],
      topDrawn: [],
      topLost: [],
      games: [
        GameTypeScore(gameType: 'chess', won: 2, drawn: 1, lost: 1),
      ],
      modes: [
        GameModeScore(
          gameType: 'chess',
          mode: 'blitz',
          won: 1,
          drawn: 0,
          lost: 0,
        ),
      ],
      recent: [
        RecentGame(
          gameType: 'chess',
          outcome: 'win',
          opponents: [RecentOpponent(displayName: 'Анна')],
        ),
        RecentGame(
          gameType: 'chess',
          outcome: 'loss',
          opponents: [RecentOpponent(displayName: 'Бот', bot: true)],
        ),
        RecentGame(
          gameType: 'chess',
          outcome: 'draw',
          opponents: [RecentOpponent(displayName: 'Илья')],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameStatsProvider(null).overrideWith((ref) async => stats),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: GameStatsBody()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Последние партии'), findsOneWidget);
    expect(find.text('Победа'), findsOneWidget);
    expect(find.text('Поражение'), findsOneWidget);
    expect(find.text('Ничья'), findsOneWidget);
    expect(find.text('Все режимы'), findsNothing);

    await tester.tap(find.text('Шахматы'));
    await tester.pumpAndSettle();

    expect(find.text('Все режимы'), findsOneWidget);
    expect(find.text('Блиц'), findsOneWidget);
    await tester.tap(find.text('Блиц'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
  });
}
