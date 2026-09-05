import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_board.dart';
import 'package:multigames_client/games/checkers/checkers_board_layout.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
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
        checkersHighlightFitsCell(cell, checkersTargetDotSize(cell.shortestSide)),
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
    await tester.tapAt(tester.getTopLeft(find.byType(CheckersBoard)) + const Offset(60, 140));
    expect(tapped, const CheckersSquare(3, 1));
  });
}
