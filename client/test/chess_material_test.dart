import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_material.dart';

void main() {
  test('в стартовой позиции перевеса нет', () {
    final board = ChessEngine.newGame(ChessEngine.modeClassic).board;
    expect(chessMaterialFor(board, 0), ChessMaterial.empty);
    expect(chessMaterialFor(board, 1), ChessMaterial.empty);
  });

  test('съеденная пешка видна у соперника как +1', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.set(1, 0, ChessEngine.empty);
    final black = chessMaterialFor(g.board, 1);
    expect(black.captured, [ChessEngine.whitePawn]);
    expect(black.advantage, 1);
    expect(chessMaterialFor(g.board, 0).advantage, 0);
    expect(chessMaterialFor(g.board, 0).captured, isEmpty);
  });

  test('превращение: лишний ферзь и минус пешка дают +8', () {
    final g = ChessEngine.newGame(ChessEngine.modeClassic);
    g.set(1, 0, ChessEngine.whiteQueen);
    final white = chessMaterialFor(g.board, 0);
    expect(white.captured, [ChessEngine.blackQueen]);
    expect(white.advantage, 8);
    final black = chessMaterialFor(g.board, 1);
    expect(black.captured, [ChessEngine.whitePawn]);
    expect(black.advantage, 0);
  });
}
