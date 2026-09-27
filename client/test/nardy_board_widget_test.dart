import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_dice_widget.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

NardyGameView _view(NardyEngine engine) {
  final myTurn = !engine.isOver && engine.turn == 0;
  return NardyGameView(
    id: 'g',
    lobbyId: '',
    gameMode: engine.mode,
    board: engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: engine.dice,
    rolled: engine.rolled,
    turn: engine.turn,
    turnNo: engine.turnNo,
    seq: engine.seq,
    headMoved: engine.headMoved,
    players: const [],
    playerIds: const ['me', 'bot:nardy'],
    legalMoves: myTurn ? engine.legalMoves() : const [],
    myIndex: 0,
    isMyTurn: myTurn,
    needsRoll: myTurn && engine.dice.isEmpty && !engine.canUndo,
    canUndo: myTurn && engine.canUndo,
    turnComplete: myTurn && engine.turnComplete,
    currentTurn: myTurn ? engine.currentTurn : const [],
    lastTurn: engine.lastTurn,
    lastTurnSeat: engine.lastTurnSeat,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: 0,
    isOver: engine.isOver,
    winnerIndex: engine.winner,
    winnerUserId: '',
    winKind: engine.winKind,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 640, height: 450, child: child),
        ),
      ),
    );

void main() {
  testWidgets('шашки переезжают анимацией, а не перерисовкой', (tester) async {
    final engine = NardyEngine.newGame(nardyModeLong);
    engine.rollWith(5, 3);
    final tracker = NardyCheckerTracker();

    Widget board(NardyGameView view) => NardyBoard(
          game: view,
          tracker: tracker,
          selectedTrack: null,
          targetTracks: const {},
          canBearOff: false,
          undoTracks: const {},
          onTrackTap: (_) {},
          onBarTap: () {},
          onBearOffTap: () {},
          canDragFrom: (_) => false,
          onDragStart: (_) {},
          onDragEnd: (_) {},
        );

    await tester.pumpWidget(_wrap(board(_view(engine))));
    await tester.pumpAndSettle();

    // Запоминаем позицию каждой шашки по её ключу.
    Map<Key, Offset> positions() {
      final out = <Key, Offset>{};
      for (final element in find.byType(AnimatedPositioned).evaluate()) {
        final widget = element.widget as AnimatedPositioned;
        final key = widget.key;
        if (key == null) continue;
        out[key] = Offset(widget.left ?? 0, widget.top ?? 0);
      }
      return out;
    }

    final before = positions();
    expect(before, isNotEmpty);

    engine.applyMove(0, const NardyMove(0, 5));
    await tester.pumpWidget(_wrap(board(_view(engine))));
    await tester.pump();

    final after = positions();
    // Ключи те же — значит Flutter не пересоздал шашки, а поедет анимацией.
    expect(after.keys.toSet(), before.keys.toSet());
    // На другой пункт уезжает ровно одна шашка. Остальные остаются в своей
    // колонке: стопка лишь переукладывается по высоте, когда шашек стало
    // меньше, — по вертикали они смещаются, но столбец не меняют.
    final changedColumn = [
      for (final entry in after.entries)
        if ((entry.value.dx - before[entry.key]!.dx).abs() > 1) entry.key,
    ];
    expect(changedColumn, hasLength(1),
        reason: 'на другой пункт должна уехать ровно одна шашка');

    // Анимация действительно идёт: к середине шашка ещё в пути.
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('доска рисуется в обеих ориентациях без переполнения',
      (tester) async {
    final engine = NardyEngine.newGame(nardyModeShort);
    final tracker = NardyCheckerTracker();
    Widget board() => NardyBoard(
          game: _view(engine),
          tracker: tracker,
          selectedTrack: null,
          targetTracks: const {},
          canBearOff: false,
          undoTracks: const {},
          onTrackTap: (_) {},
          onBarTap: () {},
          onBearOffTap: () {},
          canDragFrom: (_) => false,
          onDragStart: (_) {},
          onDragEnd: (_) {},
        );

    for (final size in const [Size(360, 620), Size(820, 380)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: board(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NardyBoard), findsOneWidget);
    }
  });

  testWidgets('раскладка дом справа зеркалит шашки в коротких и длинных',
      (tester) async {
    for (final mode in [nardyModeLong, nardyModeShort]) {
      final engine = NardyEngine.newGame(mode);
      final tracker = NardyCheckerTracker();
      Widget board({required bool homeOnRight}) => NardyBoard(
            game: _view(engine),
            tracker: tracker,
            selectedTrack: null,
            targetTracks: const {},
            canBearOff: false,
            undoTracks: const {},
            homeOnRight: homeOnRight,
            onTrackTap: (_) {},
            onBarTap: () {},
            onBearOffTap: () {},
            canDragFrom: (_) => false,
            onDragStart: (_) {},
            onDragEnd: (_) {},
          );

      await tester.pumpWidget(_wrap(board(homeOnRight: false)));
      await tester.pumpAndSettle();
      Offset firstLeft() {
        final widget = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned).first,
        );
        return Offset(widget.left ?? 0, widget.top ?? 0);
      }

      final left = firstLeft();
      await tester.pumpWidget(_wrap(board(homeOnRight: true)));
      await tester.pumpAndSettle();
      final right = firstLeft();
      expect(right.dx, isNot(closeTo(left.dx, 1)),
          reason: 'mode $mode: шашки должны зеркально переехать');
    }
  });

  testWidgets('бросок кубиков проигрывает анимацию', (tester) async {
    await tester.pumpWidget(_wrap(
      const NardyDiceRow(rolled: [3, 5], remaining: [3, 5], rollKey: 'r1'),
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    // Новый бросок — новая прокрутка.
    await tester.pumpWidget(_wrap(
      const NardyDiceRow(
          rolled: [6, 6, 6, 6], remaining: [6, 6, 6, 6], rollKey: 'r2'),
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    // Тот же бросок — заново не крутим.
    await tester.pumpWidget(_wrap(
      const NardyDiceRow(
          rolled: [6, 6, 6, 6], remaining: [6, 6], rollKey: 'r2'),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
