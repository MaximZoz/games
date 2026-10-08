import 'dart:math';

import 'package:multigames_client/games/checkers/checkers_engine.dart';

const int _botWinScore = 100000;
const int _botSearchDepth = 6;
const int _botCornersDepth = 5;

/// Лучший ход: поиск с оценкой всей позиции, не одной шашки.
CheckersMove? checkersPickMove(CheckersEngine g, [Random? rng]) {
  final legal = g.legalMoves();
  if (legal.isEmpty) return null;
  if (legal.length == 1) return legal.first;
  rng ??= Random(1);
  final rootSeat = g.turn;
  var depth = g.isCorners ? _botCornersDepth : _botSearchDepth;
  if (legal.length > 28) depth = 4;
  if (legal.length > 40) depth = 3;
  var best = legal.first;
  var bestScore = -1 << 30;
  var ties = 0;
  var alpha = -1 << 30;
  const beta = 1 << 30;
  for (final mv in _orderMoves(g, legal)) {
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final score = _alphabeta(child, depth - 1, alpha, beta, rootSeat);
    if (score > bestScore) {
      bestScore = score;
      best = mv;
      ties = 1;
      if (score > alpha) alpha = score;
    } else if (score == bestScore) {
      ties++;
      if (rng.nextInt(ties) == 0) best = mv;
    }
  }
  return best;
}

int _alphabeta(
  CheckersEngine g,
  int depth,
  int alpha,
  int beta,
  int rootSeat,
) {
  if (g.isOver) {
    if (g.winner == rootSeat) return _botWinScore + depth;
    if (g.winner == CheckersEngine.winnerDraw) return 0;
    if (g.winner == CheckersEngine.winnerNone) {
      return checkersEvaluate(g, rootSeat);
    }
    return -_botWinScore - depth;
  }
  if (depth <= 0) {
    if (depth > -2) {
      final captures = _captureMoves(g);
      if (captures.isNotEmpty) {
        return _alphabetaCaptures(
          g,
          depth - 1,
          alpha,
          beta,
          rootSeat,
          captures,
        );
      }
    }
    return checkersEvaluate(g, rootSeat);
  }
  final legal = _orderMoves(g, g.legalMoves());
  if (legal.isEmpty) return checkersEvaluate(g, rootSeat);
  final maximizing = g.turn == rootSeat;
  if (maximizing) {
    var best = -1 << 30;
    for (final mv in legal) {
      final child = g.clone();
      try {
        child.apply(g.turn, mv);
      } catch (_) {
        continue;
      }
      final s = _alphabeta(child, depth - 1, alpha, beta, rootSeat);
      if (s > best) best = s;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
  var best = 1 << 30;
  for (final mv in legal) {
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final s = _alphabeta(child, depth - 1, alpha, beta, rootSeat);
    if (s < best) best = s;
    if (best < beta) beta = best;
    if (alpha >= beta) break;
  }
  return best;
}

List<CheckersMove> _orderMoves(CheckersEngine g, List<CheckersMove> legal) {
  final out = List<CheckersMove>.from(legal);
  if (g.isCorners) {
    final tr = g.turn == 0 ? 5 : 0;
    final tc = g.turn == 0 ? 5 : 0;
    out.sort((a, b) => _moveProgress(b, tr, tc).compareTo(_moveProgress(a, tr, tc)));
    return out;
  }
  out.sort((a, b) => b.jumped.length.compareTo(a.jumped.length));
  return out;
}

int _moveProgress(CheckersMove mv, int tr, int tc) {
  final from = checkersMinDistToBox(mv.from.r, mv.from.c, tr, tc);
  final to = checkersMinDistToBox(mv.to.r, mv.to.c, tr, tc);
  return (from - to) + from;
}

int checkersEvaluate(CheckersEngine g, int seat) {
  if (g.isCorners) return _evalCorners(g, seat);
  final score = _evalDraughts(g, seat);
  return g.mode == CheckersEngine.modeGiveaway ? -score : score;
}

int _evalDraughts(CheckersEngine g, int seat) {
  var score = 0;
  for (var r = 0; r < CheckersEngine.size; r++) {
    for (var c = 0; c < CheckersEngine.size; c++) {
      final p = g.at(r, c);
      final own = CheckersEngine.owner(p);
      if (own < 0) continue;
      var val = 100;
      if (CheckersEngine.isKing(p)) {
        val = 280;
        val += 6 - (r - 3).abs() - (c - 3).abs();
      } else if (own == 0) {
        val += r * 8;
        if (r >= 5) val += 12;
      } else {
        val += (CheckersEngine.size - 1 - r) * 8;
        if (r <= 2) val += 12;
      }
      if (CheckersEngine.dark(r, c) && r >= 2 && r <= 5 && c >= 2 && c <= 5) {
        val += 8;
      }
      if (!CheckersEngine.isKing(p)) {
        if (own == 0 && r == 0) val += 18;
        if (own == 1 && r == CheckersEngine.size - 1) val += 18;
      }
      score += own == seat ? val : -val;
    }
  }
  score += _maxCapture(g, seat) * 28 - _maxCapture(g, 1 - seat) * 55;
  return score;
}

List<CheckersMove> _captureMoves(CheckersEngine g) =>
    g.legalMoves().where((mv) => mv.jumped.isNotEmpty).toList();

int _alphabetaCaptures(
  CheckersEngine g,
  int depth,
  int alpha,
  int beta,
  int rootSeat,
  List<CheckersMove> captures,
) {
  final maximizing = g.turn == rootSeat;
  if (maximizing) {
    var best = -1 << 30;
    for (final mv in _orderMoves(g, captures)) {
      final child = g.clone();
      try {
        child.apply(g.turn, mv);
      } catch (_) {
        continue;
      }
      final s = _alphabeta(child, depth, alpha, beta, rootSeat);
      if (s > best) best = s;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
  var best = 1 << 30;
  for (final mv in _orderMoves(g, captures)) {
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final s = _alphabeta(child, depth, alpha, beta, rootSeat);
    if (s < best) best = s;
    if (best < beta) beta = best;
    if (alpha >= beta) break;
  }
  return best;
}

int _maxCapture(CheckersEngine g, int attacker) {
  if (g.isOver) return 0;
  final child = g.clone();
  child.turn = attacker;
  var best = 0;
  for (final mv in child.legalMoves()) {
    if (mv.jumped.length > best) best = mv.jumped.length;
  }
  return best;
}

int _evalCorners(CheckersEngine g, int seat) {
  if (g.cornersFilled(seat)) return _botWinScore;
  if (g.cornersFilled(1 - seat)) return -_botWinScore;
  var score = 0;
  for (var s = 0; s < 2; s++) {
    final sign = s == seat ? 1 : -1;
    final tr = s == 0 ? 5 : 0;
    final tc = s == 0 ? 5 : 0;
    final sr = s == 0 ? 0 : 5;
    final sc = s == 0 ? 0 : 5;
    var sum = 0;
    var sumSq = 0;
    var maxd = 0;
    var inTarget = 0;
    var inStart = 0;
    var far = 0;
    for (var r = 0; r < CheckersEngine.size; r++) {
      for (var c = 0; c < CheckersEngine.size; c++) {
        if (CheckersEngine.owner(g.at(r, c)) != s) continue;
        final d = checkersMinDistToBox(r, c, tr, tc);
        sum += d;
        sumSq += d * d;
        if (d > maxd) maxd = d;
        if (d >= 4) far++;
        if (_inBox(r, c, tr, tc)) inTarget++;
        if (_inBox(r, c, sr, sc)) inStart++;
      }
    }
    score += sign *
        (inTarget * 140 - inStart * 18 - sum * 4 - sumSq * 5 - maxd * 22 - far * 14);
  }
  return score;
}

bool _inBox(int r, int c, int tr, int tc) =>
    r >= tr && r < tr + 3 && c >= tc && c < tc + 3;

int checkersMinDistToBox(int r, int c, int tr, int tc) {
  var dr = 0;
  if (r < tr) {
    dr = tr - r;
  } else if (r > tr + 2) {
    dr = r - (tr + 2);
  }
  var dc = 0;
  if (c < tc) {
    dc = tc - c;
  } else if (c > tc + 2) {
    dc = c - (tc + 2);
  }
  return dr + dc;
}
