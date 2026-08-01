import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/offline_tictactoe.dart';

void main() {
  test('бот занимает выигрышный ход', () {
    final board = [
      'o', 'o', '',
      'x', 'x', '',
      '', '', '',
    ];
    final cell = pickBotCell(
      board: board,
      gridSize: 3,
      turn: 'o',
      firstMoveRestriction: false,
    );
    expect(cell, 2);
  });

  test('бот блокирует победу игрока', () {
    final board = [
      'x', 'x', '',
      'o', '', '',
      '', '', '',
    ];
    final cell = pickBotCell(
      board: board,
      gridSize: 3,
      turn: 'o',
      firstMoveRestriction: false,
    );
    expect(cell, 2);
  });

  test('при humanStarts=false бот ходит первым', () {
    final game = OfflineTicTacToeGame(gridSize: 3, humanStarts: false);
    expect(game.humanMark, 'o');
    expect(game.isHumanTurn, isTrue);
    expect(game.board.where((c) => c.isNotEmpty).length, 1);
    expect(game.humanStarts, isFalse);
  });

  test('при humanStarts=true доска пустая и ход игрока', () {
    final game = OfflineTicTacToeGame(gridSize: 3, humanStarts: true);
    expect(game.humanMark, 'x');
    expect(game.isHumanTurn, isTrue);
    expect(game.board.every((c) => c.isEmpty), isTrue);
  });

  test('локальная партия завершается победой или ничьей', () {
    final game = OfflineTicTacToeGame(gridSize: 3);
    // Заполняем доску вручную через ходы, пока возможно.
    var guard = 0;
    while (!game.isFinished && guard < 20) {
      guard++;
      if (!game.isHumanTurn) {
        game.applyBotMove();
        continue;
      }
      final empty = <int>[];
      for (var i = 0; i < game.board.length; i++) {
        if (game.board[i].isEmpty) empty.add(i);
      }
      if (empty.isEmpty) break;
      game.playHuman(empty.first);
    }
    expect(game.isFinished, isTrue);
    expect(
      ['x_won', 'o_won', 'draw'].contains(game.status),
      isTrue,
    );
  });
}
