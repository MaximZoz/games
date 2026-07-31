import 'dart:math';

import 'package:multigames_client/games/games_repository.dart';

/// Локальная партия крестики-нолики против бота (без API).
class OfflineTicTacToeGame {
  OfflineTicTacToeGame({
    this.gridSize = 3,
    this.firstMoveRestriction = false,
    bool humanStarts = true,
  }) : board = List<String>.filled(gridSize * gridSize, '') {
    humanMark = humanStarts ? 'x' : 'o';
    turn = 'x';
    if (humanMark != turn) {
      // Бот ходит первым.
      applyBotMove();
    }
  }

  final int gridSize;
  final bool firstMoveRestriction;
  late String humanMark;
  late final List<String> board;
  late String turn;
  String status = 'playing'; // playing | x_won | o_won | draw
  List<int>? winningCells;

  String get botMark => humanMark == 'x' ? 'o' : 'x';
  bool get isHumanTurn => status == 'playing' && turn == humanMark;
  bool get isFinished => status != 'playing';
  bool get humanStarts => humanMark == 'x';

  int get winLen => GameStateItem.winLength(gridSize);

  bool playHuman(int cell) {
    if (!isHumanTurn) return false;
    if (cell < 0 || cell >= board.length) return false;
    if (board[cell].isNotEmpty) return false;
    if (!_isValidMove(cell, turn)) return false;
    board[cell] = turn;
    _afterMove();
    if (status == 'playing' && turn == botMark) {
      applyBotMove();
    }
    return true;
  }

  void applyBotMove() {
    if (status != 'playing' || turn != botMark) return;
    final cell = pickBotCell(
      board: board,
      gridSize: gridSize,
      turn: turn,
      firstMoveRestriction: firstMoveRestriction,
    );
    if (cell < 0) return;
    board[cell] = turn;
    _afterMove();
  }

  void _afterMove() {
    final line = _findWin(board, turn, gridSize);
    if (line != null) {
      winningCells = line;
      status = turn == 'x' ? 'x_won' : 'o_won';
      return;
    }
    if (board.every((c) => c.isNotEmpty)) {
      status = 'draw';
      return;
    }
    turn = turn == 'x' ? 'o' : 'x';
  }

  bool _isValidMove(int cell, String mark) {
    if (!firstMoveRestriction || mark != 'x') return true;
    if (board.any((c) => c.isNotEmpty)) return true;
    final centers = _centerIndices(gridSize);
    return !centers.contains(cell);
  }
}

List<int> _centerIndices(int gridSize) {
  if (gridSize.isOdd) {
    final c = gridSize ~/ 2;
    return [c * gridSize + c];
  }
  final a = gridSize ~/ 2 - 1;
  final b = gridSize ~/ 2;
  return [
    a * gridSize + a,
    a * gridSize + b,
    b * gridSize + a,
    b * gridSize + b,
  ];
}

List<int> _validMoves(
  List<String> board,
  int gridSize,
  String turn,
  bool firstMoveRestriction,
) {
  final out = <int>[];
  final empty = board.every((c) => c.isEmpty);
  final centers = _centerIndices(gridSize);
  for (var i = 0; i < board.length; i++) {
    if (board[i].isNotEmpty) continue;
    if (firstMoveRestriction &&
        turn == 'x' &&
        empty &&
        centers.contains(i)) {
      continue;
    }
    out.add(i);
  }
  return out;
}

bool _cellCompletesWin(
  List<String> board,
  int cell,
  String mark,
  int gridSize,
) {
  final next = List<String>.from(board);
  next[cell] = mark;
  return _findWin(next, mark, gridSize) != null;
}

List<int>? _findWin(List<String> board, String mark, int gridSize) {
  // Публичный хелпер GameStateItem недоступен как static compute — дублируем логику.
  final winLen = GameStateItem.winLength(gridSize);
  if (winLen > gridSize) return null;
  for (var row = 0; row < gridSize; row++) {
    for (var col = 0; col <= gridSize - winLen; col++) {
      final line = <int>[];
      var ok = true;
      for (var k = 0; k < winLen; k++) {
        final idx = row * gridSize + col + k;
        line.add(idx);
        if (board[idx] != mark) {
          ok = false;
          break;
        }
      }
      if (ok) return line;
    }
  }
  for (var col = 0; col < gridSize; col++) {
    for (var row = 0; row <= gridSize - winLen; row++) {
      final line = <int>[];
      var ok = true;
      for (var k = 0; k < winLen; k++) {
        final idx = (row + k) * gridSize + col;
        line.add(idx);
        if (board[idx] != mark) {
          ok = false;
          break;
        }
      }
      if (ok) return line;
    }
  }
  for (var row = 0; row <= gridSize - winLen; row++) {
    for (var col = 0; col <= gridSize - winLen; col++) {
      final line = <int>[];
      var ok = true;
      for (var k = 0; k < winLen; k++) {
        final idx = (row + k) * gridSize + col + k;
        line.add(idx);
        if (board[idx] != mark) {
          ok = false;
          break;
        }
      }
      if (ok) return line;
    }
  }
  for (var row = 0; row <= gridSize - winLen; row++) {
    for (var col = winLen - 1; col < gridSize; col++) {
      final line = <int>[];
      var ok = true;
      for (var k = 0; k < winLen; k++) {
        final idx = (row + k) * gridSize + (col - k);
        line.add(idx);
        if (board[idx] != mark) {
          ok = false;
          break;
        }
      }
      if (ok) return line;
    }
  }
  return null;
}

/// Ход бота: победа → блок → центр → случайный.
int pickBotCell({
  required List<String> board,
  required int gridSize,
  required String turn,
  required bool firstMoveRestriction,
}) {
  final moves = _validMoves(board, gridSize, turn, firstMoveRestriction);
  if (moves.isEmpty) return -1;
  final opponent = turn == 'o' ? 'x' : 'o';
  for (final cell in moves) {
    if (_cellCompletesWin(board, cell, turn, gridSize)) return cell;
  }
  for (final cell in moves) {
    if (_cellCompletesWin(board, cell, opponent, gridSize)) return cell;
  }
  final centers = _centerIndices(gridSize);
  for (final ci in centers) {
    if (moves.contains(ci)) return ci;
  }
  return moves[Random().nextInt(moves.length)];
}
