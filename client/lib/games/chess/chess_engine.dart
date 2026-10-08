/// Классические шахматы — те же правила, что и сервер (`server/internal/chess`).
///
/// Доска: 64 клетки row-major, индекс = r*8 + c. Ряд r=0 — первая горизонталь
/// белых, белые пешки на r=1 и идут вверх. Seat 0 — белые, seat 1 — чёрные.
class ChessSquare {
  const ChessSquare(this.r, this.c);
  final int r;
  final int c;

  @override
  bool operator ==(Object other) =>
      other is ChessSquare && other.r == r && other.c == c;

  @override
  int get hashCode => Object.hash(r, c);

  Map<String, dynamic> toJson() => {'r': r, 'c': c};

  factory ChessSquare.fromJson(Map<String, dynamic> json) => ChessSquare(
        (json['r'] as num?)?.toInt() ?? 0,
        (json['c'] as num?)?.toInt() ?? 0,
      );
}

class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    this.promo = 0,
  });

  final ChessSquare from;
  final ChessSquare to;
  final int promo;

  Map<String, dynamic> toJson() => {
        'from': from.toJson(),
        'to': to.toJson(),
        if (promo != 0) 'promo': promo,
      };

  factory ChessMove.fromJson(Map<String, dynamic> json) => ChessMove(
        from: ChessSquare.fromJson((json['from'] as Map).cast<String, dynamic>()),
        to: ChessSquare.fromJson((json['to'] as Map).cast<String, dynamic>()),
        promo: (json['promo'] as num?)?.toInt() ?? 0,
      );
}

class ChessEngine {
  ChessEngine({
    required this.mode,
    required List<int> board,
    this.turn = 0,
    this.winner = -1,
    this.seq = 0,
    List<bool>? castle,
    this.enPassant = -1,
    this.halfMove = 0,
    this.lastFromR = -1,
    this.lastFromC = -1,
    this.lastToR = -1,
    this.lastToC = -1,
    Map<String, int>? posCounts,
    this.drawReason = '',
  })  : board = List<int>.from(board),
        castle = List<bool>.from(castle ?? const [true, true, true, true]),
        posCounts = Map<String, int>.from(posCounts ?? const {});

  static const modeClassic = 'classic';
  static const modeRapid = 'rapid';
  static const modeBlitz = 'blitz';
  static const modeBullet = 'bullet';
  static const allModes = [modeClassic, modeRapid, modeBlitz, modeBullet];

  static const empty = 0;
  static const whitePawn = 1;
  static const whiteKnight = 2;
  static const whiteBishop = 3;
  static const whiteRook = 4;
  static const whiteQueen = 5;
  static const whiteKing = 6;
  static const blackPawn = 7;
  static const blackKnight = 8;
  static const blackBishop = 9;
  static const blackRook = 10;
  static const blackQueen = 11;
  static const blackKing = 12;

  static const winnerNone = -1;
  static const winnerDraw = -2;
  static const size = 8;
  static const fiftyMovePlies = 100;

  static const drawReasonStalemate = 'stalemate';
  static const drawReasonInsufficient = 'insufficient';
  static const drawReasonRepetition = 'repetition';
  static const drawReasonFiftyMove = 'fifty_move';
  static const drawReasonAgreed = 'agreed';

  static const _cWK = 0;
  static const _cWQ = 1;
  static const _cBK = 2;
  static const _cBQ = 3;

  String mode;
  List<int> board;
  int turn;
  int winner;
  int seq;
  List<bool> castle;
  int enPassant;
  int halfMove;
  int lastFromR;
  int lastFromC;
  int lastToR;
  int lastToC;
  Map<String, int> posCounts;
  String drawReason;

  static String normalizeMode(String? raw) {
    switch (raw) {
      case modeRapid:
      case modeBlitz:
      case modeBullet:
        return raw!;
      default:
        return modeClassic;
    }
  }

  factory ChessEngine.newGame(String mode) {
    final g = ChessEngine(
      mode: normalizeMode(mode),
      board: List<int>.filled(size * size, empty),
    );
    const back = [
      whiteRook,
      whiteKnight,
      whiteBishop,
      whiteQueen,
      whiteKing,
      whiteBishop,
      whiteKnight,
      whiteRook,
    ];
    for (var c = 0; c < size; c++) {
      g.set(0, c, back[c]);
      g.set(1, c, whitePawn);
      g.set(6, c, blackPawn);
      g.set(7, c, back[c] + 6);
    }
    g.posCounts[g._positionKey()] = 1;
    return g;
  }

  bool get isOver => winner != winnerNone;

  ChessEngine clone() => ChessEngine(
        mode: mode,
        board: List<int>.from(board),
        turn: turn,
        winner: winner,
        seq: seq,
        castle: List<bool>.from(castle),
        enPassant: enPassant,
        halfMove: halfMove,
        lastFromR: lastFromR,
        lastFromC: lastFromC,
        lastToR: lastToR,
        lastToC: lastToC,
        posCounts: posCounts,
        drawReason: drawReason,
      );

  int idx(int r, int c) => r * size + c;

  static bool inBounds(int r, int c) => r >= 0 && c >= 0 && r < size && c < size;

  int at(int r, int c) => inBounds(r, c) ? board[idx(r, c)] : -1;

  void set(int r, int c, int v) => board[idx(r, c)] = v;

  static int colorOf(int piece) {
    if (piece >= whitePawn && piece <= whiteKing) return 0;
    if (piece >= blackPawn && piece <= blackKing) return 1;
    return -1;
  }

  static int kind(int piece) => piece <= empty ? 0 : ((piece - 1) % 6) + 1;

  static const _knightDirs = [
    [2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2],
  ];
  static const _bishopDirs = [
    [1, 1], [1, -1], [-1, 1], [-1, -1],
  ];
  static const _rookDirs = [
    [1, 0], [-1, 0], [0, 1], [0, -1],
  ];
  static const _queenDirs = [
    [1, 1], [1, -1], [-1, 1], [-1, -1], [1, 0], [-1, 0], [0, 1], [0, -1],
  ];

  List<ChessMove> legalMoves() {
    if (isOver) return const [];
    return _legalMovesFor(turn);
  }

  /// Число псевдоходов стороны — дешёвая оценка подвижности для бота.
  int pseudoMobility(int seat) => _pseudoMoves(seat).length;

  List<ChessMove> _legalMovesFor(int seat) {
    final out = <ChessMove>[];
    for (final mv in _pseudoMoves(seat)) {
      final child = clone();
      child._applyRaw(seat, mv);
      if (!child._kingInCheck(seat)) out.add(mv);
    }
    return out;
  }

  List<ChessMove> _pseudoMoves(int seat) {
    final out = <ChessMove>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final p = at(r, c);
        if (colorOf(p) != seat) continue;
        switch (kind(p)) {
          case 1:
            out.addAll(_pawnMoves(r, c, seat));
          case 2:
            out.addAll(_stepMoves(r, c, seat, _knightDirs, false));
          case 3:
            out.addAll(_stepMoves(r, c, seat, _bishopDirs, true));
          case 4:
            out.addAll(_stepMoves(r, c, seat, _rookDirs, true));
          case 5:
            out.addAll(_stepMoves(r, c, seat, _queenDirs, true));
          case 6:
            out.addAll(_stepMoves(r, c, seat, _queenDirs, false));
            out.addAll(_castleMoves(r, c, seat));
        }
      }
    }
    return out;
  }

  List<ChessMove> _stepMoves(
      int r, int c, int seat, List<List<int>> dirs, bool sliding) {
    final out = <ChessMove>[];
    final from = ChessSquare(r, c);
    for (final d in dirs) {
      var nr = r + d[0], nc = c + d[1];
      while (inBounds(nr, nc)) {
        final target = at(nr, nc);
        if (target == empty) {
          out.add(ChessMove(from: from, to: ChessSquare(nr, nc)));
        } else {
          if (colorOf(target) != seat) {
            out.add(ChessMove(from: from, to: ChessSquare(nr, nc)));
          }
          break;
        }
        if (!sliding) break;
        nr += d[0];
        nc += d[1];
      }
    }
    return out;
  }

  List<ChessMove> _pawnMoves(int r, int c, int seat) {
    final out = <ChessMove>[];
    final from = ChessSquare(r, c);
    final fwd = seat == 1 ? -1 : 1;
    final startRow = seat == 1 ? size - 2 : 1;
    final promoRow = seat == 1 ? 0 : size - 1;
    final nr = r + fwd;
    if (inBounds(nr, c) && at(nr, c) == empty) {
      out.addAll(_pawnPushOrPromo(from, ChessSquare(nr, c), nr == promoRow));
      if (r == startRow && at(r + 2 * fwd, c) == empty) {
        out.add(ChessMove(from: from, to: ChessSquare(r + 2 * fwd, c)));
      }
    }
    for (final dc in const [-1, 1]) {
      final tr = r + fwd, tc = c + dc;
      if (!inBounds(tr, tc)) continue;
      final target = at(tr, tc);
      if (target != empty && colorOf(target) != seat && colorOf(target) >= 0) {
        out.addAll(_pawnPushOrPromo(from, ChessSquare(tr, tc), tr == promoRow));
        continue;
      }
      if (enPassant >= 0 && idx(tr, tc) == enPassant) {
        out.add(ChessMove(from: from, to: ChessSquare(tr, tc)));
      }
    }
    return out;
  }

  List<ChessMove> _pawnPushOrPromo(ChessSquare from, ChessSquare to, bool promo) {
    if (!promo) return [ChessMove(from: from, to: to)];
    return [
      for (final p in const [5, 4, 3, 2])
        ChessMove(from: from, to: to, promo: p),
    ];
  }

  List<ChessMove> _castleMoves(int r, int c, int seat) {
    final out = <ChessMove>[];
    if (_kingInCheck(seat)) return out;
    final home = seat == 1 ? size - 1 : 0;
    final kingSide = seat == 1 ? _cBK : _cWK;
    final queenSide = seat == 1 ? _cBQ : _cWQ;
    if (r != home || c != 4) return out;
    final from = ChessSquare(r, c);
    if (castle[kingSide] &&
        at(home, 5) == empty &&
        at(home, 6) == empty &&
        kind(at(home, 7)) == 4 &&
        colorOf(at(home, 7)) == seat) {
      if (!_squareAttacked(home, 5, 1 - seat) &&
          !_squareAttacked(home, 6, 1 - seat)) {
        out.add(ChessMove(from: from, to: ChessSquare(home, 6)));
      }
    }
    if (castle[queenSide] &&
        at(home, 3) == empty &&
        at(home, 2) == empty &&
        at(home, 1) == empty &&
        kind(at(home, 0)) == 4 &&
        colorOf(at(home, 0)) == seat) {
      if (!_squareAttacked(home, 3, 1 - seat) &&
          !_squareAttacked(home, 2, 1 - seat)) {
        out.add(ChessMove(from: from, to: ChessSquare(home, 2)));
      }
    }
    return out;
  }

  bool _kingInCheck(int seat) {
    final k = _findKing(seat);
    if (k == null) return false;
    return _squareAttacked(k.r, k.c, 1 - seat);
  }

  ChessSquare? _findKing(int seat) {
    final target = seat == 1 ? blackKing : whiteKing;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (at(r, c) == target) return ChessSquare(r, c);
      }
    }
    return null;
  }

  bool _squareAttacked(int r, int c, int byColor) {
    final pawnDir = byColor == 1 ? -1 : 1;
    final pawn = byColor == 1 ? blackPawn : whitePawn;
    for (final dc in const [-1, 1]) {
      if (at(r - pawnDir, c + dc) == pawn) return true;
    }
    final knight = whiteKnight + byColor * 6;
    for (final d in _knightDirs) {
      if (at(r + d[0], c + d[1]) == knight) return true;
    }
    final king = whiteKing + byColor * 6;
    for (final d in _queenDirs) {
      if (at(r + d[0], c + d[1]) == king) return true;
    }
    for (final d in _bishopDirs) {
      var nr = r + d[0], nc = c + d[1];
      while (inBounds(nr, nc)) {
        final p = at(nr, nc);
        if (p != empty) {
          if (colorOf(p) == byColor && (kind(p) == 3 || kind(p) == 5)) {
            return true;
          }
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
    for (final d in _rookDirs) {
      var nr = r + d[0], nc = c + d[1];
      while (inBounds(nr, nc)) {
        final p = at(nr, nc);
        if (p != empty) {
          if (colorOf(p) == byColor && (kind(p) == 4 || kind(p) == 5)) {
            return true;
          }
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
    return false;
  }

  void _applyRaw(int seat, ChessMove mv) {
    final piece = at(mv.from.r, mv.from.c);
    final captured = at(mv.to.r, mv.to.c);
    final isPawn = kind(piece) == 1;
    var isCapture = captured != empty;
    var newEP = -1;

    set(mv.from.r, mv.from.c, empty);

    if (isPawn && mv.to.c != mv.from.c && captured == empty) {
      set(mv.from.r, mv.to.c, empty);
      isCapture = true;
    }

    var placed = piece;
    if (isPawn && mv.promo != 0) placed = mv.promo + seat * 6;
    set(mv.to.r, mv.to.c, placed);

    if (kind(piece) == 6 && (mv.to.c - mv.from.c).abs() == 2) {
      final home = mv.from.r;
      if (mv.to.c == 6) {
        set(home, 5, at(home, 7));
        set(home, 7, empty);
      } else {
        set(home, 3, at(home, 0));
        set(home, 0, empty);
      }
    }

    if (isPawn && (mv.to.r - mv.from.r).abs() == 2) {
      newEP = idx((mv.from.r + mv.to.r) ~/ 2, mv.from.c);
    }
    enPassant = newEP;

    _updateCastleRights(piece, mv);

    if (isPawn || isCapture) {
      halfMove = 0;
    } else {
      halfMove++;
    }
  }

  void _updateCastleRights(int piece, ChessMove mv) {
    switch (piece) {
      case whiteKing:
        castle[_cWK] = false;
        castle[_cWQ] = false;
      case blackKing:
        castle[_cBK] = false;
        castle[_cBQ] = false;
      case whiteRook:
        if (mv.from.r == 0 && mv.from.c == 0) castle[_cWQ] = false;
        if (mv.from.r == 0 && mv.from.c == 7) castle[_cWK] = false;
      case blackRook:
        if (mv.from.r == 7 && mv.from.c == 0) castle[_cBQ] = false;
        if (mv.from.r == 7 && mv.from.c == 7) castle[_cBK] = false;
    }
    void loseRook(int r, int c, int right) {
      if (mv.to.r == r && mv.to.c == c) castle[right] = false;
    }

    loseRook(0, 0, _cWQ);
    loseRook(0, 7, _cWK);
    loseRook(7, 0, _cBQ);
    loseRook(7, 7, _cBK);
  }

  void apply(int seat, ChessMove mv) {
    if (isOver) throw StateError('game is over');
    if (seat != turn) throw StateError('not your turn');
    ChessMove? chosen;
    for (final cand in legalMoves()) {
      if (cand.from == mv.from && cand.to == mv.to) {
        if (_isPromotion(cand)) {
          var promo = mv.promo;
          if (promo == 0) promo = 5;
          if (cand.promo != promo) continue;
        }
        chosen = cand;
        break;
      }
    }
    if (chosen == null) throw StateError('illegal move');
    _applyRaw(seat, chosen);
    lastFromR = chosen.from.r;
    lastFromC = chosen.from.c;
    lastToR = chosen.to.r;
    lastToC = chosen.to.c;
    seq++;
    turn = 1 - turn;
    resolveEnd();
  }

  bool _isPromotion(ChessMove mv) {
    if (kind(at(mv.from.r, mv.from.c)) != 1) return false;
    return mv.to.r == 0 || mv.to.r == size - 1;
  }

  /// Нужно ли показать выбор фигуры для превращения перед отправкой хода.
  bool isPromotionMove(ChessSquare from, ChessSquare to) {
    if (kind(at(from.r, from.c)) != 1) return false;
    return to.r == 0 || to.r == size - 1;
  }

  void resolveEnd() {
    if (isOver) return;
    if (halfMove >= fiftyMovePlies) {
      winner = winnerDraw;
      drawReason = drawReasonFiftyMove;
      return;
    }
    if (_insufficientMaterial()) {
      winner = winnerDraw;
      drawReason = drawReasonInsufficient;
      return;
    }
    final key = _positionKey();
    posCounts[key] = (posCounts[key] ?? 0) + 1;
    if (posCounts[key]! >= 3) {
      winner = winnerDraw;
      drawReason = drawReasonRepetition;
      return;
    }
    if (legalMoves().isNotEmpty) return;
    if (_kingInCheck(turn)) {
      winner = 1 - turn;
      return;
    }
    winner = winnerDraw;
    drawReason = drawReasonStalemate;
  }

  bool _insufficientMaterial() {
    var knights = 0, bishops = 0;
    for (final p in board) {
      switch (kind(p)) {
        case 1:
        case 4:
        case 5:
          return false;
        case 2:
          knights++;
        case 3:
          bishops++;
      }
    }
    return knights + bishops <= 1;
  }

  String _positionKey() {
    final buf = StringBuffer();
    for (final p in board) {
      buf.writeCharCode(97 + p);
    }
    buf.write(turn);
    for (final b in castle) {
      buf.write(b ? '1' : '0');
    }
    buf.write('|$enPassant');
    return buf.toString();
  }

  /// Под шахом ли сторона, чей ход (для подсветки короля).
  bool get inCheck {
    if (isOver) return false;
    return _kingInCheck(turn);
  }

  void forfeit(int seat) {
    if (isOver) return;
    winner = 1 - seat;
    seq++;
  }

  void agreeDraw() {
    if (isOver) return;
    winner = winnerDraw;
    drawReason = drawReasonAgreed;
    seq++;
  }
}
