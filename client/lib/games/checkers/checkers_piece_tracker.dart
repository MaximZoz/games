/// Стабильный номер шашки между кадрами — чтобы она ехала, а не телепортировалась.
class CheckersPieceSpot {
  const CheckersPieceSpot({
    required this.id,
    required this.r,
    required this.c,
    required this.piece,
  });

  final int id;
  final int r;
  final int c;
  final int piece;
}

/// Сопоставляет шашки предыдущего кадра с новой доской.
class CheckersPieceTracker {
  final Map<int, (int r, int c, int piece)> _prev = {};
  int _nextId = 1;

  List<CheckersPieceSpot> spotsFor(
    List<int> board, {
    int lastFromR = -1,
    int lastFromC = -1,
    int lastToR = -1,
    int lastToC = -1,
  }) {
    final occupied = <(int r, int c, int piece)>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final i = r * 8 + c;
        if (i >= board.length) continue;
        final piece = board[i];
        if (piece > 0) occupied.add((r, c, piece));
      }
    }

    final byPos = <(int, int), int>{};
    _prev.forEach((id, place) {
      byPos[(place.$1, place.$2)] = id;
    });

    final assigned = <int, CheckersPieceSpot>{};
    final used = <int>{};

    bool sameSide(int a, int b) {
      final aw = a == 1 || a == 3;
      final bw = b == 1 || b == 3;
      return aw == bw;
    }

    void put(int id, int r, int c, int piece) {
      used.add(id);
      assigned[id] = CheckersPieceSpot(id: id, r: r, c: c, piece: piece);
    }

    if (lastFromR >= 0 && lastToR >= 0) {
      final moverId = byPos[(lastFromR, lastFromC)];
      final dest = occupied.where((o) => o.$1 == lastToR && o.$2 == lastToC);
      if (moverId != null && dest.isNotEmpty) {
        put(moverId, lastToR, lastToC, dest.first.$3);
      }
    }

    for (final (r, c, piece) in occupied) {
      if (assigned.values.any((s) => s.r == r && s.c == c)) continue;
      final stayId = byPos[(r, c)];
      if (stayId != null &&
          !used.contains(stayId) &&
          sameSide(_prev[stayId]!.$3, piece)) {
        put(stayId, r, c, piece);
      }
    }

    for (final (r, c, piece) in occupied) {
      if (assigned.values.any((s) => s.r == r && s.c == c)) continue;
      put(_nextId++, r, c, piece);
    }

    _prev
      ..clear()
      ..addEntries(
        assigned.values.map((s) => MapEntry(s.id, (s.r, s.c, s.piece))),
      );
    return assigned.values.toList();
  }
}
