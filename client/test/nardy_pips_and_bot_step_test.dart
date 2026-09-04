import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_bot.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

void main() {
  group('полоса «осталось»', () {
    test('поровну — половина на половину', () {
      expect(nardyPipsShare(myPips: 167, oppPips: 167), closeTo(0.5, 0.001));
    });

    test('у кого меньше очков, у того полоса длиннее', () {
      final leading = nardyPipsShare(myPips: 142, oppPips: 158);
      expect(leading, greaterThan(0.5));
      final trailing = nardyPipsShare(myPips: 158, oppPips: 142);
      expect(trailing, lessThan(0.5));
      expect(leading + trailing, closeTo(1.0, 0.001));
    });

    test('доля пропорциональна очкам соперника', () {
      // 100 против 300: у меня втрое меньше пути — три четверти полосы.
      expect(nardyPipsShare(myPips: 100, oppPips: 300), closeTo(0.75, 0.001));
    });

    test('проигравший всё равно виден на полосе', () {
      final share = nardyPipsShare(myPips: 360, oppPips: 1);
      expect(share, greaterThan(0.0));
      expect(share, lessThan(0.2));
    });

    test('нулевые очки не роняют расчёт', () {
      expect(nardyPipsShare(myPips: 0, oppPips: 0), 0.5);
    });

    testWidgets('в полосе видны очки обоих игроков', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: NardyPipsBar(
                myPips: 142,
                oppPips: 158,
                myTurn: true,
                isOver: false,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('142'), findsOneWidget);
      expect(find.text('158'), findsOneWidget);
    });
  });

  group('ход бота по шагам', () {
    test('первый шаг — только бросок, без шашек', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.endTurn();
      expect(engine.turn, 1);
      final rng = math.Random(3);
      nardyPlayBotStep(engine, rng);
      expect(engine.rolled, isNotEmpty);
      expect(engine.currentTurn, isEmpty,
          reason: 'на шаге броска шашки не двигаются');
    });

    test('каждый следующий шаг двигает одну шашку', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.endTurn();
      final rng = math.Random(3);
      nardyPlayBotStep(engine, rng);
      final diceAfterRoll = engine.dice.length;
      nardyPlayBotStep(engine, rng);
      expect(engine.dice.length, diceAfterRoll - 1);
    });

    test('ход закрывается отдельным шагом после последней шашки', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.endTurn();
      final rng = math.Random(3);
      var steps = 0;
      while (steps < 10 && !nardyPlayBotStep(engine, rng)) {
        steps++;
      }
      expect(engine.turn, 0, reason: 'очередь вернулась игроку');
      expect(steps, greaterThanOrEqualTo(2),
          reason: 'бросок и ходы должны быть разными шагами');
    });

    test('офлайн-сессия отдаёт ход бота по шагам', () {
      final session = OfflineNardySession.create(
        humanUserId: 'me',
        gameMode: nardyModeLong,
      );
      addTearDown(OfflineNardyRegistry.instance.disposeAll);
      // Доигрываем свой ход, чтобы очередь ушла боту.
      while (session.view.isMyTurn && !session.view.isOver) {
        final view = session.view;
        if (view.needsRoll) {
          session.applyLocalAction({'action': 'roll'});
          continue;
        }
        if (view.legalMoves.isEmpty) {
          session.applyLocalAction({'action': 'end_turn'});
          break;
        }
        final mv = view.legalMoves.first;
        session.applyLocalAction({
          'action': 'move',
          'from': mv.from,
          'die': mv.die,
        });
      }
      expect(session.view.turn, 1);

      var notifications = 0;
      session.addListener(() => notifications++);
      var steps = 0;
      while (steps < 10 && !session.debugRunBotStep()) {
        steps++;
      }
      expect(steps, greaterThanOrEqualTo(2),
          reason: 'ход бота должен приходить несколькими кадрами');
      expect(notifications, greaterThanOrEqualTo(2),
          reason: 'каждый шаг перерисовывает доску');
    });
  });

  group('свайп назад на игровом экране', () {
    testWidgets('узкая прозрачная полоса не съедает тапы у левого края',
        (tester) async {
      var back = 0;
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeBackScope.gameBoard(
            onBack: () => back++,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapped++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Тап у самого левого края поля — по фишке, а не по «выходу».
      await tester.tapAt(const Offset(6, 400));
      await tester.pumpAndSettle();
      expect(tapped, 1);
      expect(back, 0);
    });

    testWidgets('длинный свайп от края всё ещё закрывает партию',
        (tester) async {
      var back = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeBackScope.gameBoard(
            onBack: () => back++,
            child: const SizedBox.expand(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(6, 400));
      for (var step = 1; step <= 8; step++) {
        await gesture.moveBy(const Offset(12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(back, 1);
    });
  });
}
