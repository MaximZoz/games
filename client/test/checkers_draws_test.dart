import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';

CheckersEngine _empty(String mode) {
  final g = CheckersEngine.newGame(mode);
  g.board = List<int>.filled(64, 0);
  return g;
}

void main() {
  test('русские: 15 ходов дамками без взятий — ничья, в том числе 2 на 2', () {
    final g = _empty(CheckersEngine.modeRussian);
    g.set(0, 1, CheckersEngine.whiteKing);
    g.set(0, 3, CheckersEngine.whiteKing);
    g.set(7, 0, CheckersEngine.blackKing);
    g.set(7, 2, CheckersEngine.blackKing);
    g.turn = 0;
    g.noProgress = CheckersEngine.russianNoProgressPlies - 1;
    g.apply(
      0,
      const CheckersMove(
        from: CheckersSquare(0, 1),
        to: CheckersSquare(1, 2),
      ),
    );
    expect(g.winner, CheckersEngine.winnerDraw);
    expect(g.drawReason, CheckersEngine.drawReasonNoProgress);
  });

  test('взятие сбрасывает счётчик пустых ходов', () {
    final g = _empty(CheckersEngine.modeRussian);
    g.set(3, 2, CheckersEngine.whiteMan);
    g.set(4, 3, CheckersEngine.blackMan);
    g.set(7, 0, CheckersEngine.blackMan);
    g.turn = 0;
    g.noProgress = 20;
    g.apply(0, g.legalMoves().first);
    expect(g.noProgress, 0);
    expect(g.winner, CheckersEngine.winnerNone);
  });

  test('английские: одна дамка против одной — ничья', () {
    final g = _empty(CheckersEngine.modeEnglish);
    g.set(3, 2, CheckersEngine.whiteKing);
    g.set(5, 4, CheckersEngine.blackKing);
    g.turn = 0;
    g.apply(
      0,
      const CheckersMove(
        from: CheckersSquare(3, 2),
        to: CheckersSquare(4, 1),
      ),
    );
    expect(g.winner, CheckersEngine.winnerDraw);
    expect(g.drawReason, CheckersEngine.drawReasonInsufficient);
  });

  test('троекратное повторение позиции — ничья', () {
    final g = _empty(CheckersEngine.modeRussian);
    g.set(3, 2, CheckersEngine.whiteKing);
    g.set(5, 4, CheckersEngine.blackKing);
    g.turn = 0;
    g.posCounts[g.positionKey()] = 2;
    g.checkAutomaticDraw();
    expect(g.winner, CheckersEngine.winnerDraw);
    expect(g.drawReason, CheckersEngine.drawReasonRepetition);
  });

  test('уголки: ходы без прогресса в цель дают ничью', () {
    final g = _empty(CheckersEngine.modeCorners);
    g.set(3, 3, CheckersEngine.whiteMan);
    g.set(4, 4, CheckersEngine.blackMan);
    g.turn = 0;
    g.noProgress = CheckersEngine.cornersNoProgressPlies - 1;
    g.apply(
      0,
      const CheckersMove(
        from: CheckersSquare(3, 3),
        to: CheckersSquare(3, 2),
      ),
    );
    expect(g.winner, CheckersEngine.winnerDraw);
    expect(g.drawReason, CheckersEngine.drawReasonNoProgress);
  });

  test('согласованная ничья помечает причину', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeRussian);
    g.agreeDraw();
    expect(g.winner, CheckersEngine.winnerDraw);
    expect(g.drawReason, CheckersEngine.drawReasonAgreed);
  });
}
