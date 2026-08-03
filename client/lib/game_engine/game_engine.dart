class GameEngineException implements Exception {
  const GameEngineException(this.message);

  final String message;

  @override
  String toString() => 'GameEngineException: $message';
}

const variantClassic = 'classic';
const variantGomoku = 'gomoku';
const variantUltimate = 'ultimate';
const variantMulti3 = 'multi3';
const variantMulti4 = 'multi4';

const allGameVariants = <String>[
  variantClassic,
  variantGomoku,
  variantUltimate,
  variantMulti3,
  variantMulti4,
];

class GameConfig {
  const GameConfig({
    required this.variant,
    required this.gridSize,
    required this.winLength,
    required this.maxPlayers,
    required this.marks,
    required this.cellCount,
  });

  final String variant;
  final int gridSize;
  final int winLength;
  final int maxPlayers;
  final List<String> marks;
  final int cellCount;
}

String parseVariant(String? raw) {
  switch (raw) {
    case variantGomoku:
    case variantUltimate:
    case variantMulti3:
    case variantMulti4:
      return raw!;
    default:
      return variantClassic;
  }
}

String variantFromLegacyGrid(int gridSize) {
  if (gridSize == 15) return variantGomoku;
  return variantClassic;
}

GameConfig configForVariant(String? raw) {
  switch (parseVariant(raw)) {
    case variantGomoku:
      return const GameConfig(
        variant: variantGomoku,
        gridSize: 15,
        winLength: 5,
        maxPlayers: 2,
        marks: ['x', 'o'],
        cellCount: 225,
      );
    case variantUltimate:
      return const GameConfig(
        variant: variantUltimate,
        gridSize: 9,
        winLength: 3,
        maxPlayers: 2,
        marks: ['x', 'o'],
        cellCount: 81,
      );
    case variantMulti3:
      return const GameConfig(
        variant: variantMulti3,
        gridSize: 8,
        winLength: 4,
        maxPlayers: 3,
        marks: ['x', 'o', 't'],
        cellCount: 64,
      );
    case variantMulti4:
      return const GameConfig(
        variant: variantMulti4,
        gridSize: 10,
        winLength: 4,
        maxPlayers: 4,
        marks: ['x', 'o', 't', 's'],
        cellCount: 100,
      );
    case variantClassic:
    default:
      return const GameConfig(
        variant: variantClassic,
        gridSize: 3,
        winLength: 3,
        maxPlayers: 2,
        marks: ['x', 'o'],
        cellCount: 9,
      );
  }
}

class GameEngineState {
  const GameEngineState({
    required this.board,
    required this.turn,
    required this.status,
    this.winner = '',
    this.nextBoard = -1,
    this.metaBoard = const [],
  });

  final List<String> board;
  final String turn;
  final String status;
  final String winner;
  final int nextBoard;
  final List<String> metaBoard;

  GameEngineState copyWith({
    List<String>? board,
    String? turn,
    String? status,
    String? winner,
    int? nextBoard,
    List<String>? metaBoard,
  }) {
    return GameEngineState(
      board: board ?? this.board,
      turn: turn ?? this.turn,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      nextBoard: nextBoard ?? this.nextBoard,
      metaBoard: metaBoard ?? this.metaBoard,
    );
  }
}

class MoveResult {
  const MoveResult({
    required this.state,
    this.winningCells = const [],
    this.metaWinCells = const [],
  });

  final GameEngineState state;
  final List<int> winningCells;
  final List<int> metaWinCells;
}

abstract class Engine {
  GameConfig config();
  GameEngineState newState();
  MoveResult applyMove(GameEngineState state, int cell);
  List<int> legalCells(GameEngineState state);

  // Compatibility aliases for the server-style names used in issue #76.
  // ignore: non_constant_identifier_names
  GameConfig Config() => config();
  // ignore: non_constant_identifier_names
  GameEngineState NewState() => newState();
  // ignore: non_constant_identifier_names
  MoveResult ApplyMove(GameEngineState state, int cell) =>
      applyMove(state, cell);
  // ignore: non_constant_identifier_names
  List<int> LegalCells(GameEngineState state) => legalCells(state);
}

Engine newEngine(String? variant) {
  final cfg = configForVariant(variant);
  if (cfg.variant == variantUltimate) return _UltimateEngine(cfg);
  return _LineEngine(cfg);
}

List<String> emptyBoard(int n) => List<String>.filled(n, '');

String nextMark(List<String> marks, String current) {
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == current) return marks[(i + 1) % marks.length];
  }
  return marks.isEmpty ? current : marks.first;
}

bool isBoardFull(List<String> board) => board.every((c) => c.isNotEmpty);

List<int> findWinLine(
  List<String> board,
  String mark,
  int gridSize,
  int winLength,
) {
  if (winLength > gridSize) return const [];
  const dirs = <(int, int)>[(0, 1), (1, 0), (1, 1), (1, -1)];
  for (var row = 0; row < gridSize; row++) {
    for (var col = 0; col < gridSize; col++) {
      for (final (dr, dc) in dirs) {
        final line = <int>[];
        var ok = true;
        for (var k = 0; k < winLength; k++) {
          final r = row + dr * k;
          final c = col + dc * k;
          if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
            ok = false;
            break;
          }
          final idx = r * gridSize + c;
          if (idx >= board.length || board[idx] != mark) {
            ok = false;
            break;
          }
          line.add(idx);
        }
        if (ok) return line;
      }
    }
  }
  return const [];
}

class _LineEngine extends Engine {
  _LineEngine(this._cfg);

  final GameConfig _cfg;

  @override
  GameConfig config() => _cfg;

  @override
  GameEngineState newState() {
    return GameEngineState(
      board: emptyBoard(_cfg.cellCount),
      turn: _cfg.marks.first,
      status: 'active',
      nextBoard: -1,
    );
  }

  @override
  List<int> legalCells(GameEngineState state) {
    if (state.status != 'active') return const [];
    final out = <int>[];
    for (var i = 0; i < state.board.length; i++) {
      if (state.board[i].isEmpty) out.add(i);
    }
    return out;
  }

  @override
  MoveResult applyMove(GameEngineState state, int cell) {
    if (state.status != 'active') {
      throw const GameEngineException('game over');
    }
    final n = _cfg.gridSize;
    if (cell < 0 || cell >= n * n || state.board[cell].isNotEmpty) {
      throw const GameEngineException('illegal move');
    }
    final mark = state.turn;
    final board = List<String>.from(state.board);
    board[cell] = mark;
    final line = findWinLine(board, mark, n, _cfg.winLength);
    final next = GameEngineState(
      board: board,
      turn: nextMark(_cfg.marks, mark),
      status: 'active',
      nextBoard: -1,
    );
    if (line.length == _cfg.winLength) {
      return MoveResult(
        state: next.copyWith(status: 'won', winner: mark, turn: mark),
        winningCells: line,
      );
    }
    if (isBoardFull(board)) {
      return MoveResult(state: next.copyWith(status: 'draw', winner: ''));
    }
    return MoveResult(state: next);
  }
}

class _UltimateEngine extends Engine {
  _UltimateEngine(this._cfg);

  final GameConfig _cfg;

  @override
  GameConfig config() => _cfg;

  @override
  GameEngineState newState() {
    return GameEngineState(
      board: emptyBoard(81),
      turn: _cfg.marks.first,
      status: 'active',
      nextBoard: -1,
      metaBoard: emptyBoard(9),
    );
  }

  @override
  List<int> legalCells(GameEngineState state) {
    if (state.status != 'active') return const [];
    final meta = _normalizedMeta(state.metaBoard);
    final forced = state.nextBoard;
    if (forced >= 0 &&
        forced < 9 &&
        meta[forced].isEmpty &&
        !_subBoardFull(state.board, forced)) {
      return _openCellsInSub(state.board, forced);
    }
    final out = <int>[];
    for (var sub = 0; sub < 9; sub++) {
      if (meta[sub].isNotEmpty) continue;
      out.addAll(_openCellsInSub(state.board, sub));
    }
    return out;
  }

  @override
  MoveResult applyMove(GameEngineState state, int cell) {
    if (state.status != 'active') {
      throw const GameEngineException('game over');
    }
    if (cell < 0 || cell >= 81 || state.board[cell].isNotEmpty) {
      throw const GameEngineException('illegal move');
    }
    if (!legalCells(state).contains(cell)) {
      throw const GameEngineException('illegal move');
    }

    final mark = state.turn;
    final board = List<String>.from(state.board);
    board[cell] = mark;
    final meta = _normalizedMeta(state.metaBoard);
    final sub = cell ~/ 9;
    final local = cell % 9;
    final subBoard = _extractSub(board, sub);
    if (findWinLine(subBoard, mark, 3, 3).length == 3) {
      meta[sub] = mark;
    } else if (isBoardFull(subBoard)) {
      meta[sub] = 'd';
    }

    var nextForced = local;
    if (meta[nextForced].isNotEmpty || _subBoardFull(board, nextForced)) {
      nextForced = -1;
    }

    final next = GameEngineState(
      board: board,
      turn: nextMark(_cfg.marks, mark),
      status: 'active',
      nextBoard: nextForced,
      metaBoard: meta,
    );
    final metaLine = findWinLine(_metaMarksOnly(meta), mark, 3, 3);
    if (metaLine.length == 3) {
      return MoveResult(
        state: next.copyWith(status: 'won', winner: mark, turn: mark),
        winningCells: _cellsOfSub(sub),
        metaWinCells: metaLine,
      );
    }
    if (isBoardFull(meta)) {
      return MoveResult(state: next.copyWith(status: 'draw', winner: ''));
    }
    return MoveResult(state: next);
  }
}

List<String> _normalizedMeta(List<String> meta) {
  if (meta.length != 9) return emptyBoard(9);
  return List<String>.from(meta);
}

List<String> _extractSub(List<String> board, int sub) {
  final out = List<String>.filled(9, '');
  final base = sub * 9;
  for (var i = 0; i < 9; i++) {
    out[i] = base + i < board.length ? board[base + i] : '';
  }
  return out;
}

List<int> _openCellsInSub(List<String> board, int sub) {
  final out = <int>[];
  final base = sub * 9;
  for (var i = 0; i < 9; i++) {
    final idx = base + i;
    if (idx < board.length && board[idx].isEmpty) out.add(idx);
  }
  return out;
}

bool _subBoardFull(List<String> board, int sub) {
  final base = sub * 9;
  for (var i = 0; i < 9; i++) {
    final idx = base + i;
    if (idx >= board.length || board[idx].isEmpty) return false;
  }
  return true;
}

List<int> _cellsOfSub(int sub) {
  final base = sub * 9;
  return List<int>.generate(9, (i) => base + i);
}

List<String> _metaMarksOnly(List<String> meta) {
  final out = List<String>.filled(9, '');
  for (var i = 0; i < meta.length && i < 9; i++) {
    final mark = meta[i];
    if (mark == 'x' || mark == 'o') out[i] = mark;
  }
  return out;
}
