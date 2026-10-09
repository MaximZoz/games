import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_bot.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';

void main() {
  test('start position has 20 legal moves', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    expect(g.legalMoves(), hasLength(20));
    expect(g.turn, 0);
    expect(g.isOver, isFalse);
  });

  test('castling kingside is available when path is clear', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.board = List<int>.filled(64, ChessEngine.empty);
    g.set(0, 4, ChessEngine.whiteKing);
    g.set(0, 7, ChessEngine.whiteRook);
    g.set(7, 4, ChessEngine.blackKing);
    g.turn = 0;
    final moves = g.legalMoves();
    final castle = moves.where(
      (m) => m.from == const ChessSquare(0, 4) && m.to == const ChessSquare(0, 6),
    );
    expect(castle, hasLength(1));
    g.apply(0, castle.first);
    expect(g.at(0, 6), ChessEngine.whiteKing);
    expect(g.at(0, 5), ChessEngine.whiteRook);
  });

  test('pawn promotion offers four pieces and defaults to queen', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.board = List<int>.filled(64, ChessEngine.empty);
    g.set(6, 0, ChessEngine.whitePawn);
    g.set(0, 4, ChessEngine.whiteKing);
    g.set(7, 7, ChessEngine.blackKing);
    g.turn = 0;
    final promos = g.legalMoves().where(
          (m) => m.from == const ChessSquare(6, 0) && m.to == const ChessSquare(7, 0),
        );
    expect(promos, hasLength(4));
    expect(
      g.isPromotionMove(const ChessSquare(6, 0), const ChessSquare(7, 0)),
      isTrue,
    );
    g.apply(
      0,
      const ChessMove(from: ChessSquare(6, 0), to: ChessSquare(7, 0)),
    );
    expect(g.at(7, 0), ChessEngine.whiteQueen);
  });

  test("fool's mate ends with black win", () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.apply(0, const ChessMove(from: ChessSquare(1, 5), to: ChessSquare(2, 5)));
    g.apply(1, const ChessMove(from: ChessSquare(6, 4), to: ChessSquare(5, 4)));
    g.apply(0, const ChessMove(from: ChessSquare(1, 6), to: ChessSquare(3, 6)));
    g.apply(
      1,
      const ChessMove(from: ChessSquare(7, 3), to: ChessSquare(3, 7)),
    );
    expect(g.isOver, isTrue);
    expect(g.winner, 1);
  });

  test('stalemate is a draw', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.board = List<int>.filled(64, ChessEngine.empty);
    g.set(7, 7, ChessEngine.blackKing);
    g.set(5, 6, ChessEngine.whiteQueen);
    g.set(5, 5, ChessEngine.whiteKing);
    g.turn = 1;
    g.resolveEnd();
    expect(g.winner, ChessEngine.winnerDraw);
    expect(g.drawReason, ChessEngine.drawReasonStalemate);
  });

  test('insufficient material (K vs K) is a draw', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.board = List<int>.filled(64, ChessEngine.empty);
    g.set(0, 4, ChessEngine.whiteKing);
    g.set(7, 4, ChessEngine.blackKing);
    g.turn = 0;
    g.resolveEnd();
    expect(g.winner, ChessEngine.winnerDraw);
    expect(g.drawReason, ChessEngine.drawReasonInsufficient);
  });

  test('clone is independent of the original', () {
    final g = ChessEngine.newGame(ChessEngine.modeBlitz);
    g.apply(0, const ChessMove(from: ChessSquare(1, 4), to: ChessSquare(3, 4)));
    final copy = g.clone();
    expect(copy.mode, g.mode);
    expect(copy.turn, g.turn);
    expect(copy.board, g.board);
    expect(copy.legalMoves().length, g.legalMoves().length);
    copy.apply(1, const ChessMove(from: ChessSquare(6, 4), to: ChessSquare(4, 4)));
    expect(copy.turn, isNot(g.turn));
    expect(g.at(4, 4), ChessEngine.empty);
  });

  test('bot picks a legal move from the start', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    final mv = chessPickMove(g, Random(1));
    expect(mv, isNotNull);
    final legal = g.legalMoves().any(
          (m) => m.from == mv!.from && m.to == mv.to,
        );
    expect(legal, isTrue);
  });

  test('bot grabs a hanging queen', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.board = List<int>.filled(64, ChessEngine.empty);
    g.set(0, 4, ChessEngine.whiteKing);
    g.set(7, 4, ChessEngine.blackKing);
    g.set(3, 3, ChessEngine.whiteRook);
    g.set(3, 6, ChessEngine.blackQueen);
    g.turn = 0;
    final mv = chessPickMove(g, Random(1));
    expect(mv, isNotNull);
    expect(mv!.to, const ChessSquare(3, 6));
  });
}
