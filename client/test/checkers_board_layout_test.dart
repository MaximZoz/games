import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_board.dart';
import 'package:multigames_client/games/checkers/checkers_board_layout.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_piece_tracker.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';

CheckersGameView _view({
  List<int>? board,
  List<CheckersMove> legalMoves = const [],
  int lastFromR = -1,
  int lastFromC = -1,
  int lastToR = -1,
  int lastToC = -1,
}) {
  return CheckersGameView(
    id: 't',
    lobbyId: 'l',
    gameMode: CheckersEngine.modeRussian,
    board: board ?? List<int>.filled(64, 0),
    turn: 0,
    seq: 0,
    mustContinue: false,
    contR: -1,
    contC: -1,
    lastFromR: lastFromR,
    lastFromC: lastFromC,
    lastToR: lastToR,
    lastToC: lastToC,
    players: const [],
    playerIds: const [],
    legalMoves: legalMoves,
    myIndex: 0,
    isMyTurn: true,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: 0,
    isOver: false,
    winnerIndex: -1,
    winnerUserId: '',
    isDraw: false,
  );
}

void main() {
  test('клетки стыкуются без щелей на дробной ширине', () {
    for (final side in [317.0, 333.3, 390.0, 412.0, 700.0]) {
      expect(checkersCellsTileWithoutGaps(side), isTrue, reason: 'side=$side');
      final cell = checkersCellRect(side, 3, 5);
      expect(
        checkersHighlightFitsCell(
            cell, checkersTargetDotSize(cell.shortestSide)),
        isTrue,
      );
    }
  });

  test('поворот доски зеркалит логические координаты', () {
    expect(
      checkersBoardSquare(visR: 0, visC: 0, flip: false),
      const CheckersSquare(0, 0),
    );
    expect(
      checkersBoardSquare(visR: 0, visC: 0, flip: true),
      const CheckersSquare(7, 7),
    );
    expect(
      checkersSquareAtLocal(side: 320, dx: 10, dy: 10, flip: false),
      const CheckersSquare(0, 0),
    );
    expect(
      checkersSquareAtLocal(side: 320, dx: 310, dy: 10, flip: true),
      const CheckersSquare(7, 0),
    );
  });

  testWidgets('тап по клетке даёт ровные координаты сетки', (tester) async {
    CheckersSquare? tapped;
    final board = List<int>.filled(64, 0);
    board[2 * 8 + 1] = CheckersEngine.whiteMan;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 320,
            child: CheckersBoard(
              game: _view(
                board: board,
                legalMoves: const [
                  CheckersMove(
                    from: CheckersSquare(2, 1),
                    to: CheckersSquare(3, 2),
                  ),
                ],
              ),
              selected: const CheckersSquare(2, 1),
              flip: false,
              onSquareTap: (r, c) => tapped = CheckersSquare(r, c),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
        tester.getTopLeft(find.byType(CheckersBoard)) + const Offset(60, 140));
    expect(tapped, const CheckersSquare(3, 1));
  });

  test('трекер сохраняет номер шашки при ходе', () {
    final tracker = CheckersPieceTracker();
    final board = List<int>.filled(64, 0);
    board[2 * 8 + 1] = CheckersEngine.whiteMan;
    final first = tracker.spotsFor(board);
    expect(first, hasLength(1));
    board[2 * 8 + 1] = 0;
    board[3 * 8 + 2] = CheckersEngine.whiteMan;
    final second = tracker.spotsFor(
      board,
      lastFromR: 2,
      lastFromC: 1,
      lastToR: 3,
      lastToC: 2,
    );
    expect(second, hasLength(1));
    expect(second.single.id, first.single.id);
    expect(second.single.r, 3);
    expect(second.single.c, 2);
  });

  test('длительность хода растёт с дистанцией', () {
    final step = checkersMoveDuration(fromR: 2, fromC: 1, toR: 3, toC: 2);
    final fly = checkersMoveDuration(fromR: 0, fromC: 1, toR: 7, toC: 8);
    expect(fly.inMilliseconds, greaterThan(step.inMilliseconds));
  });

  testWidgets('шашка переезжает анимацией, а не перерисовкой', (tester) async {
    final board = List<int>.filled(64, 0);
    board[2 * 8 + 1] = CheckersEngine.whiteMan;
    Widget boardAt(
        {required int lastFromR,
        required int lastFromC,
        required int lastToR,
        required int lastToC}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 320,
            child: CheckersBoard(
              game: _view(
                board: List<int>.from(board),
                lastFromR: lastFromR,
                lastFromC: lastFromC,
                lastToR: lastToR,
                lastToC: lastToC,
              ),
              selected: null,
              flip: false,
              onSquareTap: (_, __) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
        boardAt(lastFromR: -1, lastFromC: -1, lastToR: -1, lastToC: -1));
    await tester.pump();
    expect(find.byType(AnimatedPositioned), findsOneWidget);
    final before =
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    final beforeLeft = before.left ?? 0;
    final key = before.key;

    board[2 * 8 + 1] = 0;
    board[3 * 8 + 2] = CheckersEngine.whiteMan;
    await tester.pumpWidget(
      boardAt(lastFromR: 2, lastFromC: 1, lastToR: 3, lastToC: 2),
    );
    await tester.pump();
    final after =
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    expect(after.key, key);
    expect(after.left ?? 0, isNot(closeTo(beforeLeft, 1)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
