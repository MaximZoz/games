import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_bot.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';

void main() {
  test('payload движка сохраняет позицию для изолята', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.apply(0, const ChessMove(from: ChessSquare(1, 4), to: ChessSquare(3, 4)));
    final back = chessEngineFromPayload(chessEnginePayload(g));
    expect(back.board, g.board);
    expect(back.turn, 1);
    expect(back.lastToR, 3);
    expect(back.lastToC, 4);
    expect(back.posCounts, g.posCounts);
  });

  test('bot develops pieces instead of marching the a-pawn', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    final white = <ChessMove>[
      const ChessMove(from: ChessSquare(1, 4), to: ChessSquare(3, 4)),
      const ChessMove(from: ChessSquare(0, 6), to: ChessSquare(2, 5)),
      const ChessMove(from: ChessSquare(0, 5), to: ChessSquare(3, 2)),
      const ChessMove(from: ChessSquare(1, 3), to: ChessSquare(3, 3)),
    ];
    var aPawnPushes = 0;
    for (final w in white) {
      g.apply(0, w);
      final mv = chessPickMove(g, Random(7));
      expect(mv, isNotNull);
      if (mv!.from.c == 0) aPawnPushes++;
      g.apply(1, mv);
    }
    expect(aPawnPushes, lessThan(2),
        reason: 'bot should develop, not keep pushing the edge pawn');
  });
}
