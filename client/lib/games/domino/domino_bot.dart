import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';

const int dominoBotSearchDepth = 8;
const int dominoBotNodeCap = 6000;

/// «Бесконечность» перебора. Записана числом, а не сдвигом: в вебе (dart2js)
/// сдвиг даёт беззнаковые 32 бита, `-1 << 30` там равно +3221225472, и любой
/// ход оказывается «хуже» начальной оценки.
const int _inf = 1073741824;

DominoAction dominoBestAction(DominoGame game, int seat) {
  if (game.status != dominoStatusPlaying || seat != game.turn) {
    return const DominoAction(type: '');
  }
  final moves = game.legal(seat);
  if (moves.isEmpty) {
    if (game.boneyard.isNotEmpty) {
      return const DominoAction(type: dominoActionDraw);
    }
    return const DominoAction(type: dominoActionPass);
  }
  final searched = _sampledSearch(game, seat, moves);
  if (searched != null) return searched;
  var best = moves.first;
  var bestScore = -_inf;
  for (final move in moves) {
    final score = _heuristic(game, seat, move);
    if (score > bestScore || (score == bestScore && _betterMove(move, best))) {
      bestScore = score;
      best = move;
    }
  }
  final pair = game.pairTiles(seat);
  if (pair != null &&
      _pairHeuristic(game, seat, pair.$1, pair.$2) >= bestScore) {
    return const DominoAction(type: dominoActionPlayPair);
  }
  return DominoAction(type: dominoActionPlay, tile: best.tile, end: best.end);
}

/// Ходы костью в порядке перебора; пара дублей, если она есть, идёт первой:
/// она сбрасывает две кости за ход.
List<DominoAction> _botActions(
  DominoGame game,
  int seat,
  List<DominoMove> moves,
) {
  return [
    if (game.canPair(seat)) const DominoAction(type: dominoActionPlayPair),
    for (final move in _orderMoves(moves))
      DominoAction(type: dominoActionPlay, tile: move.tile, end: move.end),
  ];
}

/// Оценка хода двумя дублями: лучший из двух одиночных ходов плюс вторая
/// сброшенная кость. Закрыть кон парой — как закрыть его костью.
int _pairHeuristic(DominoGame game, int seat, int left, int right) {
  final a = _heuristic(game, seat, DominoMove(tile: left, end: 'left'));
  final b = _heuristic(game, seat, DominoMove(tile: right, end: 'right'));
  var score = a > b ? a : b;
  score += 200;
  if (game.players[seat].hand.length == 2) score += 9000;
  return score;
}

DominoAction? _sampledSearch(
    DominoGame game, int seat, List<DominoMove> moves) {
  if (game.aliveCount() != 2 || moves.isEmpty) return null;
  final opp = game.otherAlive(seat);
  if (opp < 0) return null;
  final unseen = game.unseen(seat);
  final boneN = game.boneyard.length;
  if (boneN + game.players[opp].hand.length != unseen.length || boneN > 2) {
    return null;
  }
  final bones = _combinations(unseen, boneN);
  if (bones.isEmpty || bones.length > 10) return null;
  final actions = _botActions(game, seat, moves);
  var best = actions.first;
  var bestValue = -_inf;
  var depth = dominoBotSearchDepth;
  if (bones.length > 1) depth = 5;
  for (final action in actions) {
    var total = 0;
    var okN = 0;
    for (final bone in bones) {
      final root = _withHypothesis(game, opp, unseen, bone);
      final next = root.clone();
      try {
        next.apply(action);
      } catch (_) {
        continue;
      }
      final nodes = <int>[0];
      total += _minimax(next, seat, depth - 1, -_inf, _inf, nodes);
      okN++;
    }
    if (okN == 0) continue;
    // Действия уже упорядочены: при равной оценке остаётся более раннее.
    final value = total ~/ okN;
    if (value > bestValue) {
      bestValue = value;
      best = action;
    }
  }
  return best;
}

DominoGame _withHypothesis(
  DominoGame game,
  int opp,
  List<int> unseen,
  List<int> bone,
) {
  final next = game.clone();
  final inBone = bone.toSet();
  next.players[opp].hand = [
    for (final id in unseen)
      if (!inBone.contains(id)) id,
  ];
  next.boneyard = List<int>.of(bone);
  return next;
}

List<List<int>> _combinations(List<int> items, int k) {
  if (k == 0) return [const []];
  if (k < 0 || k > items.length) return const [];
  final out = <List<int>>[];
  void walk(int start, List<int> cur) {
    if (cur.length == k) {
      out.add(List<int>.of(cur));
      return;
    }
    final need = k - cur.length;
    for (var i = start; i <= items.length - need; i++) {
      cur.add(items[i]);
      walk(i + 1, cur);
      cur.removeLast();
    }
  }

  walk(0, []);
  return out;
}

bool _betterMove(DominoMove a, DominoMove b) {
  final ap = dominoPipSum([a.tile]);
  final bp = dominoPipSum([b.tile]);
  if (ap != bp) return ap > bp;
  if (a.tile != b.tile) return a.tile < b.tile;
  return a.end == 'left' && b.end != 'left';
}

int _heuristic(DominoGame game, int seat, DominoMove move) {
  final (lo, hi) = dominoPips(move.tile);
  var score = (lo + hi) * 20;
  if (lo == hi) score += 24;
  final hand = [
    for (final id in game.players[seat].hand)
      if (id != move.tile) id,
  ];
  if (hand.isEmpty) score += 9000;
  if (game.normalizedMode == dominoModeSea && hand.length == 1) {
    // Одинокая 0-0 на руках стоит 25, одинокая 6-6 — 50.
    final (weight, forced) = dominoSeaWeight(hand);
    if (forced) score -= weight * 6;
  }
  var left = game.leftEnd;
  var right = game.rightEnd;
  if (left < 0) {
    left = lo;
    right = hi;
  } else if (move.end == 'left' || move.end == 'start') {
    left = dominoOrient(move.tile, left).$2;
  } else {
    right = dominoOrient(move.tile, right).$2;
  }
  var flex = 0;
  for (final id in hand) {
    if (dominoTileMatches(id, left) || dominoTileMatches(id, right)) flex++;
  }
  score += flex * 6;
  var oppLeft = 0;
  final other = game.otherAlive(seat);
  if (other >= 0) oppLeft = game.players[other].hand.length;
  var deadBonus = 12;
  if (game.boneyard.isEmpty) {
    deadBonus = 84;
    if (oppLeft <= 2) deadBonus += 24;
  }
  final leftDead = game.knownSuit(seat, left, move.tile) >= dominoSuitCopies;
  final rightDead = game.knownSuit(seat, right, move.tile) >= dominoSuitCopies;
  if (leftDead) score += deadBonus;
  if (rightDead) score += deadBonus;
  if (game.boneyard.isEmpty && leftDead && rightDead && flex == 0) {
    final mine = dominoPipSum(hand);
    if (mine <= 10) {
      score += 140;
    } else {
      score -= mine * 2;
    }
  }
  return score;
}

List<DominoMove> _orderMoves(List<DominoMove> moves) {
  final out = List<DominoMove>.of(moves);
  for (var i = 1; i < out.length; i++) {
    var j = i;
    while (j > 0 && _betterMove(out[j], out[j - 1])) {
      final swap = out[j];
      out[j] = out[j - 1];
      out[j - 1] = swap;
      j--;
    }
  }
  return out;
}

int _minimax(
  DominoGame game,
  int root,
  int depth,
  int alpha,
  int beta,
  List<int> nodes,
) {
  nodes[0]++;
  if (game.status != dominoStatusPlaying ||
      depth <= 0 ||
      nodes[0] > dominoBotNodeCap) {
    return _evalRound(game, root);
  }
  final seat = game.turn;
  final moves = game.legal(seat);
  final actions = <DominoAction>[];
  if (moves.isEmpty) {
    actions.add(DominoAction(
      type: game.boneyard.isNotEmpty ? dominoActionDraw : dominoActionPass,
    ));
  } else {
    actions.addAll(_botActions(game, seat, moves));
  }
  if (seat == root) {
    var value = -_inf;
    for (final action in actions) {
      final next = game.clone();
      try {
        next.apply(action);
      } catch (_) {
        continue;
      }
      final score = _minimax(next, root, depth - 1, alpha, beta, nodes);
      if (score > value) value = score;
      if (value > alpha) alpha = value;
      if (beta <= alpha) break;
    }
    if (value == -_inf) return _evalRound(game, root);
    return value;
  }
  var value = _inf;
  for (final action in actions) {
    final next = game.clone();
    try {
      next.apply(action);
    } catch (_) {
      continue;
    }
    final score = _minimax(next, root, depth - 1, alpha, beta, nodes);
    if (score < value) value = score;
    if (value < beta) beta = value;
    if (beta <= alpha) break;
  }
  if (value == _inf) return _evalRound(game, root);
  return value;
}

int _evalRound(DominoGame game, int root) {
  if (root < 0 || root >= game.players.length) return 0;
  if (game.status == dominoStatusRoundEnd || game.status == dominoStatusOver) {
    var opp = 0;
    for (var i = 0; i < game.players.length; i++) {
      if (i == root || game.players[i].forfeited) continue;
      opp += game.players[i].roundDelta;
    }
    var value = opp * 4 - game.players[root].roundDelta * 5;
    if (game.normalizedMode == dominoModeClassic) {
      value = game.players[root].roundDelta * 5 - opp * 4;
    }
    if (game.roundKind == dominoRoundOut && game.outSeat == root) value += 8000;
    if (game.roundKind == dominoRoundOut &&
        game.outSeat >= 0 &&
        game.outSeat != root) {
      value -= 8000;
    }
    if (game.goatSeat == root) value -= 20000;
    for (final id in game.winnerUserIds) {
      if (id == game.players[root].userId) value += 20000;
    }
    return value;
  }
  final mine = dominoPipSum(game.players[root].hand);
  var opp = 0;
  for (var i = 0; i < game.players.length; i++) {
    if (i == root || game.players[i].forfeited) continue;
    opp += dominoPipSum(game.players[i].hand);
  }
  return opp - mine * 2;
}

DominoAction dominoGreedyAction(DominoGame game, int seat) {
  final moves = game.legal(seat);
  if (moves.isEmpty) {
    if (game.boneyard.isNotEmpty) {
      return const DominoAction(type: dominoActionDraw);
    }
    return const DominoAction(type: dominoActionPass);
  }
  var best = moves.first;
  var bestPips = -1;
  for (final move in moves) {
    var pips = dominoPipSum([move.tile]);
    if (dominoIsDouble(move.tile)) pips += 3;
    if (pips > bestPips) {
      bestPips = pips;
      best = move;
    }
  }
  return DominoAction(type: dominoActionPlay, tile: best.tile, end: best.end);
}
