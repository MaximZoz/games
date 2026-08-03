import 'dart:math';

import 'package:multigames_client/game_engine/game_engine.dart';

/// Локальная партия крестики-нолики против бота (без API).
class OfflineTicTacToeGame {
  OfflineTicTacToeGame({
    String variant = variantClassic,
    int? gridSize,
    this.firstMoveRestriction = false,
    bool humanStarts = true,
  })  : variant = _offlineVariant(variant, gridSize),
        engine = newEngine(_offlineVariant(variant, gridSize)) {
    final initial = engine.newState();
    board = List<String>.from(initial.board);
    this.gridSize = engine.config().gridSize;
    _state = initial;
    humanMark = humanStarts ? 'x' : 'o';
    if (humanMark != turn) {
      // Бот ходит первым.
      applyBotMove();
    }
  }

  final String variant;
  final Engine engine;
  late final int gridSize;
  final bool firstMoveRestriction;
  late String humanMark;
  late final List<String> board;
  late GameEngineState _state;
  String status = 'playing'; // playing | x_won | o_won | draw
  List<int>? winningCells;

  String get turn => _state.turn;
  String get botMark => humanMark == 'x' ? 'o' : 'x';
  bool get isHumanTurn => status == 'playing' && turn == humanMark;
  bool get isFinished => status != 'playing';
  bool get humanStarts => humanMark == 'x';

  int get winLen => engine.config().winLength;

  bool playHuman(int cell) {
    if (!isHumanTurn) return false;
    if (!engine.legalCells(_state).contains(cell)) return false;
    _applyMove(cell);
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
      variant: variant,
      legalCells: engine.legalCells(_state),
    );
    if (cell < 0) return;
    _applyMove(cell);
  }

  void _applyMove(int cell) {
    final result = engine.applyMove(_state, cell);
    _state = result.state;
    for (var i = 0; i < board.length && i < result.state.board.length; i++) {
      board[i] = result.state.board[i];
    }
    winningCells = result.winningCells.isEmpty ? null : result.winningCells;
    if (result.state.status == 'won') {
      status = '${result.state.winner}_won';
    } else if (result.state.status == 'draw') {
      status = 'draw';
    } else {
      status = 'playing';
    }
  }
}

String _offlineVariant(String variant, int? gridSize) {
  final parsed = parseVariant(variant);
  if (parsed != variantClassic || gridSize == null) return parsed;
  return variantFromLegacyGrid(gridSize);
}

bool _cellCompletesWin(
  List<String> board,
  int cell,
  String mark,
  int gridSize,
  String variant,
) {
  final next = List<String>.from(board);
  next[cell] = mark;
  return _findWin(next, mark, gridSize, variant) != null;
}

List<int>? _findWin(
  List<String> board,
  String mark,
  int gridSize,
  String variant,
) {
  final winLen = configForVariant(_offlineVariant(variant, gridSize)).winLength;
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
  String variant = variantClassic,
  List<int>? legalCells,
}) {
  final resolvedVariant = _offlineVariant(variant, gridSize);
  final moves = legalCells ??
      newEngine(resolvedVariant).legalCells(
        GameEngineState(
          board: board,
          turn: turn,
          status: 'active',
          nextBoard: -1,
        ),
      );
  if (moves.isEmpty) return -1;
  final opponent = turn == 'o' ? 'x' : 'o';
  final cfg = configForVariant(resolvedVariant);
  if (cfg.variant == variantClassic || cfg.variant == variantGomoku) {
    for (final cell in moves) {
      if (_cellCompletesWin(board, cell, turn, gridSize, resolvedVariant)) {
        return cell;
      }
    }
    for (final cell in moves) {
      if (_cellCompletesWin(board, cell, opponent, gridSize, resolvedVariant)) {
        return cell;
      }
    }
  }
  if (cfg.variant != variantUltimate) {
    final center = (gridSize ~/ 2) * gridSize + (gridSize ~/ 2);
    if (moves.contains(center)) return center;
  }
  return moves[Random().nextInt(moves.length)];
}
