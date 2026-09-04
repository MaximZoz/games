import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_board_layout.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_dice_widget.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/nardy/nardy_sfx.dart';

NardyGameView _view(
  NardyEngine engine, {
  List<int>? board,
  int turnNo = 0,
}) {
  final myTurn = !engine.isOver && engine.turn == 0;
  return NardyGameView(
    id: 'g',
    lobbyId: '',
    gameMode: engine.mode,
    board: board ?? engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: engine.dice,
    rolled: engine.rolled,
    turn: engine.turn,
    turnNo: turnNo,
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

void main() {
  group('на столе всегда два кубика', () {
    test('обычный бросок — две грани', () {
      expect(nardyDiceFaces(const [3, 5]), [3, 5]);
      expect(nardyIsDoubleRoll(const [3, 5]), isFalse);
    });

    test('дубль — тоже два кубика, а не четыре', () {
      expect(nardyIsDoubleRoll(const [6, 6, 6, 6]), isTrue);
      expect(nardyDiceFaces(const [6, 6, 6, 6]), [6, 6]);
    });

    test('потраченные кубики гаснут по одному', () {
      expect(nardyDiceUsed(const [3, 5], const [3, 5]), [false, false]);
      expect(nardyDiceUsed(const [3, 5], const [5]), [true, false]);
      expect(nardyDiceUsed(const [3, 5], const []), [true, true]);
    });

    test('смена хода с теми же кубиками — не новый бросок', () {
      expect(nardyIsNewRoll(const [3, 5], const [3, 5]), isFalse);
      expect(nardyIsNewRoll(const [3, 5], const [4, 1]), isTrue);
      expect(nardyIsNewRoll(const [], const [2, 6]), isTrue);
      expect(nardyIsNewRoll(const [2, 6], const []), isFalse);
    });

    test('дубль гасит кубик за каждые два хода', () {
      const roll = [6, 6, 6, 6];
      expect(nardyDiceUsed(roll, const [6, 6, 6, 6]), [false, false]);
      expect(nardyDiceUsed(roll, const [6, 6, 6]), [false, false]);
      expect(nardyDiceUsed(roll, const [6, 6]), [false, true]);
      expect(nardyDiceUsed(roll, const [6]), [false, true]);
      expect(nardyDiceUsed(roll, const []), [true, true]);
    });
  });

  testWidgets('на дубле рисуются два кубика и счётчик ходов', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: NardyDiceRow(
            rolled: [6, 6, 6, 6],
            remaining: [6, 6, 6, 6],
            rollKey: 'r',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint).evaluate().length, greaterThan(0));
    expect(find.text('×4'), findsOneWidget);
  });

  group('звуки нард', () {
    final engine = NardyEngine.newGame(nardyModeLong);

    test('первый снимок не звучит', () {
      expect(nardySfxCues(null, _view(engine)), isEmpty);
    });

    test('новый бросок даёт звук кубиков', () {
      final before = _view(engine, turnNo: 0);
      final rolled = NardyEngine.newGame(nardyModeLong)..rollWith(4, 2);
      final after = _view(rolled, turnNo: 1);
      expect(nardySfxCues(before, after), contains(NardySfxCue.roll));
    });

    test('Готово с теми же кубиками не звучит как второй бросок', () {
      final rolled = NardyEngine.newGame(nardyModeLong)..rollWith(4, 2);
      final before = _view(rolled, turnNo: 1);
      final after = _view(rolled, turnNo: 2);
      expect(nardySfxCues(before, after), isNot(contains(NardySfxCue.roll)));
    });

    test('переезд шашки даёт звук хода', () {
      final before = _view(engine);
      final moved = List<int>.of(engine.board);
      moved[23] -= 1;
      moved[18] += 1;
      final after = _view(engine, board: moved);
      expect(nardySfxCues(before, after), contains(NardySfxCue.move));
    });

    test('без изменений — тишина', () {
      final before = _view(engine);
      final after = _view(engine);
      expect(nardySfxCues(before, after), isEmpty);
    });
  });

  group('перетаскивание шашки', () {
    testWidgets('шашку можно перетащить на подсвеченный пункт',
        (tester) async {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(5, 3);
      final tracker = NardyCheckerTracker();
      int? dragStarted;
      int? dropped;
      var selected = -1;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              height: 450,
              child: StatefulBuilder(
                builder: (context, setState) => NardyBoard(
                  game: _view(engine),
                  tracker: tracker,
                  selectedTrack: selected < 0 ? null : selected,
                  targetTracks: selected < 0 ? const {} : const {5},
                  canBearOff: false,
                  undoTracks: const {},
                  onTrackTap: (_) {},
                  onBarTap: () {},
                  onBearOffTap: () {},
                  canDragFrom: (track) => track == 0,
                  onDragStart: (track) {
                    dragStarted = track;
                    setState(() => selected = track);
                  },
                  onDragEnd: (track) => dropped = track,
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final geometry = NardyBoardGeometry(
        size: const Size(640, 450),
        showBar: false,
      );
      final board = tester.getTopLeft(find.byType(NardyBoard));
      final from = board + geometry.trackRect(0).center;
      final to = board + geometry.trackRect(5).center;

      // Мышью — так же, как на вебе, где раньше жест уходил тапу.
      final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 20));
      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dragStarted, 0);
      expect(dropped, 5);
    });

    testWidgets('короткий тап не превращается в перетаскивание',
        (tester) async {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(5, 3);
      final tracker = NardyCheckerTracker();
      var started = false;
      int? tapped;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              height: 450,
              child: NardyBoard(
                game: _view(engine),
                tracker: tracker,
                selectedTrack: null,
                targetTracks: const {},
                canBearOff: false,
                undoTracks: const {},
                onTrackTap: (track) => tapped = track,
                onBarTap: () {},
                onBearOffTap: () {},
                canDragFrom: (track) => track == 0,
                onDragStart: (_) => started = true,
                onDragEnd: (_) {},
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final geometry = NardyBoardGeometry(
        size: const Size(640, 450),
        showBar: false,
      );
      final board = tester.getTopLeft(find.byType(NardyBoard));
      await tester.tapAt(board + geometry.trackRect(0).center);
      await tester.pumpAndSettle();

      expect(started, isFalse);
      expect(tapped, 0);
    });

    testWidgets('с чужого пункта шашка не тащится', (tester) async {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(5, 3);
      final tracker = NardyCheckerTracker();
      var started = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              height: 450,
              child: NardyBoard(
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
                onDragStart: (_) => started = true,
                onDragEnd: (_) {},
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final geometry = NardyBoardGeometry(
        size: const Size(640, 450),
        showBar: false,
      );
      final board = tester.getTopLeft(find.byType(NardyBoard));
      final from = board + geometry.trackRect(0).center;
      final to = board + geometry.trackRect(5).center;
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 20));
      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(started, isFalse);
    });
  });
}
