import 'package:multigames_client/games/domino/domino_engine.dart';

const int dominoBotSearchDepth = 8;
const int dominoBotNodeCap = 6000;

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
  var bestScore = -1 << 30;
  for (final move in moves) {
    final score = _heuristic(game, seat, move);
    if (score > bestScore || (score == bestScore && _betterMove(move, best))) {
      bestScore = score;
      best = move;
    }
  }
  return DominoAction(type: dominoActionPlay, tile: best.tile, end: best.end);
}

DominoAction? _sampledSearch(DominoGame game, int seat, List<DominoMove> moves) {
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
  var best = moves.first;
  var bestValue = -1 << 30;
  var depth = dominoBotSearchDepth;
  if (bones.length > 1) depth = 5;
  for (final move in _orderMoves(moves)) {
    var total = 0;
    var okN = 0;
    for (final bone in bones) {
      final root = _withHypothesis(game, opp, unseen, bone);
      final next = root.clone();
      try {
        next.apply(DominoAction(
          type: dominoActionPlay,
          tile: move.tile,
          end: move.end,
        ));
      } catch (_) {
        continue;
      }
      final nodes = <int>[0];
      total += _minimax(next, seat, depth - 1, -1 << 30, 1 << 30, nodes);
      okN++;
    }
    if (okN == 0) continue;
    final value = total ~/ okN;
    if (value > bestValue || (value == bestValue && _betterMove(move, best))) {
      bestValue = value;
      best = move;
    }
  }
  return DominoAction(type: dominoActionPlay, tile: best.tile, end: best.end);
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
    for (final move in _orderMoves(moves)) {
      actions.add(DominoAction(
        type: dominoActionPlay,
        tile: move.tile,
        end: move.end,
      ));
    }
  }
  if (seat == root) {
    var value = -1 << 30;
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
    if (value == -1 << 30) return _evalRound(game, root);
    return value;
  }
  var value = 1 << 30;
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
  if (value == 1 << 30) return _evalRound(game, root);
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
