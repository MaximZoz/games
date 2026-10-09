/// Русские шашки / поддавки — те же правила, что сервер.
class CheckersSquare {
  const CheckersSquare(this.r, this.c);
  final int r;
  final int c;

  @override
  bool operator ==(Object other) =>
      other is CheckersSquare && other.r == r && other.c == c;

  @override
  int get hashCode => Object.hash(r, c);

  Map<String, dynamic> toJson() => {'r': r, 'c': c};

  factory CheckersSquare.fromJson(Map<String, dynamic> json) => CheckersSquare(
        (json['r'] as num?)?.toInt() ?? 0,
        (json['c'] as num?)?.toInt() ?? 0,
      );
}

class CheckersMove {
  const CheckersMove({
    required this.from,
    required this.to,
    this.jumped = const [],
  });

  final CheckersSquare from;
  final CheckersSquare to;
  final List<CheckersSquare> jumped;

  Map<String, dynamic> toJson() => {
        'from': from.toJson(),
        'to': to.toJson(),
        if (jumped.isNotEmpty) 'jumped': jumped.map((e) => e.toJson()).toList(),
      };

  factory CheckersMove.fromJson(Map<String, dynamic> json) {
    final jumpedRaw = json['jumped'];
    return CheckersMove(
      from: CheckersSquare.fromJson(
        (json['from'] as Map).cast<String, dynamic>(),
      ),
      to: CheckersSquare.fromJson(
        (json['to'] as Map).cast<String, dynamic>(),
      ),
      jumped: jumpedRaw is List
          ? jumpedRaw
              .whereType<Map>()
              .map((e) => CheckersSquare.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

class CheckersEngine {
  CheckersEngine({
    required this.mode,
    required List<int> board,
    this.turn = 0,
    this.winner = -1,
    this.seq = 0,
    this.mustContinue = false,
    this.contR = -1,
    this.contC = -1,
    this.lastFromR = -1,
    this.lastFromC = -1,
    this.lastToR = -1,
    this.lastToC = -1,
    this.noProgress = 0,
    Map<String, int>? posCounts,
    this.drawReason = '',
  })  : board = List<int>.from(board),
        posCounts = Map<String, int>.from(posCounts ?? const {});

  static const modeRussian = 'russian';
  static const modeEnglish = 'english';
  static const modeGiveaway = 'giveaway';
  static const modeCorners = 'corners';
  static const allModes = [
    modeRussian,
    modeEnglish,
    modeGiveaway,
    modeCorners,
  ];
  static const empty = 0;
  static const whiteMan = 1;
  static const blackMan = 2;
  static const whiteKing = 3;
  static const blackKing = 4;
  static const winnerNone = -1;
  static const winnerDraw = -2;
  static const size = 8;

  /// За столько своих ходов фишки должны покинуть стартовый угол.
  static const cornersLeaveHomeMoves = 25;

  /// 15 ходов каждой стороны только дамками без взятий (ФШР).
  static const russianNoProgressPlies = 30;

  /// 40 ходов без взятия и хода простой (WCDF / английские).
  static const englishNoProgressPlies = 80;

  /// 25 ходов каждой стороны без прогресса в целевой угол.
  static const cornersNoProgressPlies = 50;

  static const drawReasonRepetition = 'repetition';
  static const drawReasonNoProgress = 'no_progress';
  static const drawReasonInsufficient = 'insufficient';
  static const drawReasonAgreed = 'agreed';

  String mode;
  List<int> board;
  int turn;
  int winner;
  int seq;
  bool mustContinue;
  int contR;
  int contC;
  int lastFromR;
  int lastFromC;
  int lastToR;
  int lastToC;
  int noProgress;
  Map<String, int> posCounts;
  String drawReason;

  static String normalizeMode(String? raw) {
    switch (raw) {
      case modeEnglish:
      case modeGiveaway:
      case modeCorners:
        return raw!;
      default:
        return modeRussian;
    }
  }

  static String nextMode(String? raw) {
    final cur = normalizeMode(raw);
    return allModes[(allModes.indexOf(cur) + 1) % allModes.length];
  }

  bool get isEnglish => mode == modeEnglish;
  bool get isCorners => mode == modeCorners;

  factory CheckersEngine.newGame(String mode) {
    final g = CheckersEngine(
      mode: normalizeMode(mode),
      board: List<int>.filled(size * size, empty),
    );
    if (g.mode == modeCorners) {
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          g.set(r, c, whiteMan);
          g.set(size - 3 + r, size - 3 + c, blackMan);
        }
      }
      return g;
    }
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if ((r + c) % 2 == 0) continue;
        if (r <= 2) {
          g.set(r, c, whiteMan);
        } else if (r >= 5) {
          g.set(r, c, blackMan);
        }
      }
    }
    return g;
  }

  bool get isOver => winner != winnerNone;

  CheckersEngine clone() => CheckersEngine(
        mode: mode,
        board: List<int>.from(board),
        turn: turn,
        winner: winner,
        seq: seq,
        mustContinue: mustContinue,
        contR: contR,
        contC: contC,
        lastFromR: lastFromR,
        lastFromC: lastFromC,
        lastToR: lastToR,
        lastToC: lastToC,
        noProgress: noProgress,
        posCounts: posCounts,
        drawReason: drawReason,
      );

  int idx(int r, int c) => r * size + c;

  int at(int r, int c) {
    if (r < 0 || c < 0 || r >= size || c >= size) return -1;
    return board[idx(r, c)];
  }

  void set(int r, int c, int v) => board[idx(r, c)] = v;

  static int owner(int piece) {
    if (piece == whiteMan || piece == whiteKing) return 0;
    if (piece == blackMan || piece == blackKing) return 1;
    return -1;
  }

  static bool isKing(int piece) => piece == whiteKing || piece == blackKing;

  static bool dark(int r, int c) => (r + c) % 2 == 1;

  List<CheckersMove> legalMoves() {
    if (isOver) return const [];
    if (isCorners) return cornersMoves(turn);
    if (mustContinue) return capturesFrom(contR, contC);
    final caps = allCaptures(turn);
    if (caps.isNotEmpty) return caps;
    return quietMoves(turn);
  }

  List<CheckersMove> allCaptures(int seat) {
    final out = <CheckersMove>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (owner(at(r, c)) != seat) continue;
        out.addAll(capturesFrom(r, c));
      }
    }
    return out;
  }

  List<CheckersMove> capturesFrom(int r, int c) {
    final piece = at(r, c);
    if (owner(piece) < 0) return const [];
    return isKing(piece) ? kingCaptures(r, c) : manCaptures(r, c);
  }

  List<CheckersMove> manCaptures(int r, int c) {
    final piece = at(r, c);
    final seat = owner(piece);
    final out = <CheckersMove>[];
    final dirs = isEnglish
        ? [
            [seat == 0 ? 1 : -1, 1],
            [seat == 0 ? 1 : -1, -1],
          ]
        : const [
            [1, 1],
            [1, -1],
            [-1, 1],
            [-1, -1],
          ];
    for (final d in dirs) {
      final jr = r + d[0], jc = c + d[1];
      final tr = r + 2 * d[0], tc = c + 2 * d[1];
      final mid = at(jr, jc);
      if (owner(mid) < 0 || owner(mid) == seat) continue;
      if (at(tr, tc) != empty || !dark(tr, tc)) continue;
      out.add(CheckersMove(
        from: CheckersSquare(r, c),
        to: CheckersSquare(tr, tc),
        jumped: [CheckersSquare(jr, jc)],
      ));
    }
    return out;
  }

  List<CheckersMove> kingCaptures(int r, int c) {
    final piece = at(r, c);
    final seat = owner(piece);
    final out = <CheckersMove>[];
    for (final d in const [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ]) {
      if (isEnglish) {
        final jr = r + d[0], jc = c + d[1];
        final tr = r + 2 * d[0], tc = c + 2 * d[1];
        final mid = at(jr, jc);
        if (owner(mid) < 0 || owner(mid) == seat) continue;
        if (at(tr, tc) != empty || !dark(tr, tc)) continue;
        out.add(CheckersMove(
          from: CheckersSquare(r, c),
          to: CheckersSquare(tr, tc),
          jumped: [CheckersSquare(jr, jc)],
        ));
        continue;
      }
      var jr = r + d[0], jc = c + d[1];
      while (at(jr, jc) == empty) {
        jr += d[0];
        jc += d[1];
      }
      final mid = at(jr, jc);
      if (owner(mid) < 0 || owner(mid) == seat) continue;
      var lr = jr + d[0], lc = jc + d[1];
      while (at(lr, lc) == empty && dark(lr, lc)) {
        out.add(CheckersMove(
          from: CheckersSquare(r, c),
          to: CheckersSquare(lr, lc),
          jumped: [CheckersSquare(jr, jc)],
        ));
        lr += d[0];
        lc += d[1];
      }
    }
    return out;
  }

  List<CheckersMove> quietMoves(int seat) {
    final out = <CheckersMove>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final piece = at(r, c);
        if (owner(piece) != seat) continue;
        if (isKing(piece)) {
          for (final d in const [
            [1, 1],
            [1, -1],
            [-1, 1],
            [-1, -1],
          ]) {
            var nr = r + d[0], nc = c + d[1];
            if (isEnglish) {
              if (at(nr, nc) == empty && dark(nr, nc)) {
                out.add(CheckersMove(
                  from: CheckersSquare(r, c),
                  to: CheckersSquare(nr, nc),
                ));
              }
              continue;
            }
            while (at(nr, nc) == empty && dark(nr, nc)) {
              out.add(CheckersMove(
                from: CheckersSquare(r, c),
                to: CheckersSquare(nr, nc),
              ));
              nr += d[0];
              nc += d[1];
            }
          }
          continue;
        }
        final fwd = seat == 0 ? 1 : -1;
        for (final dc in const [-1, 1]) {
          final nr = r + fwd, nc = c + dc;
          if (at(nr, nc) == empty && dark(nr, nc)) {
            out.add(CheckersMove(
              from: CheckersSquare(r, c),
              to: CheckersSquare(nr, nc),
            ));
          }
        }
      }
    }
    return out;
  }

  static const _ortho = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];

  List<CheckersMove> cornersMoves(int seat) {
    final out = <CheckersMove>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (owner(at(r, c)) != seat) continue;
        out.addAll(cornersMovesFrom(r, c));
      }
    }
    return out;
  }

  static bool cornersOwnHome(int seat, int r, int c) {
    if (seat == 0) return r >= 0 && r <= 2 && c >= 0 && c <= 2;
    if (seat == 1) return r >= 5 && r <= 7 && c >= 5 && c <= 7;
    return false;
  }

  /// Сколько ходов уже сделал [seat] после [seq] полуходов.
  static int seatMoveCount(int seq, int seat) {
    if (seat == 0) return (seq + 1) ~/ 2;
    return seq ~/ 2;
  }

  bool cornersHasPiecesInOwnHome(int seat) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (owner(at(r, c)) == seat && cornersOwnHome(seat, r, c)) {
          return true;
        }
      }
    }
    return false;
  }

  List<CheckersMove> cornersMovesFrom(int r, int c) {
    final out = <CheckersMove>[];
    final from = CheckersSquare(r, c);
    final seat = owner(at(r, c));
    final leftHome = seat >= 0 && !cornersOwnHome(seat, r, c);
    for (final d in _ortho) {
      final nr = r + d[0], nc = c + d[1];
      if (at(nr, nc) == empty) {
        if (leftHome && cornersOwnHome(seat, nr, nc)) continue;
        out.add(CheckersMove(from: from, to: CheckersSquare(nr, nc)));
      }
    }
    final seen = <CheckersSquare>{from};
    final queue = <CheckersSquare>[from];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final d in _ortho) {
        final mr = cur.r + d[0], mc = cur.c + d[1];
        final lr = cur.r + 2 * d[0], lc = cur.c + 2 * d[1];
        if (at(mr, mc) <= 0) continue;
        if (at(lr, lc) != empty) continue;
        final land = CheckersSquare(lr, lc);
        if (seen.contains(land)) continue;
        seen.add(land);
        if (leftHome && cornersOwnHome(seat, lr, lc)) continue;
        out.add(CheckersMove(from: from, to: land));
        queue.add(land);
      }
    }
    return out;
  }

  bool cornersFilled(int seat) {
    final tr0 = seat == 1 ? 0 : 5;
    final tc0 = seat == 1 ? 0 : 5;
    var own = 0;
    var inTarget = 0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (owner(at(r, c)) != seat) continue;
        own++;
        if (r >= tr0 && r < tr0 + 3 && c >= tc0 && c < tc0 + 3) {
          inTarget++;
        }
      }
    }
    return own > 0 && own == inTarget;
  }

  void apply(int seat, CheckersMove mv) {
    if (isOver) throw StateError('game is over');
    if (seat != turn) throw StateError('not your turn');
    CheckersMove? chosen;
    for (final cand in legalMoves()) {
      if (cand.from == mv.from &&
          cand.to == mv.to &&
          (mv.jumped.isEmpty || _sameJumped(cand.jumped, mv.jumped))) {
        chosen = cand;
        break;
      }
    }
    if (chosen == null) throw StateError('illegal move');
    var piece = at(chosen.from.r, chosen.from.c);
    final captured = !isCorners && chosen.jumped.isNotEmpty;
    final manMoved = !isKing(piece);
    final cornersBefore = isCorners ? cornersTargetCount(seat) : 0;
    set(chosen.from.r, chosen.from.c, empty);
    var promoted = false;
    if (!isCorners) {
      for (final j in chosen.jumped) {
        set(j.r, j.c, empty);
      }
    }
    if (!isCorners && !isKing(piece)) {
      if ((seat == 0 && chosen.to.r == size - 1) ||
          (seat == 1 && chosen.to.r == 0)) {
        piece = seat == 0 ? whiteKing : blackKing;
        promoted = true;
      }
    }
    set(chosen.to.r, chosen.to.c, piece);
    lastFromR = chosen.from.r;
    lastFromC = chosen.from.c;
    lastToR = chosen.to.r;
    lastToC = chosen.to.c;
    seq++;
    if (isCorners) {
      if (cornersFilled(seat)) {
        winner = seat;
        mustContinue = false;
        contR = -1;
        contC = -1;
        return;
      }
      if (seatMoveCount(seq, seat) >= cornersLeaveHomeMoves &&
          cornersHasPiecesInOwnHome(seat)) {
        winner = 1 - seat;
        mustContinue = false;
        contR = -1;
        contC = -1;
        return;
      }
    } else if (captured && !(isEnglish && promoted)) {
      final more = capturesFrom(chosen.to.r, chosen.to.c);
      if (more.isNotEmpty) {
        mustContinue = true;
        contR = chosen.to.r;
        contC = chosen.to.c;
        return;
      }
    }
    mustContinue = false;
    contR = -1;
    contC = -1;
    turn = 1 - turn;
    noteProgress(
      !isCorners && (captured || manMoved || promoted),
      isCorners && cornersTargetCount(seat) > cornersBefore,
    );
    resolveEnd();
  }

  int get noProgressLimit {
    switch (mode) {
      case modeEnglish:
        return englishNoProgressPlies;
      case modeCorners:
        return cornersNoProgressPlies;
      default:
        return russianNoProgressPlies;
    }
  }

  int cornersTargetCount(int seat) {
    final tr0 = seat == 1 ? 0 : 5;
    final tc0 = seat == 1 ? 0 : 5;
    var n = 0;
    for (var r = tr0; r < tr0 + 3; r++) {
      for (var c = tc0; c < tc0 + 3; c++) {
        if (owner(at(r, c)) == seat) n++;
      }
    }
    return n;
  }

  bool get loneKings {
    var whiteMen = 0, blackMen = 0, whiteKings = 0, blackKings = 0;
    for (final p in board) {
      switch (p) {
        case whiteMan:
          whiteMen++;
        case blackMan:
          blackMen++;
        case whiteKing:
          whiteKings++;
        case blackKing:
          blackKings++;
      }
    }
    return whiteMen == 0 && blackMen == 0 && whiteKings == 1 && blackKings == 1;
  }

  String positionKey() {
    final buf = StringBuffer(board.join());
    buf
      ..write('|')
      ..write(turn)
      ..write('|')
      ..write(mustContinue ? 1 : 0)
      ..write('|')
      ..write(contR)
      ..write('|')
      ..write(contC);
    return buf.toString();
  }

  void noteProgress(bool didProgress, bool cornersProgress) {
    if (isOver) return;
    if (didProgress || cornersProgress) {
      noProgress = 0;
    } else {
      noProgress++;
    }
    checkAutomaticDraw();
  }

  void checkAutomaticDraw() {
    if (isOver) return;
    if (isEnglish && loneKings) {
      winner = winnerDraw;
      drawReason = drawReasonInsufficient;
      return;
    }
    if (noProgress >= noProgressLimit) {
      winner = winnerDraw;
      drawReason = drawReasonNoProgress;
      return;
    }
    final key = positionKey();
    posCounts[key] = (posCounts[key] ?? 0) + 1;
    if (posCounts[key]! >= 3) {
      winner = winnerDraw;
      drawReason = drawReasonRepetition;
    }
  }

  void resolveEnd() {
    if (isOver) return;
    if (isCorners) {
      if (cornersFilled(0)) {
        winner = 0;
        return;
      }
      if (cornersFilled(1)) {
        winner = 1;
        return;
      }
      final justMoved = 1 - turn;
      if (seatMoveCount(seq, justMoved) >= cornersLeaveHomeMoves &&
          cornersHasPiecesInOwnHome(justMoved)) {
        winner = 1 - justMoved;
        return;
      }
    }
    if (legalMoves().isNotEmpty) return;
    final loser = turn;
    winner = mode == modeGiveaway ? loser : 1 - loser;
  }

  void forfeit(int seat) {
    if (isOver) return;
    winner = mode == modeGiveaway ? seat : 1 - seat;
    seq++;
  }

  void agreeDraw() {
    if (isOver) return;
    winner = winnerDraw;
    drawReason = drawReasonAgreed;
    seq++;
  }

  static bool _sameJumped(List<CheckersSquare> a, List<CheckersSquare> b) {
    if (a.length != b.length) return a.isEmpty || b.isEmpty;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
