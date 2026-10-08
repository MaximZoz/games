import 'dart:math';

import 'package:multigames_client/games/chess/chess_engine.dart';

const int _botWinScore = 1000000;
const int _botSearchDepth = 3;
const int _botQuiesceCap = 4;

const List<int> _pieceValue = [0, 100, 320, 330, 500, 900, 20000];

const List<int> _pawnPST = [
  0, 0, 0, 0, 0, 0, 0, 0,
  5, 10, 10, -20, -20, 10, 10, 5,
  5, -5, -10, 0, 0, -10, -5, 5,
  0, 0, 0, 20, 20, 0, 0, 0,
  5, 5, 10, 25, 25, 10, 5, 5,
  10, 10, 20, 30, 30, 20, 10, 10,
  50, 50, 50, 50, 50, 50, 50, 50,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _knightPST = [
  -50, -40, -30, -30, -30, -30, -40, -50,
  -40, -20, 0, 5, 5, 0, -20, -40,
  -30, 5, 10, 15, 15, 10, 5, -30,
  -30, 0, 15, 20, 20, 15, 0, -30,
  -30, 5, 15, 20, 20, 15, 5, -30,
  -30, 0, 10, 15, 15, 10, 0, -30,
  -40, -20, 0, 0, 0, 0, -20, -40,
  -50, -40, -30, -30, -30, -30, -40, -50,
];
const List<int> _bishopPST = [
  -20, -10, -10, -10, -10, -10, -10, -20,
  -10, 5, 0, 0, 0, 0, 5, -10,
  -10, 10, 10, 10, 10, 10, 10, -10,
  -10, 0, 10, 10, 10, 10, 0, -10,
  -10, 5, 5, 10, 10, 5, 5, -10,
  -10, 0, 5, 10, 10, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -10, -10, -10, -10, -20,
];
const List<int> _rookPST = [
  0, 0, 0, 5, 5, 0, 0, 0,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  5, 10, 10, 10, 10, 10, 10, 5,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _queenPST = [
  -20, -10, -10, -5, -5, -10, -10, -20,
  -10, 0, 5, 0, 0, 0, 0, -10,
  -10, 5, 5, 5, 5, 5, 0, -10,
  0, 0, 5, 5, 5, 5, 0, -5,
  -5, 0, 5, 5, 5, 5, 0, -5,
  -10, 0, 5, 5, 5, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -5, -5, -10, -10, -20,
];
const List<int> _kingPST = [
  20, 30, 10, 0, 0, 10, 30, 20,
  20, 20, 0, 0, 0, 0, 20, 20,
  -10, -20, -20, -20, -20, -20, -20, -10,
  -20, -30, -30, -40, -40, -30, -30, -20,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
];

int _pstFor(int k, int index, int seat) {
  var i = index;
  if (seat == 1) {
    i = (ChessEngine.size - 1 - index ~/ ChessEngine.size) * ChessEngine.size +
        index % ChessEngine.size;
  }
  switch (k) {
    case 1:
      return _pawnPST[i];
    case 2:
      return _knightPST[i];
    case 3:
      return _bishopPST[i];
    case 4:
      return _rookPST[i];
    case 5:
      return _queenPST[i];
    case 6:
      return _kingPST[i];
  }
  return 0;
}

/// Лучший ход бота: alpha-beta с квиесценцией и позиционной оценкой.
ChessMove? chessPickMove(ChessEngine g, [Random? rng]) {
  final legal = g.legalMoves();
  if (legal.isEmpty) return null;
  if (legal.length == 1) return legal.first;
  rng ??= Random(1);
  final rootSeat = g.turn;
  var depth = _botSearchDepth;
  if (legal.length > 34) depth = 2;
  var best = legal.first;
  var bestScore = -1 << 30;
  var ties = 0;
  const wide = 1 << 30;
  for (final mv in _orderMoves(g, legal)) {
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final score = -_alphabeta(child, depth - 1, -wide, wide, rootSeat);
    if (score > bestScore) {
      bestScore = score;
      best = mv;
      ties = 1;
    } else if (score == bestScore) {
      ties++;
      if (rng.nextInt(ties) == 0) best = mv;
    }
  }
  return best;
}

int _alphabeta(ChessEngine g, int depth, int alpha, int beta, int rootSeat) {
  if (g.isOver) {
    if (g.winner == ChessEngine.winnerDraw) return 0;
    if (g.winner == g.turn) return _botWinScore + depth;
    return -_botWinScore - depth;
  }
  if (depth <= 0) return _quiesce(g, alpha, beta, _botQuiesceCap);
  final legal = g.legalMoves();
  if (legal.isEmpty) return _evaluateSide(g, g.turn);
  var best = -1 << 30;
  for (final mv in _orderMoves(g, legal)) {
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final s = -_alphabeta(child, depth - 1, -beta, -alpha, rootSeat);
    if (s > best) best = s;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

int _quiesce(ChessEngine g, int alpha, int beta, int depth) {
  if (g.isOver) {
    if (g.winner == ChessEngine.winnerDraw) return 0;
    if (g.winner == g.turn) return _botWinScore;
    return -_botWinScore;
  }
  final stand = _evaluateSide(g, g.turn);
  if (depth <= 0) return stand;
  if (stand >= beta) return beta;
  if (stand > alpha) alpha = stand;
  for (final mv in _orderMoves(g, g.legalMoves())) {
    if (g.at(mv.to.r, mv.to.c) == ChessEngine.empty && mv.promo == 0) continue;
    final child = g.clone();
    try {
      child.apply(g.turn, mv);
    } catch (_) {
      continue;
    }
    final s = -_quiesce(child, -beta, -alpha, depth - 1);
    if (s >= beta) return beta;
    if (s > alpha) alpha = s;
  }
  return alpha;
}

List<ChessMove> _orderMoves(ChessEngine g, List<ChessMove> legal) {
  final out = List<ChessMove>.from(legal);
  int score(ChessMove mv) {
    var s = 0;
    final victim = g.at(mv.to.r, mv.to.c);
    if (victim != ChessEngine.empty) {
      s += _pieceValue[ChessEngine.kind(victim)] * 10 -
          _pieceValue[ChessEngine.kind(g.at(mv.from.r, mv.from.c))];
    }
    if (mv.promo != 0) s += _pieceValue[mv.promo];
    return s;
  }

  out.sort((a, b) => score(b).compareTo(score(a)));
  return out;
}

int _evaluateSide(ChessEngine g, int seat) {
  var score = 0;
  for (var i = 0; i < g.board.length; i++) {
    final p = g.board[i];
    if (p == ChessEngine.empty) continue;
    final own = ChessEngine.colorOf(p);
    final val = _pieceValue[ChessEngine.kind(p)] +
        _pstFor(ChessEngine.kind(p), i, own);
    if (own == seat) {
      score += val;
    } else {
      score -= val;
    }
  }
  return score;
}
