import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_board.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';

void main() {
  ChessGameView viewOf(ChessEngine g) {
    return ChessGameView(
      id: 'g',
      lobbyId: '',
      gameMode: g.mode,
      board: List<int>.from(g.board),
      turn: g.turn,
      seq: g.seq,
      inCheck: g.inCheck,
      lastFromR: g.lastFromR,
      lastFromC: g.lastFromC,
      lastToR: g.lastToR,
      lastToC: g.lastToC,
      players: const [],
      playerIds: const [],
      legalMoves: const [],
      myIndex: 0,
      isMyTurn: g.turn == 0,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isOver: g.isOver,
      winnerIndex: g.winner,
      winnerUserId: '',
      isDraw: g.winner == ChessEngine.winnerDraw,
    );
  }

  void play(ChessEngine g, int fr, int fc, int tr, int tc) {
    g.apply(g.turn, ChessMove(from: ChessSquare(fr, fc), to: ChessSquare(tr, tc)));
  }

  test('клетки последнего хода отличаются от обычных', () {
    expect(chessLastMoveSquare(dark: false), const Color(0xFFCDD26A));
    expect(chessLastMoveSquare(dark: true), const Color(0xFFAAA23A));
    expect(chessLastMoveSquare(dark: false), isNot(const Color(0xFFEBECD0)));
    expect(chessLastMoveSquare(dark: true), isNot(const Color(0xFF739552)));
  });

  test('обычный ход — один слайд, рокировка — король и ладья', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    final start = viewOf(g);
    play(g, 1, 4, 3, 4);
    final e4 = viewOf(g);
    final pawn = chessMoveSlides(start, e4);
    expect(pawn, isNotNull);
    expect(pawn!, hasLength(1));
    expect(pawn.single.from, const ChessSquare(1, 4));
    expect(pawn.single.to, const ChessSquare(3, 4));
    expect(pawn.single.piece, ChessEngine.whitePawn);
    expect(chessMoveSlides(e4, e4), isNull);

    play(g, 6, 4, 4, 4);
    play(g, 0, 6, 2, 5);
    play(g, 7, 1, 5, 2);
    play(g, 0, 5, 3, 2);
    play(g, 7, 6, 5, 5);
    final beforeCastle = viewOf(g);
    play(g, 0, 4, 0, 6);
    final castle = chessMoveSlides(beforeCastle, viewOf(g));
    expect(castle, isNotNull);
    expect(castle!, hasLength(2));
    expect(castle.first.piece, ChessEngine.whiteKing);
    expect(castle.last.from, const ChessSquare(0, 7));
    expect(castle.last.to, const ChessSquare(0, 5));
  });

  testWidgets('фигура едет с клетки на клетку, а не прыгает', (tester) async {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    final start = viewOf(g);
    g.apply(
      0,
      const ChessMove(from: ChessSquare(1, 4), to: ChessSquare(3, 4)),
    );
    final after = viewOf(g);

    Widget board(ChessGameView game) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: ChessBoard(
                game: game,
                selected: null,
                flip: false,
                onSquareTap: (_, __) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(board(start));
    await tester.pumpWidget(board(after));
    await tester.pump(const Duration(milliseconds: 90));

    final tops = tester
        .widgetList<Positioned>(find.byType(Positioned))
        .map((p) => p.top)
        .whereType<double>();
    final offGrid = tops.where((top) {
      final mod = top % 40;
      return mod > 0.5 && mod < 39.5;
    });
    expect(offGrid, isNotEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  });
}
