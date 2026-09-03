import 'dart:math' as math;

import 'package:multigames_client/games/nardy/nardy_engine.dart';

/// Идентификатор бота нард (совпадает с сервером).
const String nardyBotUserId = 'bot:nardy';

/// Лучший ход жадной оценкой позиции. `null` — ходов нет.
NardyMove? nardyBotBestMove(NardyEngine game, math.Random rng) {
  final moves = game.legalMoves();
  if (moves.isEmpty) return null;
  final seat = game.turn;
  NardyMove best = moves.first;
  var bestScore = -1 << 30;
  var ties = 0;
  for (final mv in moves) {
    final probe = game.clone();
    if (!probe.applyMoveUnchecked(mv)) continue;
    final score = nardyEvaluate(probe, seat);
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

/// Оценка позиции глазами [seat]; больше — лучше.
int nardyEvaluate(NardyEngine game, int seat) {
  final opp = nardyOpponent(seat);
  var score = (game.pips(opp) - game.pips(seat)) * 4;
  score += game.off[seat] * 60;
  score -= game.off[opp] * 60;
  if (!game.isLong) {
    score += game.bar[opp] * 45;
    score -= game.bar[seat] * 55;
    for (var t = 0; t < nardyPoints; t++) {
      final mine = game.countAt(seat, t);
      if (mine == 1) {
        score -= 12 + (nardyPoints - t) ~/ 3;
      } else if (mine >= 2) {
        score += 8;
        if (t >= nardyHomeStart) score += 6;
      }
    }
    return score;
  }
  for (var t = nardyHomeStart; t < nardyPoints; t++) {
    if (game.countAt(seat, t) > 0) score += 6;
  }
  score -= game.countAt(seat, 0) * 2;
  return score;
}

/// Один полный ход бота: бросок, все шашки и передача очереди.
void nardyPlayBotTurn(NardyEngine game, math.Random rng) {
  if (game.isOver) return;
  final seat = game.turn;
  if (game.dice.isEmpty && !game.roll(rng)) return;
  for (var step = 0; step < 8; step++) {
    if (game.isOver || game.turn != seat) return;
    if (game.dice.isEmpty) {
      game.endTurn();
      return;
    }
    final mv = nardyBotBestMove(game, rng);
    if (mv == null || !game.applyMove(seat, mv)) {
      game.endTurn();
      return;
    }
  }
  if (!game.isOver && game.turn == seat) game.endTurn();
}
