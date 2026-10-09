import 'dart:math' as math;

import 'package:multigames_client/games/nardy/nardy_engine.dart';

/// Идентификатор бота нард (совпадает с сервером).
const String nardyBotUserId = 'bot:nardy';

const int _nardyBotNodeLimit = 12000;

/// Лучший ход поиском по оставшимся кубикам. `null` — ходов нет.
NardyMove? nardyBotBestMove(NardyEngine game, math.Random rng) {
  final moves = game.legalMoves();
  if (moves.isEmpty) return null;
  final seat = game.turn;
  NardyMove best = moves.first;
  var bestScore = -1 << 30;
  var ties = 0;
  var nodes = 0;
  for (final mv in moves) {
    final probe = game.clone();
    if (!probe.applyMoveUnchecked(mv)) continue;
    final score = _nardySearchTurn(probe, seat, () => ++nodes);
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

int _nardySearchTurn(NardyEngine game, int seat, int Function() bump) {
  if (game.off[seat] >= nardyCheckers) return 200000;
  if (game.off[nardyOpponent(seat)] >= nardyCheckers) return -200000;
  if (bump() > _nardyBotNodeLimit) return nardyEvaluate(game, seat);
  final moves = game.legalMoves();
  if (moves.isEmpty) return nardyEvaluate(game, seat);
  var best = -1 << 30;
  for (final mv in moves) {
    final probe = game.clone();
    if (!probe.applyMoveUnchecked(mv)) continue;
    final s = _nardySearchTurn(probe, seat, bump);
    if (s > best) best = s;
  }
  return best;
}

/// Оценка позиции глазами [seat]; больше — лучше.
int nardyEvaluate(NardyEngine game, int seat) {
  final opp = nardyOpponent(seat);
  var score = (game.pips(opp) - game.pips(seat)) * 6;
  score += game.off[seat] * 80;
  score -= game.off[opp] * 80;
  if (!game.isLong) {
    score += game.bar[opp] * 70;
    score -= game.bar[seat] * 90;
    score += _nardyPrimeLen(game, seat) * 18 - _nardyPrimeLen(game, opp) * 16;
    for (var t = 0; t < nardyPoints; t++) {
      final mine = game.countAt(seat, t);
      if (mine == 1) {
        score -= 22 + (nardyPoints - t) ~/ 2;
      } else if (mine >= 2) {
        score += 14;
        if (t >= nardyHomeStart) score += 16;
        if (mine >= 3) score += 4;
      }
      if (game.countAt(opp, t) == 1 && mine == 0) {
        score += 8;
      }
    }
    return score;
  }
  final leftOnHead = game.countAt(seat, 0);
  score -= leftOnHead * 28;
  var laggard = -1;
  var spread = 0;
  for (var t = 0; t < nardyPoints; t++) {
    final n = game.countAt(seat, t);
    if (n == 0) continue;
    laggard = laggard < 0 ? t : laggard;
    spread++;
    if (t >= nardyHomeStart) score += 8;
  }
  if (laggard >= 0) score += laggard * 5;
  score += spread * 4;
  score += _nardyPrimeLen(game, seat) * 10;
  return score;
}

int _nardyPrimeLen(NardyEngine game, int seat) {
  var best = 0;
  var run = 0;
  for (var t = 0; t < nardyPoints; t++) {
    if (game.countAt(seat, t) >= 2) {
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
  }
  return best;
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
