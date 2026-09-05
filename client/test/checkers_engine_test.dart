import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_bot.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';

void main() {
  test('start: 12 white and 12 black on dark squares', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeRussian);
    var white = 0;
    var black = 0;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = g.at(r, c);
        if (CheckersEngine.owner(p) == 0) white++;
        if (CheckersEngine.owner(p) == 1) black++;
        if (p != 0) expect(CheckersEngine.dark(r, c), isTrue);
      }
    }
    expect(white, 12);
    expect(black, 12);
    expect(g.legalMoves(), isNotEmpty);
  });

  test('man moves forward and captures all four ways', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeRussian);
    g.board = List<int>.filled(64, 0);
    g.set(3, 2, CheckersEngine.whiteMan);
    g.set(4, 3, CheckersEngine.blackMan);
    g.turn = 0;
    final caps = g.legalMoves();
    expect(caps.length, 1);
    expect(caps.first.to, const CheckersSquare(5, 4));
    g.apply(0, caps.first);
    expect(g.at(4, 3), 0);
    expect(g.at(5, 4), CheckersEngine.whiteMan);
  });

  test('giveaway: the side that cannot move wins', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeGiveaway);
    g.board = List<int>.filled(64, 0);
    g.set(0, 1, CheckersEngine.whiteMan);
    g.turn = 1;
    g.resolveEnd();
    expect(g.winner, 1);
  });

  test('дамка обязана бить дальше, но направление выбирает сама', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeRussian);
    g.board = List<int>.filled(64, 0);
    g.set(2, 1, CheckersEngine.whiteKing);
    g.set(3, 2, CheckersEngine.blackMan);
    g.set(5, 4, CheckersEngine.blackMan);
    g.set(1, 2, CheckersEngine.blackMan);
    g.turn = 0;

    final dests = g.legalMoves().map((m) => m.to).toSet();
    expect(dests, contains(const CheckersSquare(4, 3)));
    expect(dests, contains(const CheckersSquare(0, 3)));

    final short = CheckersEngine.newGame(CheckersEngine.modeRussian)
      ..board = List<int>.from(g.board)
      ..turn = 0;
    short.apply(
      0,
      const CheckersMove(
        from: CheckersSquare(2, 1),
        to: CheckersSquare(0, 3),
      ),
    );
    expect(short.mustContinue, isFalse);
    expect(short.turn, 1);

    g.apply(
      0,
      const CheckersMove(
        from: CheckersSquare(2, 1),
        to: CheckersSquare(4, 3),
      ),
    );
    expect(g.mustContinue, isTrue);
    expect(g.turn, 0);
    expect(g.contR, 4);
    expect(g.contC, 3);
    final cont = g.legalMoves();
    expect(cont, isNotEmpty);
    expect(cont.every((m) => m.from == const CheckersSquare(4, 3)), isTrue);
    expect(cont.every((m) => m.jumped.isNotEmpty), isTrue);
    expect(
      () => g.apply(
        0,
        const CheckersMove(
          from: CheckersSquare(4, 3),
          to: CheckersSquare(5, 2),
        ),
      ),
      throwsStateError,
    );
    g.apply(0, cont.first);
    expect(g.at(5, 4), 0);
    expect(g.mustContinue, isFalse);
  });

  test('английские: простая бьёт только вперёд, дамка ходит на одну клетку', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeEnglish);
    g.board = List<int>.filled(64, 0);
    g.set(4, 3, CheckersEngine.whiteMan);
    g.set(3, 2, CheckersEngine.blackMan);
    g.set(5, 4, CheckersEngine.blackMan);
    g.turn = 0;
    final caps = g.legalMoves();
    expect(caps, hasLength(1));
    expect(caps.first.to, const CheckersSquare(6, 5));

    final king = CheckersEngine.newGame(CheckersEngine.modeEnglish);
    king.board = List<int>.filled(64, 0);
    king.set(3, 2, CheckersEngine.whiteKing);
    for (final m in king.legalMoves()) {
      expect((m.to.r - m.from.r).abs(), 1);
      expect((m.to.c - m.from.c).abs(), 1);
    }
  });

  test('уголки: 9 на 9, прыжок не снимает фигуру', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeCorners);
    var white = 0;
    var black = 0;
    for (final p in g.board) {
      if (p == CheckersEngine.whiteMan) white++;
      if (p == CheckersEngine.blackMan) black++;
    }
    expect(white, 9);
    expect(black, 9);
    g.board = List<int>.filled(64, 0);
    g.set(2, 2, CheckersEngine.whiteMan);
    g.set(2, 3, CheckersEngine.blackMan);
    g.turn = 0;
    g.apply(0, const CheckersMove(
      from: CheckersSquare(2, 2),
      to: CheckersSquare(2, 4),
    ));
    expect(g.at(2, 3), CheckersEngine.blackMan);
    expect(g.at(2, 4), CheckersEngine.whiteMan);
  });

  test('bot prefers a capture', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeRussian);
    g.board = List<int>.filled(64, 0);
    g.set(3, 2, CheckersEngine.whiteMan);
    g.set(4, 3, CheckersEngine.blackMan);
    g.set(2, 1, CheckersEngine.whiteMan);
    g.turn = 0;
    final mv = checkersPickMove(g);
    expect(mv, isNotNull);
    expect(mv!.jumped, isNotEmpty);
  });

  test('уголки: бот развивает заднюю шашку, а не одну ближнюю', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeCorners);
    g.board = List<int>.filled(64, 0);
    g.set(7, 7, CheckersEngine.blackMan);
    g.set(5, 5, CheckersEngine.blackMan);
    g.set(0, 0, CheckersEngine.whiteMan);
    g.turn = 1;
    final mv = checkersPickMove(g);
    expect(mv, isNotNull);
    expect(mv!.from, const CheckersSquare(7, 7));
  });

  test('уголки: бот ходит разными шашками', () {
    final g = CheckersEngine.newGame(CheckersEngine.modeCorners);
    final froms = <CheckersSquare>{};
    var blackMoves = 0;
    for (var i = 0; i < 40 && !g.isOver && blackMoves < 8; i++) {
      final seat = g.turn;
      final mv = checkersPickMove(g);
      expect(mv, isNotNull);
      g.apply(seat, mv!);
      if (seat == 1) {
        froms.add(mv.from);
        blackMoves++;
      }
    }
    expect(froms.length, greaterThanOrEqualTo(3));
    var inStart = 0;
    for (var r = 5; r < 8; r++) {
      for (var c = 5; c < 8; c++) {
        if (CheckersEngine.owner(g.at(r, c)) == 1) inStart++;
      }
    }
    expect(inStart, lessThan(8));
  });
}
