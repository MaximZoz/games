import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';

const int _botWinScore = 1000000;
const int _botSearchDepth = 3;
const int _botQuiesceCap = 4;

/// Граница окна поиска. Намеренно НЕ степень двойки и далеко от 2^31, иначе
/// на web (dart2js, 32-битные битовые операции) значения вида `1 << 30`
/// переполняются в поиске и все ходы получают одинаковую «мусорную» оценку.
const int _inf = 100000000;

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

/// Снимок движка, который можно отдать в изолят.
Map<String, dynamic> chessEnginePayload(ChessEngine g) => {
      'mode': g.mode,
      'board': List<int>.from(g.board),
      'turn': g.turn,
      'winner': g.winner,
      'seq': g.seq,
      'castle': List<bool>.from(g.castle),
      'enPassant': g.enPassant,
      'halfMove': g.halfMove,
      'lastFromR': g.lastFromR,
      'lastFromC': g.lastFromC,
      'lastToR': g.lastToR,
      'lastToC': g.lastToC,
      'posCounts': Map<String, int>.from(g.posCounts),
      'drawReason': g.drawReason,
    };

/// Восстанавливает движок из [chessEnginePayload].
ChessEngine chessEngineFromPayload(Map<String, dynamic> payload) {
  final countsRaw = payload['posCounts'];
  final counts = <String, int>{};
  if (countsRaw is Map) {
    countsRaw.forEach((key, value) {
      counts['$key'] = (value as num).toInt();
    });
  }
  final castleRaw = payload['castle'];
  final castle = castleRaw is List
      ? castleRaw.map((e) => e == true).toList()
      : const [true, true, true, true];
  return ChessEngine(
    mode: '${payload['mode']}',
    board: (payload['board'] as List).map((e) => (e as num).toInt()).toList(),
    turn: (payload['turn'] as num).toInt(),
    winner: (payload['winner'] as num).toInt(),
    seq: (payload['seq'] as num).toInt(),
    castle: castle,
    enPassant: (payload['enPassant'] as num).toInt(),
    halfMove: (payload['halfMove'] as num).toInt(),
    lastFromR: (payload['lastFromR'] as num).toInt(),
    lastFromC: (payload['lastFromC'] as num).toInt(),
    lastToR: (payload['lastToR'] as num).toInt(),
    lastToC: (payload['lastToC'] as num).toInt(),
    posCounts: counts,
    drawReason: '${payload['drawReason']}',
  );
}

/// Точка входа изолята. Пустой map — хода нет.
Map<String, dynamic> chessPickMovePayload(Map<String, dynamic> payload) {
  final mv = chessPickMove(chessEngineFromPayload(payload));
  if (mv == null) return const {};
  return mv.toJson();
}

/// Поиск хода вне UI-изолята, чтобы часы бота тикали каждую секунду.
/// На web изолят недоступен — между ходами корня отдаём кадр таймерам.
Future<ChessMove?> chessPickMoveAsync(ChessEngine g) async {
  if (kIsWeb) return _chessPickMoveYielding(g);
  try {
    final raw = await compute(chessPickMovePayload, chessEnginePayload(g));
    if (raw.isEmpty) return null;
    return ChessMove.fromJson(Map<String, dynamic>.from(raw));
  } catch (_) {
    return _chessPickMoveYielding(g);
  }
}

Future<ChessMove?> _chessPickMoveYielding(ChessEngine g) async {
  final legal = g.legalMoves();
  if (legal.isEmpty) return null;
  if (legal.length == 1) return legal.first;
  final rng = Random(1);
  final rootSeat = g.turn;
  var depth = _botSearchDepth;
  if (legal.length > 34) depth = 2;
  var best = legal.first;
  var bestScore = -_inf;
  var ties = 0;
  const wide = _inf;
  for (final mv in _orderMoves(g, legal)) {
    await Future<void>.delayed(Duration.zero);
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
  var bestScore = -_inf;
  var ties = 0;
  const wide = _inf;
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
  var best = -_inf;
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
  final mine = g.pseudoMobility(seat);
  final theirs = g.pseudoMobility(1 - seat);
  score += (mine - theirs) * 2;
  return score;
}
