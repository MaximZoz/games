import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';

void main() {
  test('classic board is 7×6 empty', () {
    final g = Connect4Engine.newGame(Connect4Engine.modeClassic);
    expect(g.cols, 7);
    expect(g.rows, 6);
    expect(g.board.length, 42);
    expect(g.legalColumns(), [0, 1, 2, 3, 4, 5, 6]);
  });

  test('wide board is 9×7', () {
    final g = Connect4Engine.newGame(Connect4Engine.modeWide);
    expect(g.cols, 9);
    expect(g.rows, 7);
  });

  test('vertical four wins', () {
    final g = Connect4Engine.newGame(Connect4Engine.modeClassic);
    for (var i = 0; i < 3; i++) {
      g.drop(0, 0);
      g.drop(1, 1);
    }
    g.drop(0, 0);
    expect(g.winner, 0);
    expect(g.isOver, isTrue);
  });

  test('horizontal four wins', () {
    final g = Connect4Engine.newGame(Connect4Engine.modeClassic);
    g.drop(0, 0);
    g.drop(1, 0);
    g.drop(0, 1);
    g.drop(1, 1);
    g.drop(0, 2);
    g.drop(1, 2);
    g.drop(0, 3);
    expect(g.winner, 0);
  });

  test('bot blocks a winning column', () {
    final g = Connect4Engine.newGame(Connect4Engine.modeClassic);
    g.drop(0, 0);
    g.drop(1, 6);
    g.drop(0, 1);
    g.drop(1, 6);
    g.drop(0, 2);
    expect(connect4PickColumn(g), 3);
  });
}
