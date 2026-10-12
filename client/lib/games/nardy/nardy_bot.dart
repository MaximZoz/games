import 'dart:math' as math;

import 'package:multigames_client/games/nardy/nardy_engine.dart';

/// Идентификатор бота нард (совпадает с сервером).
const String nardyBotUserId = 'bot:nardy';

/// Дальше этого порога оценки ходов не бывают; на web `1 << 30` переполняется.
const int _nardyScoreFloor = -100000000;

/// Лучший ход поиском по оставшимся кубикам. `null` — ходов нет.
///
/// Каждый кандидат доигрывается до конца броска со своим лимитом узлов.
/// Общий счётчик раньше отдавал весь бюджет первым шашкам с головы.
NardyMove? nardyBotBestMove(NardyEngine game, math.Random rng) {
  final moves = _orderBotMoves(game, game.legalMoves());
  if (moves.isEmpty) return null;
  final seat = game.turn;
  var best = moves.first;
  var bestScore = _nardyScoreFloor;
  var ties = 0;
  final budget = _nodeBudget(game.dice.length);
  final probe = game.clone();
  for (final mv in moves) {
    final undo = probe.applyForSearch(mv);
    if (undo == null) continue;
    final nodes = <int>[0];
    final score = _nardySearchTurn(probe, seat, nodes, budget);
    probe.undoForSearch(mv, undo);
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

/// Два кубика доигрываются целиком; у дубля потолок на каждый корневой ход.
int _nodeBudget(int diceLeft) {
  if (diceLeft >= 4) return 1600;
  if (diceLeft == 3) return 4000;
  return 8000;
}

int _nardySearchTurn(NardyEngine game, int seat, List<int> nodes, int budget) {
  if (game.off[seat] >= nardyCheckers) return 200000;
  if (game.off[nardyOpponent(seat)] >= nardyCheckers) return -200000;
  nodes[0]++;
  if (nodes[0] > budget) return nardyEvaluate(game, seat);
  final moves = _orderBotMoves(game, game.legalMoves());
  if (moves.isEmpty) return nardyEvaluate(game, seat);
  var best = _nardyScoreFloor;
  for (final mv in moves) {
    final undo = game.applyForSearch(mv);
    if (undo == null) continue;
    final s = _nardySearchTurn(game, seat, nodes, budget);
    game.undoForSearch(mv, undo);
    if (s > best) best = s;
  }
  return best;
}

List<NardyMove> _orderBotMoves(NardyEngine game, List<NardyMove> moves) {
  if (moves.length < 2) return moves;
  final out = List<NardyMove>.of(moves);
  int key(NardyMove mv) {
    var k = mv.die;
    var to = mv.from + mv.die;
    if (mv.from == nardyBarTrack) {
      to = mv.die - 1;
      k += 40;
    }
    if (to >= nardyPoints) {
      k += 80;
    } else if (!game.isLong && game.opponentAt(game.turn, to) == 1) {
      k += 60;
    }
    return k + to;
  }

  out.sort((a, b) => key(b).compareTo(key(a)));
  return out;
}

/// Оценка позиции глазами [seat]; больше — лучше.
int nardyEvaluate(NardyEngine game, int seat) {
  final opp = nardyOpponent(seat);
  final myPips = game.pips(seat);
  final oppPips = game.pips(opp);
  final race = oppPips - myPips;
  var score = race * 12;
  if (game.isLong || !_inContact(game)) {
    score += race * 8;
  }
  score += game.off[seat] * 140;
  score -= game.off[opp] * 140;
  if (game.off[seat] == 0) {
    score -= game.off[opp] * 40;
  } else {
    score += 80;
  }
  if (game.off[opp] == 0 && myPips + 8 < oppPips) {
    score += game.off[seat] * 25;
  }
  if (game.isLong) return score + _evalLong(game, seat, opp);
  return score + _evalShort(game, seat, opp);
}

int _evalShort(NardyEngine game, int seat, int opp) {
  var score = game.bar[opp] * 130 - game.bar[seat] * 170;
  if (game.bar[opp] > 0) score += _homeMade(game, seat) * 45;
  if (game.bar[seat] > 0) score -= _homeMade(game, opp) * 50;
  score += _nardyPrimeLen(game, seat) * 22 - _nardyPrimeLen(game, opp) * 20;
  final contact = _inContact(game);
  for (var t = 0; t < nardyPoints; t++) {
    final mine = game.countAt(seat, t);
    if (mine == 1) {
      if (contact) {
        final shots = math.min(4, _directShotDice(game, seat, t));
        var pen = 16 + 18 * shots;
        if (t < 6) pen -= 8;
        score -= pen;
      } else {
        score -= 4;
      }
    } else if (mine >= 2) {
      score += 10;
      if (t >= nardyHomeStart) score += 22;
      if (t < 6) score += 18;
      if (mine > 4 && t < nardyHomeStart) score -= (mine - 4) * 8;
    }
    if (contact && game.countAt(opp, t) == 1) {
      final shots = math.min(3, _directShotDice(game, opp, t));
      score += shots > 0 ? 12 + 10 * shots : 6;
    }
  }
  if (game.allHome(seat)) score += _bearOffShape(game, seat);
  if (game.allHome(opp)) score -= _bearOffShape(game, opp) ~/ 2;
  return score;
}

int _evalLong(NardyEngine game, int seat, int opp) {
  var score = -game.countAt(seat, 0) * 36 + game.countAt(opp, 0) * 20;
  var laggard = -1;
  for (var t = 0; t < nardyPoints; t++) {
    final n = game.countAt(seat, t);
    if (n == 0) continue;
    if (laggard < 0) laggard = t;
    if (t >= nardyHomeStart) score += n * 6;
  }
  if (laggard >= 0) score += laggard * 8;
  var oppLaggard = -1;
  for (var t = 0; t < nardyPoints; t++) {
    if (game.countAt(opp, t) > 0) {
      oppLaggard = t;
      break;
    }
  }
  if (oppLaggard >= 0) {
    var block = 0;
    for (var t = oppLaggard; t < nardyPoints; t++) {
      final myTrack = nardyBoardToTrack(
        game.mode,
        seat,
        nardyTrackToBoard(game.mode, opp, t),
      );
      if (myTrack >= 0 && game.countAt(seat, myTrack) > 0) block++;
    }
    score += block * 14;
  }
  score += _nardyPrimeLen(game, seat) * 8;
  if (game.allHome(seat)) score += _bearOffShape(game, seat);
  return score;
}

int _homeMade(NardyEngine game, int seat) {
  var n = 0;
  for (var t = nardyHomeStart; t < nardyPoints; t++) {
    if (game.countAt(seat, t) >= 2) n++;
  }
  return n;
}

int _bearOffShape(NardyEngine game, int seat) {
  var score = 0;
  var furthest = -1;
  for (var t = nardyHomeStart; t < nardyPoints; t++) {
    final n = game.countAt(seat, t);
    if (n == 0) continue;
    if (furthest < 0) furthest = t;
    score += n * (t - nardyHomeStart) * 3;
  }
  if (furthest >= 0) {
    final deep = game.countAt(seat, furthest);
    if (deep > 2) score -= (deep - 2) * 6;
  }
  return score;
}

bool _inContact(NardyEngine game) {
  if (game.isLong) return false;
  if (game.bar[0] > 0 || game.bar[1] > 0) return true;
  for (var seat = 0; seat < 2; seat++) {
    final opp = nardyOpponent(seat);
    for (var t = 0; t < nardyPoints; t++) {
      if (game.countAt(seat, t) == 0) continue;
      final oppTrack = nardyBoardToTrack(
        game.mode,
        opp,
        nardyTrackToBoard(game.mode, seat, t),
      );
      if (oppTrack <= 0) continue;
      for (var s = 0; s < oppTrack; s++) {
        if (game.countAt(opp, s) > 0) return true;
      }
    }
  }
  return false;
}

int _directShotDice(NardyEngine game, int seat, int track) {
  final opp = nardyOpponent(seat);
  final oppTrack = nardyBoardToTrack(
    game.mode,
    opp,
    nardyTrackToBoard(game.mode, seat, track),
  );
  if (oppTrack < 0) return 0;
  var dice = 0;
  for (var d = 1; d <= 6; d++) {
    final src = oppTrack - d;
    if (src >= 0 && game.countAt(opp, src) > 0) {
      dice++;
      continue;
    }
    if (src < 0 && game.bar[opp] > 0 && oppTrack == d - 1) dice++;
  }
  return dice;
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
