import 'package:multigames_client/game_engine/game_engine.dart';

/// Локальная партия крестики-нолики против бота(ов) (без API).
/// Все онлайн-варианты: classic / gomoku / ultimate / multi3 / multi4.
class OfflineTicTacToeGame {
  OfflineTicTacToeGame({
    String variant = variantClassic,
    int? gridSize,
    this.firstMoveRestriction = false,
    bool humanStarts = true,
  })  : variant = parseVariant(variant),
        engine = newEngine(parseVariant(variant)) {
    final initial = engine.newState();
    board = List<String>.from(initial.board);
    this.gridSize = engine.config().gridSize;
    _state = initial;
    metaBoard = List<String>.from(initial.metaBoard);
    nextBoard = initial.nextBoard;
    final marks = engine.config().marks;
    humanMark = humanStarts ? marks.first : marks[1 % marks.length];
    // Один стартовый ход бота, если человек не ходит первым (остальные — с задержкой UI).
    if (turn != humanMark) {
      applyBotMove();
    }
  }

  final String variant;
  final Engine engine;
  late final int gridSize;
  final bool firstMoveRestriction;
  late String humanMark;
  late final List<String> board;
  late List<String> metaBoard;
  int nextBoard = -1;
  late GameEngineState _state;
  String status = 'playing'; // playing | x_won | o_won | t_won | s_won | draw
  List<int>? winningCells;
  List<int>? metaWinCells;

  String get turn => _state.turn;
  List<String> get marks => engine.config().marks;
  bool get isHumanTurn => status == 'playing' && turn == humanMark;
  bool get isFinished => status != 'playing';
  bool get humanStarts => humanMark == marks.first;
  bool get isMulti => marks.length > 2;
  bool get isUltimate => variant == variantUltimate;

  int get winLen => engine.config().winLength;

  bool playHuman(int cell) {
    if (!isHumanTurn) return false;
    if (!engine.legalCells(_state).contains(cell)) return false;
    _applyMove(cell);
    return true;
  }

  void applyBotMove() {
    if (status != 'playing' || turn == humanMark) return;
    final cell = pickBotCell(
      board: board,
      gridSize: gridSize,
      turn: turn,
      firstMoveRestriction: firstMoveRestriction,
      variant: variant,
      legalCells: engine.legalCells(_state),
      metaBoard: metaBoard,
      nextBoard: nextBoard,
      humanMark: humanMark,
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
    metaBoard = List<String>.from(result.state.metaBoard);
    nextBoard = result.state.nextBoard;
    winningCells = result.winningCells.isEmpty ? null : result.winningCells;
    metaWinCells = result.metaWinCells.isEmpty ? null : result.metaWinCells;
    if (result.state.status == 'won') {
      status = '${result.state.winner}_won';
    } else if (result.state.status == 'draw') {
      status = 'draw';
    } else {
      status = 'playing';
    }
  }
}

bool _cellCompletesWin(
  List<String> board,
  int cell,
  String mark,
  int gridSize,
  int winLen,
) {
  final next = List<String>.from(board);
  next[cell] = mark;
  return findWinLine(next, mark, gridSize, winLen).isNotEmpty;
}

/// Ход бота: победа → блок (всех соперников) → минимакс 3×3 → центр → случайный.
int pickBotCell({
  required List<String> board,
  required int gridSize,
  required String turn,
  required bool firstMoveRestriction,
  String variant = variantClassic,
  List<int>? legalCells,
  List<String>? metaBoard,
  int nextBoard = -1,
  String? humanMark,
}) {
  final resolved = parseVariant(variant);
  final cfg = configForVariant(resolved);
  final engine = newEngine(resolved);
  final state = GameEngineState(
    board: board,
    turn: turn,
    status: 'active',
    nextBoard: nextBoard,
    metaBoard: metaBoard ?? const [],
  );
  final moves = legalCells ?? engine.legalCells(state);
  if (moves.isEmpty) return -1;

  final winLen = cfg.winLength;
  final opponents = cfg.marks.where((m) => m != turn).toList();

  // 1. Своя победа
  if (resolved != variantUltimate) {
    for (final cell in moves) {
      if (_cellCompletesWin(board, cell, turn, gridSize, winLen)) {
        return cell;
      }
    }
    // 2. Блок любого соперника (сначала человека)
    final human = humanMark;
    final ordered = [
      if (human != null && opponents.contains(human)) human,
      ...opponents.where((m) => m != human),
    ];
    for (final opp in ordered) {
      for (final cell in moves) {
        if (_cellCompletesWin(board, cell, opp, gridSize, winLen)) {
          return cell;
        }
      }
    }
  } else {
    // Ultimate: победа/блок в текущем сабборде + мета.
    for (final cell in moves) {
      if (_ultimateWouldWin(board, metaBoard ?? const [], cell, turn)) {
        return cell;
      }
    }
    for (final opp in opponents) {
      for (final cell in moves) {
        if (_ultimateWouldWin(board, metaBoard ?? const [], cell, opp)) {
          return cell;
        }
      }
    }
  }

  // 3. Вилка: две угрозы сразу, затем блок чужой вилки.
  if (resolved != variantUltimate) {
    final fork = _bestFork(board, moves, turn, gridSize, winLen);
    if (fork >= 0) return fork;
    for (final opp in opponents) {
      final block = _bestFork(board, moves, opp, gridSize, winLen);
      if (block >= 0) return block;
    }
  }

  // 4. Классика 3×3 — минимакс
  if (resolved == variantClassic && gridSize == 3 && cfg.marks.length == 2) {
    final cell = _minimaxBest(board, turn, turn);
    if (cell >= 0 && moves.contains(cell)) return cell;
  }

  // 5. Поиск на больших досках.
  if (resolved != variantUltimate &&
      gridSize >= 4 &&
      gridSize <= 8 &&
      cfg.marks.length == 2) {
    final opp = opponents.first;
    final cell = _searchBoard(board, moves, turn, opp, gridSize, winLen);
    if (cell >= 0 && moves.contains(cell)) return cell;
  }

  // 6. Своя угроза, затем блок чужой.
  if (resolved != variantUltimate) {
    final threat = _bestThreat(board, moves, turn, gridSize, winLen);
    if (threat >= 0) return threat;
    for (final opp in opponents) {
      final block = _bestThreat(board, moves, opp, gridSize, winLen);
      if (block >= 0) return block;
    }
    var bestCell = moves.first;
    var bestScore = -1;
    for (final cell in moves) {
      final r = cell ~/ gridSize;
      final c = cell % gridSize;
      final s = gridSize -
          (r - gridSize ~/ 2).abs() -
          (c - gridSize ~/ 2).abs();
      if (s > bestScore) {
        bestScore = s;
        bestCell = cell;
      }
    }
    return bestCell;
  }

  return _pickUltimateCell(board, metaBoard ?? const [], moves, turn);
}

int _bestFork(
  List<String> board,
  List<int> moves,
  String mark,
  int gridSize,
  int winLen,
) {
  var best = -1;
  var bestScore = 1;
  for (final cell in moves) {
    final next = List<String>.from(board);
    next[cell] = mark;
    final n = _countOpenThreats(next, mark, gridSize, winLen);
    if (n > bestScore) {
      bestScore = n;
      best = cell;
    }
  }
  return best;
}

int _searchBoard(
  List<String> board,
  List<int> moves,
  String botMark,
  String opponent,
  int gridSize,
  int winLen,
) {
  var depth = 2;
  if (gridSize == 4) depth = 4;
  if (gridSize == 5) depth = 3;
  var bestCell = -1;
  var bestScore = -1 << 30;
  for (final cell in moves) {
    final next = List<String>.from(board);
    next[cell] = botMark;
    final score = _boardMinimax(
      next,
      opponent,
      botMark,
      opponent,
      gridSize,
      winLen,
      depth - 1,
    );
    if (score > bestScore) {
      bestScore = score;
      bestCell = cell;
    }
  }
  return bestCell;
}

int _boardMinimax(
  List<String> board,
  String toMove,
  String botMark,
  String opponent,
  int gridSize,
  int winLen,
  int depth,
) {
  if (findWinLine(board, botMark, gridSize, winLen).isNotEmpty) {
    return 1000 + depth;
  }
  if (findWinLine(board, opponent, gridSize, winLen).isNotEmpty) {
    return -1000 - depth;
  }
  if (board.every((c) => c.isNotEmpty) || depth <= 0) {
    return _countOpenThreats(board, botMark, gridSize, winLen) * 30 -
        _countOpenThreats(board, opponent, gridSize, winLen) * 40;
  }
  final moves = <int>[];
  for (var i = 0; i < board.length; i++) {
    if (board[i].isEmpty) moves.add(i);
  }
  if (moves.isEmpty) return 0;
  final next = toMove == botMark ? opponent : botMark;
  if (toMove == botMark) {
    var best = -1 << 30;
    for (final cell in moves) {
      final cp = List<String>.from(board);
      cp[cell] = toMove;
      final s = _boardMinimax(
        cp,
        next,
        botMark,
        opponent,
        gridSize,
        winLen,
        depth - 1,
      );
      if (s > best) best = s;
    }
    return best;
  }
  var best = 1 << 30;
  for (final cell in moves) {
    final cp = List<String>.from(board);
    cp[cell] = toMove;
    final s = _boardMinimax(
      cp,
      next,
      botMark,
      opponent,
      gridSize,
      winLen,
      depth - 1,
    );
    if (s < best) best = s;
  }
  return best;
}

int _pickUltimateCell(
  List<String> board,
  List<String> meta,
  List<int> moves,
  String turn,
) {
  final opp = turn == 'x' ? 'o' : 'x';
  var best = moves.first;
  var bestScore = -1 << 30;
  for (final cell in moves) {
    final s = _ultimateScore(board, meta, cell, turn, opp);
    if (s > bestScore) {
      bestScore = s;
      best = cell;
    }
  }
  return best;
}

int _ultimateScore(
  List<String> board,
  List<String> meta,
  int cell,
  String bot,
  String opp,
) {
  final nextBoard = List<String>.from(board);
  nextBoard[cell] = bot;
  final sub = cell ~/ 9;
  final local = cell % 9;
  final nextMeta = List<String>.filled(9, '');
  for (var i = 0; i < 9; i++) {
    nextMeta[i] = i < meta.length ? meta[i] : '';
  }
  final subBoard = List<String>.filled(9, '');
  final base = sub * 9;
  for (var i = 0; i < 9; i++) {
    subBoard[i] = nextBoard[base + i];
  }
  final wonSub = findWinLine(subBoard, bot, 3, 3).length == 3;
  if (wonSub) nextMeta[sub] = bot;
  if (findWinLine(nextMeta, bot, 3, 3).length == 3) return 10000;
  var score = 0;
  if (wonSub) score += 400;
  if (_ultimateWouldWin(board, meta, cell, opp)) score += 350;
  if (local == 4) {
    score += 18;
  } else if (local.isEven) {
    score += 8;
  }
  if (sub == 4) score += 12;
  final forced = local;
  final forcedClosed = forced < nextMeta.length &&
      (nextMeta[forced].isNotEmpty ||
          List.generate(9, (i) => nextBoard[forced * 9 + i])
              .every((c) => c.isNotEmpty));
  if (forcedClosed) {
    score += 40;
  } else if (forced == 4) {
    score -= 15;
  }
  return score;
}

int _bestThreat(
  List<String> board,
  List<int> moves,
  String mark,
  int gridSize,
  int winLen,
) {
  var best = -1;
  var bestScore = 0;
  for (final cell in moves) {
    final next = List<String>.from(board);
    next[cell] = mark;
    final n = _countOpenThreats(next, mark, gridSize, winLen);
    if (n > bestScore) {
      bestScore = n;
      best = cell;
    }
  }
  return bestScore > 0 ? best : -1;
}

int _countOpenThreats(
  List<String> board,
  String mark,
  int gridSize,
  int winLen,
) {
  var n = 0;
  const dirs = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];
  for (var r = 0; r < gridSize; r++) {
    for (var c = 0; c < gridSize; c++) {
      for (final d in dirs) {
        var own = 0;
        var empty = 0;
        var ok = true;
        for (var k = 0; k < winLen; k++) {
          final rr = r + d[0] * k;
          final cc = c + d[1] * k;
          if (rr < 0 || cc < 0 || rr >= gridSize || cc >= gridSize) {
            ok = false;
            break;
          }
          final v = board[rr * gridSize + cc];
          if (v == mark) {
            own++;
          } else if (v.isEmpty) {
            empty++;
          } else {
            ok = false;
            break;
          }
        }
        if (ok && own == winLen - 1 && empty == 1) n++;
      }
    }
  }
  return n;
}

bool _ultimateWouldWin(
  List<String> board,
  List<String> meta,
  int cell,
  String mark,
) {
  final nextBoard = List<String>.from(board);
  nextBoard[cell] = mark;
  final sub = cell ~/ 9;
  final subBoard = List<String>.filled(9, '');
  final base = sub * 9;
  for (var i = 0; i < 9; i++) {
    subBoard[i] = nextBoard[base + i];
  }
  if (findWinLine(subBoard, mark, 3, 3).length != 3) return false;
  final nextMeta = List<String>.filled(9, '');
  for (var i = 0; i < 9; i++) {
    nextMeta[i] = i < meta.length ? meta[i] : '';
  }
  nextMeta[sub] = mark;
  return findWinLine(nextMeta, mark, 3, 3).length == 3;
}

int _minimaxBest(List<String> board, String botMark, String turn) {
  final moves = <int>[];
  for (var i = 0; i < board.length; i++) {
    if (board[i].isEmpty) moves.add(i);
  }
  if (moves.isEmpty) return -1;
  var bestScore = -20;
  var bestCell = -1;
  for (final cell in moves) {
    final cp = List<String>.from(board);
    cp[cell] = botMark;
    final score = _minimax(cp, botMark, botMark == 'x' ? 'o' : 'x', false);
    if (score > bestScore) {
      bestScore = score;
      bestCell = cell;
    }
  }
  return bestCell;
}

int _minimax(
  List<String> board,
  String botMark,
  String turn,
  bool maximizing,
) {
  if (findWinLine(board, 'x', 3, 3).isNotEmpty) {
    return botMark == 'x' ? 10 : -10;
  }
  if (findWinLine(board, 'o', 3, 3).isNotEmpty) {
    return botMark == 'o' ? 10 : -10;
  }
  if (board.every((c) => c.isNotEmpty)) return 0;

  final moves = <int>[];
  for (var i = 0; i < board.length; i++) {
    if (board[i].isEmpty) moves.add(i);
  }
  if (maximizing) {
    var best = -20;
    for (final cell in moves) {
      final cp = List<String>.from(board);
      cp[cell] = turn;
      final next = turn == 'x' ? 'o' : 'x';
      final s = _minimax(cp, botMark, next, false);
      if (s > best) best = s;
    }
    return best;
  }
  var best = 20;
  for (final cell in moves) {
    final cp = List<String>.from(board);
    cp[cell] = turn;
    final next = turn == 'x' ? 'o' : 'x';
    final s = _minimax(cp, botMark, next, true);
    if (s < best) best = s;
  }
  return best;
}
