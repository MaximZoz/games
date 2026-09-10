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
        score -= 16 + (nardyPoints - t) ~/ 2;
      } else if (mine >= 2) {
        score += 10;
        if (t >= nardyHomeStart) score += 8;
      }
      if (game.countAt(opp, t) == 1 && mine == 0) {
        score += 3;
      }
    }
    return score;
  }
  final leftOnHead = game.countAt(seat, 0);
  score -= leftOnHead * 22;
  var laggard = -1;
  var spread = 0;
  for (var t = 0; t < nardyPoints; t++) {
    final n = game.countAt(seat, t);
    if (n == 0) continue;
    laggard = laggard < 0 ? t : laggard;
    spread++;
    if (t >= nardyHomeStart) score += 4;
  }
  if (laggard >= 0) score += laggard * 3;
  score += spread * 5;
  return score;
}

/// Одно действие бота: бросок, одна шашка или закрытие хода.
///
/// По шагам, а не целиком: иначе весь ход соперника происходит в одном кадре
/// и на экране его не видно.
bool nardyPlayBotStep(NardyEngine game, math.Random rng) {
  if (game.isOver) return true;
  final seat = game.turn;
  if (game.dice.isEmpty) {
    // Кубики отыграны — ход закрываем отдельным шагом, чтобы последняя
    // шашка успела доехать.
    if (game.canUndo) {
      game.endTurn();
      return true;
    }
    if (!game.roll(rng)) {
      game.endTurn();
      return true;
    }
    // Ходов может не быть — тогда бросок уже передал очередь.
    return game.isOver || game.turn != seat;
  }
  final mv = nardyBotBestMove(game, rng);
  if (mv == null || !game.applyMove(seat, mv)) {
    game.endTurn();
    return true;
  }
  return game.isOver;
}

/// Полный ход бота — для тестов и догона состояния.
void nardyPlayBotTurn(NardyEngine game, math.Random rng) {
  for (var step = 0; step < 10; step++) {
    if (nardyPlayBotStep(game, rng)) return;
  }
}
