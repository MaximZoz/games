/// Клиентский движок «Четыре в ряд» — те же правила, что сервер.
class Connect4Engine {
  Connect4Engine({
    required this.mode,
    required this.cols,
    required this.rows,
    required List<int> board,
    this.turn = 0,
    this.winner = -1,
    this.seq = 0,
    this.lastCol = -1,
    this.lastRow = -1,
  }) : board = List<int>.from(board);

  String mode;
  int cols;
  int rows;
  List<int> board;
  int turn;
  int winner;
  int seq;
  int lastCol;
  int lastRow;

  static const modeClassic = 'classic';
  static const modeWide = 'wide';
  static const winnerNone = -1;
  static const winnerDraw = -2;

  static String normalizeMode(String? raw) =>
      raw == modeWide ? modeWide : modeClassic;

  static (int, int) sizeForMode(String mode) =>
      normalizeMode(mode) == modeWide ? (9, 7) : (7, 6);

  factory Connect4Engine.newGame(String mode) {
    final m = normalizeMode(mode);
    final (cols, rows) = sizeForMode(m);
    return Connect4Engine(
      mode: m,
      cols: cols,
      rows: rows,
      board: List<int>.filled(cols * rows, 0),
    );
  }

  bool get isOver => winner != winnerNone;

  int _idx(int c, int r) => r * cols + c;

  int at(int c, int r) {
    if (c < 0 || r < 0 || c >= cols || r >= rows) return -1;
    return board[_idx(c, r)];
  }

  List<int> legalColumns() {
    if (isOver) return const [];
    return [
      for (var c = 0; c < cols; c++)
        if (at(c, rows - 1) == 0) c,
    ];
  }

  void drop(int seat, int col) {
    if (isOver) throw StateError('game is over');
    if (seat != turn) throw StateError('not your turn');
    if (col < 0 || col >= cols) throw StateError('illegal move');
    var row = -1;
    for (var r = 0; r < rows; r++) {
      if (at(col, r) == 0) {
        row = r;
        break;
      }
    }
    if (row < 0) throw StateError('column is full');
    board[_idx(col, row)] = seat + 1;
    lastCol = col;
    lastRow = row;
    seq++;
    if (_hasWin(col, row, seat + 1)) {
      winner = seat;
      return;
    }
    if (legalColumns().isEmpty) {
      winner = winnerDraw;
      return;
    }
    turn = 1 - turn;
  }

  void forfeit(int seat) {
    if (isOver) return;
    winner = 1 - seat;
    seq++;
  }

  void agreeDraw() {
    if (isOver) return;
    winner = winnerDraw;
    seq++;
  }

  bool _hasWin(int c, int r, int piece) {
    const dirs = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1],
    ];
    for (final d in dirs) {
      var n = 1;
      n += _count(c, r, d[0], d[1], piece);
      n += _count(c, r, -d[0], -d[1], piece);
      if (n >= 4) return true;
    }
    return false;
  }

  int _count(int c, int r, int dc, int dr, int piece) {
    var n = 0;
    var cc = c + dc;
    var rr = r + dr;
    while (at(cc, rr) == piece) {
      n++;
      cc += dc;
      rr += dr;
    }
    return n;
  }
}

int connect4PickColumn(Connect4Engine g) {
  final legal = g.legalColumns();
  if (legal.isEmpty) return -1;
  for (final c in legal) {
    if (_wouldWin(g, c, g.turn)) return c;
  }
  final opp = 1 - g.turn;
  for (final c in legal) {
    if (_wouldWin(g, c, opp)) return c;
  }
  final center = g.cols ~/ 2;
  legal.sort((a, b) => (a - center).abs().compareTo((b - center).abs()));
  return legal.first;
}

bool _wouldWin(Connect4Engine g, int col, int seat) {
  final clone = Connect4Engine(
    mode: g.mode,
    cols: g.cols,
    rows: g.rows,
    board: g.board,
    turn: seat,
    winner: g.winner,
  );
  try {
    clone.drop(seat, col);
  } catch (_) {
    return false;
  }
  return clone.winner == seat;
}
