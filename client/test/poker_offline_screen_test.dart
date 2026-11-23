import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/framework/game_screen_scaffold.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/poker_game_screen.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

import 'test_locale.dart';

Future<void> _pumpTable(
  WidgetTester tester, {
  int playerCount = 2,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final session = OfflinePokerSession.create(
    humanUserId: 'user-1',
    humanDisplayName: 'player1',
    playerCount: playerCount,
  );
  addTearDown(() {
    OfflinePokerRegistry.instance.get(session.gameId)?.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      // Каждый стол — свой экран: состояние прошлого размера не переносим.
      key: ValueKey(session.gameId),
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PokerGameScreen(gameId: session.gameId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Снять экран и офлайн-стол, чтобы их таймеры не пережили тест.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  OfflinePokerRegistry.instance.disposeAll();
}

class _FixedPokerGame extends PokerGameNotifier {
  _FixedPokerGame(this.view);

  final PokerGameView view;

  @override
  Future<PokerGameView> build(String arg) async => view;
}

// Префикс offline — экран не ходит в сеть; сам стол отдаёт провайдер ниже.
const _timedGameId = 'offline:poker:chrome-test';

/// Раздача на троих с лимитом времени; ходит место [acting].
PokerGameView _timedView({required int acting, required int deadline}) {
  const ids = ['user-1', 'user-2', 'user-3'];
  return PokerGameView.fromJson({
    'id': _timedGameId,
    'status': 'active',
    'street': 'preflop',
    'player_ids': ids,
    'players': [
      for (var i = 0; i < ids.length; i++)
        {
          'id': ids[i],
          'display_name': 'player${i + 1}',
          'seat': i,
          'chips': 1000,
          'is_acting': i == acting,
          if (i == 0)
            'hole_cards': [
              {'rank': 14, 'suit': 'S'},
              {'rank': 13, 'suit': 'S'},
            ],
        },
    ],
    'small_blind': 10,
    'big_blind': 20,
    'dealer_index': 0,
    'acting_index': acting,
    'my_index': 0,
    'legal_actions': acting == 0 ? ['fold', 'call'] : <String>[],
    'call_amount': 20,
    'turn_time_sec': 60,
    'turn_deadline': deadline,
    'stake_bronze': 0,
    'hand_number': 1,
  });
}

Future<void> _pumpTimed(WidgetTester tester, PokerGameView view) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey('timed-${view.actingIndex}'),
      overrides: [
        pokerGameProvider.overrideWith(() => _FixedPokerGame(view)),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PokerGameScreen(gameId: _timedGameId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    TurnClockSfx.reset();
  });

  testWidgets('офлайн-покер рисует стол, не пустой фон', (tester) async {
    await _pumpTable(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Покер'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      findsWidgets,
    );
  });

  testWidgets('общий хром: в шапке только правила, флаг «сдаться» под ними',
      (tester) async {
    await _pumpTable(tester, size: const Size(390, 800));

    final rules =
        tester.getRect(find.byKey(const ValueKey('game-chrome-rules')));
    final flag = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.flag_outlined),
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.flag_outlined),
      ),
      findsNothing,
    );
    expect(flag.top, greaterThanOrEqualTo(rules.bottom - 8));
    expect((flag.center.dx - rules.center.dx).abs(), lessThan(8));
    await _unmount(tester);
  });

  testWidgets('о своём ходе сообщает только общий хром', (tester) async {
    await _pumpTable(tester);

    // Офлайн без лимита времени: один MyTurnAlert каркаса, рамки мест
    // звуком хода не управляют.
    expect(find.byType(MyTurnAlert), findsOneWidget);
    final frames = tester.widgetList<TurnTimerBorder>(
      find.byType(TurnTimerBorder),
    );
    expect(frames, isNotEmpty);
    expect(frames.where((f) => f.myTurnClock), isEmpty);
    await _unmount(tester);
  });

  testWidgets('свой ход с лимитом: отсчёт в шапке перед правилами',
      (tester) async {
    final deadline = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 30;
    await _pumpTimed(tester, _timedView(acting: 0, deadline: deadline));
    expect(tester.takeException(), isNull);

    final timer = tester.getRect(find.byType(GameTurnCountdown));
    final rules =
        tester.getRect(find.byKey(const ValueKey('game-chrome-rules')));
    expect(timer.right, lessThanOrEqualTo(rules.left));
    expect(rules.left - timer.right, lessThan(24));
    expect((timer.center.dy - rules.center.dy).abs(), lessThan(8));

    // Рамка своего места остаётся таймером, но звук хода ведёт только шапка.
    final hero = tester.widget<TurnTimerBorder>(
      find.byKey(ValueKey('poker-hero-$deadline')),
    );
    expect(hero.active, isTrue);
    expect(hero.myTurnClock, isFalse);
    expect(hero.onExpired, isNull);
    expect(find.byType(MyTurnAlert), findsNothing);
    await _unmount(tester);
  });

  testWidgets('ход соперника: отсчёт в шапке скрыт, таймер — рамка его места',
      (tester) async {
    final deadline = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 30;
    await _pumpTimed(tester, _timedView(acting: 1, deadline: deadline));
    expect(tester.takeException(), isNull);

    expect(find.byType(GameTurnCountdown), findsNothing);
    expect(
      find.byType(GameTurnCountdown, skipOffstage: false),
      findsOneWidget,
    );
    final acting = tester.widget<TurnTimerBorder>(
      find.byKey(ValueKey('poker-seat-1-$deadline')),
    );
    expect(acting.active, isTrue);
    expect(acting.turnDeadline, deadline);
    expect(acting.turnTimeSec, 60);
    final waiting = tester.widget<TurnTimerBorder>(
      find.byKey(ValueKey('poker-seat-2-$deadline')),
    );
    expect(waiting.active, isFalse);
    final hero = tester.widget<TurnTimerBorder>(
      find.byKey(ValueKey('poker-hero-$deadline')),
    );
    expect(hero.active, isFalse);
    await _unmount(tester);
  });

  testWidgets('места соперников не заходят под флаг «сдаться»', (tester) async {
    const sizes = [
      Size(360, 740),
      Size(360, 560),
      Size(740, 360),
      Size(1200, 800),
    ];
    for (final size in sizes) {
      for (var players = 2; players <= 6; players++) {
        await _pumpTable(tester, playerCount: players, size: size);
        expect(tester.takeException(), isNull);

        final button = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.flag_outlined),
        );
        // Полоса столбика действий — та ширина, что общий хром отдаёт телу.
        final flag = Rect.fromLTRB(
          size.width - GameScreenScaffold.railWidth,
          button.top,
          size.width,
          button.bottom,
        );
        final seats = [
          ...tester.widgetList(find.byType(GamePlayerAvatar)).map(
                (w) => tester.getRect(find.byWidget(w)),
              ),
          ...tester.widgetList(find.byType(TurnTimerBorder)).map(
                (w) => tester.getRect(find.byWidget(w)),
              ),
        ];
        expect(seats.length, players * 2, reason: '$size, игроков $players');
        for (final seat in seats) {
          expect(
            seat.overlaps(flag),
            isFalse,
            reason: '$size, игроков $players: место $seat под флагом $flag',
          );
        }
        await _unmount(tester);
      }
    }
  });
}
