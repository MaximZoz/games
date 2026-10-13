import 'dart:convert';

import 'package:multigames_client/games/domino/domino_mode.dart';

const int dominoTileCount = 28;
const int dominoSuitCopies = 7;
const int dominoGoatScore = 101;
const int dominoClassicScore = 100;
const int dominoSeaScore = 125;
const int dominoSeaRecordMin = 25;
const int dominoSeaBlankHit = 75;
const int dominoSeaSixHit = 100;
const int dominoHandSize = 7;

int dominoTargetFor(String? mode) {
  switch (dominoNormalizeMode(mode)) {
    case dominoModeClassic:
      return dominoClassicScore;
    case dominoModeSea:
      return dominoSeaScore;
    default:
      return dominoGoatScore;
  }
}

const String dominoStatusPlaying = 'playing';
const String dominoStatusRoundEnd = 'round_end';
const String dominoStatusOver = 'over';

const String dominoActionPlay = 'play';
const String dominoActionDraw = 'draw';
const String dominoActionPass = 'pass';
const String dominoActionNextRound = 'next_round';
const String dominoActionForfeit = 'forfeit';

const String dominoRoundOut = 'out';
const String dominoRoundFish = 'fish';
const String dominoRoundForfeit = 'forfeit';
const String dominoRoundFast = 'fast';

/// splitmix64 на uint64. В JS нет точных int больше 2^53, поэтому
/// состояние считается в BigInt и совпадает с серверным uint64.
final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;
final BigInt _mixGolden = BigInt.parse('9E3779B97F4A7C15', radix: 16);
final BigInt _mix1 = BigInt.parse('BF58476D1CE4E5B9', radix: 16);
final BigInt _mix2 = BigInt.parse('94D049BB133111EB', radix: 16);

BigInt _u64(BigInt value) => value & _mask64;

BigInt _rngBits(Object? raw) {
  if (raw == null) return BigInt.one;
  if (raw is BigInt) return raw & _mask64;
  if (raw is int) return BigInt.from(raw) & _mask64;
  if (raw is num) return BigInt.from(raw.toInt()) & _mask64;
  return (BigInt.tryParse(raw.toString()) ?? BigInt.one) & _mask64;
}

class DominoAction {
  const DominoAction({
    required this.type,
    this.tile = 0,
    this.end = '',
    this.actor = '',
  });

  final String type;
  final int tile;
  final String end;
  final String actor;

  @override
  bool operator ==(Object other) =>
      other is DominoAction &&
      type == other.type &&
      tile == other.tile &&
      end == other.end &&
      actor == other.actor;

  @override
  int get hashCode => Object.hash(type, tile, end, actor);

  @override
  String toString() => 'DominoAction($type tile=$tile end=$end)';
}

class DominoMove {
  const DominoMove({required this.tile, required this.end});

  final int tile;
  final String end;

  Map<String, dynamic> toJson() => {'tile': tile, 'end': end};

  factory DominoMove.fromJson(Map<String, dynamic> json) => DominoMove(
        tile: (json['tile'] as num?)?.toInt() ?? 0,
        end: (json['end'] ?? '').toString(),
      );
}

class DominoPlaced {
  DominoPlaced({
    required this.id,
    required this.lo,
    required this.hi,
    required this.inward,
    required this.outward,
    required this.end,
    required this.isDouble,
  });

  final int id;
  final int lo;
  final int hi;
  final int inward;
  final int outward;
  final String end;
  final bool isDouble;

  DominoPlaced copy() => DominoPlaced(
        id: id,
        lo: lo,
        hi: hi,
        inward: inward,
        outward: outward,
        end: end,
        isDouble: isDouble,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lo': lo,
        'hi': hi,
        'inward': inward,
        'outward': outward,
        'end': end,
        'double': isDouble,
      };

  factory DominoPlaced.fromJson(Map<String, dynamic> json) => DominoPlaced(
        id: (json['id'] as num?)?.toInt() ?? 0,
        lo: (json['lo'] as num?)?.toInt() ?? 0,
        hi: (json['hi'] as num?)?.toInt() ?? 0,
        inward: (json['inward'] as num?)?.toInt() ?? 0,
        outward: (json['outward'] as num?)?.toInt() ?? 0,
        end: (json['end'] ?? '').toString(),
        isDouble: json['double'] == true,
      );
}

class DominoPlayer {
  DominoPlayer({
    required this.userId,
    List<int>? hand,
    this.score = 0,
    this.forfeited = false,
    this.roundPips = 0,
    this.roundDelta = 0,
  }) : hand = List<int>.of(hand ?? const []);

  final String userId;
  List<int> hand;
  int score;
  bool forfeited;
  int roundPips;
  int roundDelta;

  DominoPlayer copy() => DominoPlayer(
        userId: userId,
        hand: hand,
        score: score,
        forfeited: forfeited,
        roundPips: roundPips,
        roundDelta: roundDelta,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'hand': hand,
        'score': score,
        'forfeited': forfeited,
        'round_pips': roundPips,
        'round_delta': roundDelta,
      };

  factory DominoPlayer.fromJson(Map<String, dynamic> json) => DominoPlayer(
        userId: (json['user_id'] ?? '').toString(),
        hand: [
          for (final id in (json['hand'] as List?) ?? const [])
            (id as num).toInt(),
        ],
        score: (json['score'] as num?)?.toInt() ?? 0,
        forfeited: json['forfeited'] == true,
        roundPips: (json['round_pips'] as num?)?.toInt() ?? 0,
        roundDelta: (json['round_delta'] as num?)?.toInt() ?? 0,
      );
}

class DominoViewPlayer {
  const DominoViewPlayer({
    required this.userId,
    required this.seat,
    required this.hand,
    required this.handCount,
    required this.score,
    required this.forfeited,
    required this.roundPips,
    required this.roundDelta,
  });

  final String userId;
  final int seat;
  final List<int> hand;
  final int handCount;
  final int score;
  final bool forfeited;
  final int roundPips;
  final int roundDelta;
}

class DominoView {
  const DominoView({
    required this.players,
    required this.chain,
    required this.leftEnd,
    required this.rightEnd,
    required this.boneyardCount,
    required this.turn,
    required this.forcedTile,
    required this.round,
    required this.status,
    required this.starter,
    required this.roundKind,
    required this.outSeat,
    required this.goatSeat,
    required this.winnerUserIds,
    required this.legal,
    required this.targetScore,
    required this.mode,
    required this.lastAction,
    required this.lastTile,
    required this.lastEnd,
    required this.lastActor,
    required this.eventSeq,
  });

  final List<DominoViewPlayer> players;
  final List<DominoPlaced> chain;
  final int leftEnd;
  final int rightEnd;
  final int boneyardCount;
  final int turn;
  final int forcedTile;
  final int round;
  final String status;
  final int starter;
  final String roundKind;
  final int outSeat;
  final int goatSeat;
  final List<String> winnerUserIds;
  final List<DominoMove> legal;
  final int targetScore;
  final String mode;
  final String lastAction;
  final int lastTile;
  final String lastEnd;
  final int lastActor;
  final int eventSeq;
}

(int, int) dominoPips(int id) {
  if (id < 0 || id >= dominoTileCount) return (0, 0);
  var hi = 0;
  while (true) {
    final count = hi + 1;
    final base = hi * (hi + 1) ~/ 2;
    if (id < base + count) return (id - base, hi);
    hi++;
  }
}

int dominoTileId(int lo, int hi) {
  if (lo > hi) {
    final swap = lo;
    lo = hi;
    hi = swap;
  }
  return hi * (hi + 1) ~/ 2 + lo;
}

int dominoPipSum(List<int> ids) {
  var sum = 0;
  for (final id in ids) {
    final (lo, hi) = dominoPips(id);
    sum += lo + hi;
  }
  return sum;
}

bool dominoIsDouble(int id) {
  final (lo, hi) = dominoPips(id);
  return lo == hi;
}

bool dominoTileMatches(int id, int end) {
  if (end < 0) return false;
  final (lo, hi) = dominoPips(id);
  return lo == end || hi == end;
}

(int, int) dominoOrient(int id, int end) {
  final (lo, hi) = dominoPips(id);
  if (lo == end) return (lo, hi);
  return (hi, lo);
}

class DominoGame {
  DominoGame({
    required this.players,
    List<int>? boneyard,
    List<DominoPlaced>? chain,
    this.leftEnd = -1,
    this.rightEnd = -1,
    this.turn = 0,
    this.forcedTile = -1,
    this.round = 1,
    this.status = dominoStatusPlaying,
    this.starter = 0,
    this.roundKind = '',
    this.outSeat = -1,
    this.goatSeat = -1,
    List<String>? winnerUserIds,
    this.lastAction = '',
    this.lastTile = -1,
    this.lastEnd = '',
    this.lastActor = -1,
    this.eventSeq = 0,
    Object? rng,
    this.target = dominoGoatScore,
    this.mode = dominoModeKozel,
  })  : boneyard = List<int>.of(boneyard ?? const []),
        chain = List<DominoPlaced>.of(chain ?? const []),
        winnerUserIds = List<String>.of(winnerUserIds ?? const []),
        rng = _rngBits(rng);

  List<DominoPlayer> players;
  List<int> boneyard;
  List<DominoPlaced> chain;
  int leftEnd;
  int rightEnd;
  int turn;
  int forcedTile;
  int round;
  String status;
  int starter;
  String roundKind;
  int outSeat;
  int goatSeat;
  List<String> winnerUserIds;
  String lastAction;
  int lastTile;
  String lastEnd;
  int lastActor;
  int eventSeq;
  BigInt rng;
  int target;
  String mode;

  bool get isOver => status == dominoStatusOver;

  factory DominoGame.newGame(
    List<String> playerIds,
    int seed, [
    String mode = dominoModeKozel,
  ]) {
    if (playerIds.length < 2 || playerIds.length > 4) {
      throw StateError('domino: need 2..4 players');
    }
    if (seed == 0) seed = 1;
    final normalized = dominoNormalizeMode(mode);
    final game = DominoGame(
      players: [
        for (final id in playerIds) DominoPlayer(userId: id),
      ],
      rng: seed,
      mode: normalized,
      target: dominoTargetFor(normalized),
    );
    game.deal(opening: true);
    return game;
  }

  String get normalizedMode => dominoNormalizeMode(mode);

  int get handSize => normalizedMode == dominoModeClassic && players.length >= 4
      ? 5
      : dominoHandSize;

  int playerIndex(String userId) {
    for (var i = 0; i < players.length; i++) {
      if (players[i].userId == userId) return i;
    }
    return -1;
  }

  DominoGame clone() {
    return DominoGame(
      players: [for (final player in players) player.copy()],
      boneyard: boneyard,
      chain: [for (final placed in chain) placed.copy()],
      leftEnd: leftEnd,
      rightEnd: rightEnd,
      turn: turn,
      forcedTile: forcedTile,
      round: round,
      status: status,
      starter: starter,
      roundKind: roundKind,
      outSeat: outSeat,
      goatSeat: goatSeat,
      winnerUserIds: winnerUserIds,
      lastAction: lastAction,
      lastTile: lastTile,
      lastEnd: lastEnd,
      lastActor: lastActor,
      eventSeq: eventSeq,
      rng: rng,
      target: target,
      mode: mode,
    );
  }

  BigInt _nextRand() {
    rng = _u64(rng + _mixGolden);
    var z = rng;
    z = _u64((z ^ (z >> 30)) * _mix1);
    z = _u64((z ^ (z >> 27)) * _mix2);
    return _u64(z ^ (z >> 31));
  }

  void _shuffle(List<int> ids) {
    for (var i = ids.length - 1; i > 0; i--) {
      final j = (_nextRand() % BigInt.from(i + 1)).toInt();
      final swap = ids[i];
      ids[i] = ids[j];
      ids[j] = swap;
    }
  }

  int aliveCount() {
    var n = 0;
    for (final player in players) {
      if (!player.forfeited) n++;
    }
    return n;
  }

  void deal({required bool opening}) {
    final useOpening = opening || (round <= 1 && eventSeq == 0);
    var nextStarter = 0;
    if (!useOpening) nextStarter = pickNextStarter();
    final ids = [for (var i = 0; i < dominoTileCount; i++) i];
    _shuffle(ids);
    for (final player in players) {
      player.hand = [];
      player.roundPips = 0;
      player.roundDelta = 0;
    }
    var cursor = 0;
    for (final player in players) {
      if (player.forfeited) continue;
      final size = handSize;
      if (cursor + size > ids.length) {
        throw StateError('domino: not enough tiles');
      }
      player.hand = ids.sublist(cursor, cursor + size);
      cursor += size;
    }
    boneyard = ids.sublist(cursor);
    chain = [];
    leftEnd = -1;
    rightEnd = -1;
    forcedTile = -1;
    outSeat = -1;
    roundKind = '';
    lastTile = -1;
    lastEnd = '';
    lastAction = '';
    if (useOpening) {
      final openingPick = pickOpening();
      if (openingPick == null) throw StateError('domino: no opening tile');
      starter = openingPick.$1;
      turn = openingPick.$1;
      forcedTile = openingPick.$2;
      return;
    }
    starter = nextStarter;
    turn = nextStarter;
    forcedTile = -1;
  }

  List<int> get _openingDoubles => normalizedMode == dominoModeClassic
      ? const [6, 0, 5, 4, 3, 2, 1]
      : const [1, 2, 3, 4, 5, 6, 0];

  (int, int)? pickOpening() {
    for (final pip in _openingDoubles) {
      final id = dominoTileId(pip, pip);
      for (var i = 0; i < players.length; i++) {
        if (players[i].forfeited) continue;
        if (players[i].hand.contains(id)) return (i, id);
      }
    }
    var bestSeat = -1;
    var bestTile = -1;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) continue;
      for (final id in players[i].hand) {
        if (bestTile < 0 || _tileBeats(id, bestTile)) {
          bestTile = id;
          bestSeat = i;
        }
      }
    }
    if (bestSeat < 0) return null;
    return (bestSeat, bestTile);
  }

  bool _tileBeats(int a, int b) {
    final (alo, ahi) = dominoPips(a);
    final (blo, bhi) = dominoPips(b);
    if (ahi != bhi) return ahi > bhi;
    return alo > blo;
  }

  int pickNextStarter() {
    if ((roundKind == dominoRoundOut || roundKind == dominoRoundFast) &&
        outSeat >= 0 &&
        outSeat < players.length &&
        !players[outSeat].forfeited) {
      return outSeat;
    }
    var minPips = 1 << 30;
    for (final player in players) {
      if (player.forfeited) continue;
      if (player.roundPips < minPips) minPips = player.roundPips;
    }
    final n = players.length;
    var start = starter;
    if (roundKind == dominoRoundFish) start = (starter + 1) % n;
    for (var step = 0; step < n; step++) {
      final seat = (start + step) % n;
      if (players[seat].forfeited) continue;
      if (players[seat].roundPips == minPips) return seat;
    }
    for (var i = 0; i < players.length; i++) {
      if (!players[i].forfeited) return i;
    }
    return 0;
  }

  void apply(DominoAction action) {
    if (status == dominoStatusOver) {
      throw StateError('game is over');
    }
    switch (action.type) {
      case dominoActionForfeit:
        _forfeit(action);
        return;
      case dominoActionNextRound:
        if (status != dominoStatusRoundEnd) {
          throw StateError('next round is not pending');
        }
        round++;
        deal(opening: false);
        status = dominoStatusPlaying;
        eventSeq++;
        lastAction = dominoActionNextRound;
        lastActor = turn;
        return;
    }
    if (status != dominoStatusPlaying) {
      throw StateError('not your turn');
    }
    final seat = turn;
    if (seat < 0 || seat >= players.length || players[seat].forfeited) {
      throw StateError('not your turn');
    }
    switch (action.type) {
      case dominoActionDraw:
        if (legal(seat).isNotEmpty || boneyard.isEmpty) {
          throw StateError('illegal move');
        }
        final tile = boneyard.removeLast();
        players[seat].hand.add(tile);
        eventSeq++;
        lastAction = dominoActionDraw;
        lastTile = tile;
        lastEnd = '';
        lastActor = seat;
        return;
      case dominoActionPass:
        if (legal(seat).isNotEmpty || boneyard.isNotEmpty) {
          throw StateError('illegal move');
        }
        eventSeq++;
        lastAction = dominoActionPass;
        lastTile = -1;
        lastEnd = '';
        lastActor = seat;
        _advance();
        _maybeFish();
        return;
      case dominoActionPlay:
        final move = _matchLegal(seat, action.tile, action.end);
        if (move == null) throw StateError('illegal move');
        _play(seat, move);
        return;
      default:
        throw StateError('unknown move');
    }
  }

  void _forfeit(DominoAction action) {
    var seat = turn;
    if (action.actor.isNotEmpty) seat = playerIndex(action.actor);
    if (seat < 0 || seat >= players.length) {
      throw StateError('not a player');
    }
    if (players[seat].forfeited) throw StateError('player forfeited');
    players[seat].forfeited = true;
    players[seat].hand = [];
    eventSeq++;
    lastAction = dominoActionForfeit;
    lastTile = -1;
    lastActor = seat;
    if (aliveCount() <= 1) {
      status = dominoStatusOver;
      roundKind = dominoRoundForfeit;
      goatSeat = seat;
      _settleSurvival();
      return;
    }
    if (status == dominoStatusRoundEnd) return;
    if (turn == seat) _advance();
    _maybeFish();
  }

  void _settleSurvival() {
    winnerUserIds = [
      for (final player in players)
        if (!player.forfeited) player.userId,
    ];
  }

  DominoMove? _matchLegal(int seat, int tile, String end) {
    final moves = legal(seat);
    if (leftEnd < 0) {
      for (final move in moves) {
        if (move.tile == tile) return move;
      }
      return null;
    }
    for (final move in moves) {
      if (move.tile == tile && move.end == end) return move;
    }
    if (end.isEmpty) {
      DominoMove? found;
      for (final move in moves) {
        if (move.tile != tile) continue;
        if (found != null) return null;
        found = move;
      }
      return found;
    }
    return null;
  }

  void _play(int seat, DominoMove move) {
    _removeHand(seat, move.tile);
    final (lo, hi) = dominoPips(move.tile);
    late final DominoPlaced placed;
    if (leftEnd < 0) {
      placed = DominoPlaced(
        id: move.tile,
        lo: lo,
        hi: hi,
        inward: lo,
        outward: hi,
        end: 'start',
        isDouble: lo == hi,
      );
      leftEnd = lo;
      rightEnd = hi;
      chain = [placed];
    } else if (move.end == 'left') {
      final (inward, outward) = dominoOrient(move.tile, leftEnd);
      placed = DominoPlaced(
        id: move.tile,
        lo: lo,
        hi: hi,
        inward: inward,
        outward: outward,
        end: 'left',
        isDouble: lo == hi,
      );
      leftEnd = outward;
      chain = [placed, ...chain];
    } else {
      final (inward, outward) = dominoOrient(move.tile, rightEnd);
      placed = DominoPlaced(
        id: move.tile,
        lo: lo,
        hi: hi,
        inward: inward,
        outward: outward,
        end: 'right',
        isDouble: lo == hi,
      );
      rightEnd = outward;
      chain = [...chain, placed];
    }
    forcedTile = -1;
    eventSeq++;
    lastAction = dominoActionPlay;
    lastTile = move.tile;
    lastEnd = placed.end;
    lastActor = seat;
    if (normalizedMode == dominoModeSea && move.tile == dominoTileId(0, 0)) {
      _finishRound(dominoRoundFast, seat);
      return;
    }
    if (players[seat].hand.isEmpty) {
      _finishRound(dominoRoundOut, seat);
      return;
    }
    _advance();
    _maybeFish();
  }

  void _removeHand(int seat, int tile) {
    final hand = players[seat].hand;
    final index = hand.indexOf(tile);
    if (index >= 0) hand.removeAt(index);
  }

  void _advance() {
    if (status != dominoStatusPlaying) return;
    final n = players.length;
    for (var i = 0; i < n; i++) {
      turn = (turn + 1) % n;
      if (!players[turn].forfeited) return;
    }
  }

  void _maybeFish() {
    if (status != dominoStatusPlaying || boneyard.isNotEmpty) return;
    if (_anyCanPlay()) return;
    _finishRound(dominoRoundFish, -1);
  }

  bool canPlace(int seat) {
    if (seat < 0 || seat >= players.length || players[seat].forfeited) {
      return false;
    }
    final hand = players[seat].hand;
    if (leftEnd < 0) return hand.isNotEmpty;
    for (final id in hand) {
      if (dominoTileMatches(id, leftEnd) || dominoTileMatches(id, rightEnd)) {
        return true;
      }
    }
    return false;
  }

  bool _anyCanPlay() {
    for (var i = 0; i < players.length; i++) {
      if (canPlace(i)) return true;
    }
    return false;
  }

  List<DominoMove> legal(int seat) {
    if (status != dominoStatusPlaying || seat < 0 || seat >= players.length) {
      return const [];
    }
    if (players[seat].forfeited || turn != seat) return const [];
    final hand = players[seat].hand;
    if (leftEnd < 0) {
      if (forcedTile >= 0) {
        if (hand.contains(forcedTile)) {
          return [DominoMove(tile: forcedTile, end: 'left')];
        }
        return const [];
      }
      return [for (final id in hand) DominoMove(tile: id, end: 'left')];
    }
    final out = <DominoMove>[];
    for (final id in hand) {
      if (dominoTileMatches(id, leftEnd)) {
        out.add(DominoMove(tile: id, end: 'left'));
      }
      if (dominoTileMatches(id, rightEnd)) {
        out.add(DominoMove(tile: id, end: 'right'));
      }
    }
    return out;
  }

  void _finishRound(String kind, int out) {
    switch (normalizedMode) {
      case dominoModeClassic:
        _finishClassic(kind, out);
      case dominoModeSea:
        _finishSea(kind, out);
      default:
        _finishGoat(kind, out);
    }
  }

  void _finishGoat(String kind, int out) {
    roundKind = kind;
    outSeat = out;
    var active = 0;
    var minPips = 1 << 30;
    final pips = List<int>.filled(players.length, 0);
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) {
        players[i].roundPips = 0;
        players[i].roundDelta = 0;
        continue;
      }
      final sum = dominoPipSum(players[i].hand);
      pips[i] = sum;
      players[i].roundPips = sum;
      active++;
      if (sum < minPips) minPips = sum;
    }
    var minCount = 0;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) continue;
      if (pips[i] == minPips) minCount++;
    }
    var crossed = false;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) continue;
      var delta = pips[i];
      if (kind == dominoRoundFish && minCount < active && pips[i] == minPips) {
        delta = 0;
      }
      players[i].roundDelta = delta;
      players[i].score += delta;
      if (players[i].score >= target) crossed = true;
    }
    _closeRound(crossed);
  }

  void _finishClassic(String kind, int out) {
    roundKind = kind;
    outSeat = out;
    final snap = _snapshotPips();
    for (var i = 0; i < players.length; i++) {
      if (!players[i].forfeited) players[i].roundDelta = 0;
    }
    if (kind == dominoRoundOut &&
        out >= 0 &&
        out < players.length &&
        !players[out].forfeited) {
      var gain = 0;
      for (var i = 0; i < players.length; i++) {
        if (players[i].forfeited || i == out) continue;
        gain += snap.pips[i];
      }
      players[out].roundDelta = gain;
      players[out].score += gain;
    } else if (kind == dominoRoundFish && snap.minCount == 1) {
      var winner = -1;
      var others = 0;
      var oppN = 0;
      for (var i = 0; i < players.length; i++) {
        if (players[i].forfeited) continue;
        if (snap.pips[i] == snap.minPips) {
          winner = i;
          continue;
        }
        others += snap.pips[i];
        oppN++;
      }
      if (winner >= 0) {
        var gain = others - snap.minPips * oppN;
        if (gain < 0) gain = 0;
        players[winner].roundDelta = gain;
        players[winner].score += gain;
      }
    }
    _closeRound(_someoneReached());
  }

  void _finishSea(String kind, int out) {
    roundKind = kind;
    outSeat = out;
    final snap = _snapshotPips();
    for (var i = 0; i < players.length; i++) {
      if (!players[i].forfeited) players[i].roundDelta = 0;
    }
    if (kind == dominoRoundOut &&
        lastTile == dominoTileId(6, 6) &&
        out >= 0 &&
        out < players.length) {
      players[out].score = 0;
    }
    final candidates = <int>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) continue;
      if ((kind == dominoRoundOut || kind == dominoRoundFast) && i == out) {
        continue;
      }
      candidates.add(i);
    }
    if (kind == dominoRoundFast) {
      _chargeUnique(candidates, snap.pips, dominoSeaBlankHit);
    } else if (kind == dominoRoundOut && lastTile == dominoTileId(6, 6)) {
      _chargeUnique(candidates, snap.pips, dominoSeaSixHit);
    } else {
      _chargeHeaviest(candidates, snap.pips);
    }
    _closeRound(_someoneReached());
  }

  ({List<int> pips, int minPips, int minCount}) _snapshotPips() {
    final pips = List<int>.filled(players.length, 0);
    var minPips = 1 << 30;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) {
        players[i].roundPips = 0;
        players[i].roundDelta = 0;
        continue;
      }
      final sum = dominoPipSum(players[i].hand);
      pips[i] = sum;
      players[i].roundPips = sum;
      if (sum < minPips) minPips = sum;
    }
    var minCount = 0;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited) continue;
      if (pips[i] == minPips) minCount++;
    }
    return (pips: pips, minPips: minPips, minCount: minCount);
  }

  bool _someoneReached() {
    for (final player in players) {
      if (!player.forfeited && player.score >= target) return true;
    }
    return false;
  }

  void _chargeUnique(List<int> candidates, List<int> pips, int amount) {
    var best = -1;
    var ties = 0;
    var bestPips = -1;
    for (final seat in candidates) {
      if (pips[seat] > bestPips) {
        bestPips = pips[seat];
        best = seat;
        ties = 1;
        continue;
      }
      if (pips[seat] == bestPips) ties++;
    }
    if (ties != 1 || best < 0) return;
    players[best].roundDelta = amount;
    players[best].score += amount;
  }

  void _chargeHeaviest(List<int> candidates, List<int> pips) {
    var heavy = 0;
    var best = -1;
    var ties = 0;
    var bestPips = -1;
    for (final seat in candidates) {
      if (pips[seat] >= dominoSeaRecordMin) heavy++;
      if (pips[seat] > bestPips) {
        bestPips = pips[seat];
        best = seat;
        ties = 1;
        continue;
      }
      if (pips[seat] == bestPips) ties++;
    }
    if (heavy >= 2 || ties != 1 || best < 0 || bestPips < dominoSeaRecordMin) {
      return;
    }
    players[best].roundDelta = bestPips;
    players[best].score += bestPips;
  }

  void _closeRound(bool crossed) {
    if (crossed || aliveCount() <= 1) {
      status = dominoStatusOver;
      if (normalizedMode == dominoModeClassic) {
        _settlePositive();
        return;
      }
      _settleScores();
      return;
    }
    status = dominoStatusRoundEnd;
  }

  void _settlePositive() {
    goatSeat = -1;
    winnerUserIds = [];
    var bestScore = -1;
    var alive = 0;
    for (final player in players) {
      if (player.forfeited) continue;
      alive++;
      if (player.score > bestScore) bestScore = player.score;
    }
    if (bestScore < 0 || alive == 0) return;
    var same = 0;
    for (final player in players) {
      if (player.forfeited) continue;
      if (player.score == bestScore) same++;
    }
    if (same == alive) return;
    for (final player in players) {
      if (player.forfeited || player.score != bestScore) continue;
      winnerUserIds.add(player.userId);
    }
  }

  void _settleScores() {
    final n = players.length;
    var best = -1;
    var bestScore = -1;
    for (var step = 0; step < n; step++) {
      final seat = (starter + step) % n;
      if (players[seat].forfeited) continue;
      if (best < 0 || players[seat].score > bestScore) {
        best = seat;
        bestScore = players[seat].score;
      }
    }
    goatSeat = best;
    winnerUserIds = [];
    if (best < 0) return;
    var minScore = 1 << 30;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited || i == best) continue;
      if (players[i].score < minScore) minScore = players[i].score;
    }
    if (minScore == 1 << 30 || minScore == bestScore) return;
    for (var i = 0; i < players.length; i++) {
      if (players[i].forfeited || i == best) continue;
      if (players[i].score == minScore) {
        winnerUserIds.add(players[i].userId);
      }
    }
  }

  int knownSuit(int seat, int suit, int extraTile) {
    if (suit < 0) return 0;
    final seen = List<bool>.filled(dominoTileCount, false);
    void mark(int id) {
      if (id < 0 || id >= dominoTileCount || seen[id]) return;
      final (lo, hi) = dominoPips(id);
      if (lo == suit || hi == suit) seen[id] = true;
    }

    for (final placed in chain) {
      mark(placed.id);
    }
    if (seat >= 0 && seat < players.length) {
      for (final id in players[seat].hand) {
        mark(id);
      }
    }
    mark(extraTile);
    var n = 0;
    for (final ok in seen) {
      if (ok) n++;
    }
    return n;
  }

  int otherAlive(int seat) {
    var found = -1;
    for (var i = 0; i < players.length; i++) {
      if (i == seat || players[i].forfeited) continue;
      if (found >= 0) return -1;
      found = i;
    }
    return found;
  }

  List<int> unseen(int seat) {
    final known = List<bool>.filled(dominoTileCount, false);
    if (seat >= 0 && seat < players.length) {
      for (final id in players[seat].hand) {
        if (id >= 0 && id < dominoTileCount) known[id] = true;
      }
    }
    for (final placed in chain) {
      if (placed.id >= 0 && placed.id < dominoTileCount) {
        known[placed.id] = true;
      }
    }
    return [
      for (var id = 0; id < dominoTileCount; id++)
        if (!known[id]) id,
    ];
  }

  DominoView view(String viewer) {
    final reveal = status == dominoStatusRoundEnd || status == dominoStatusOver;
    final viewerSeat = playerIndex(viewer);
    final viewPlayers = <DominoViewPlayer>[];
    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      viewPlayers.add(DominoViewPlayer(
        userId: player.userId,
        seat: i,
        hand: reveal || i == viewerSeat ? List<int>.of(player.hand) : const [],
        handCount: player.hand.length,
        score: player.score,
        forfeited: player.forfeited,
        roundPips: player.roundPips,
        roundDelta: player.roundDelta,
      ));
    }
    var legalMoves = const <DominoMove>[];
    if (viewerSeat == turn &&
        status == dominoStatusPlaying &&
        viewerSeat >= 0 &&
        !players[viewerSeat].forfeited) {
      legalMoves = legal(viewerSeat);
    }
    var shownTile = lastTile;
    if (lastAction == dominoActionDraw && viewerSeat != lastActor && !reveal) {
      shownTile = -1;
    }
    return DominoView(
      players: viewPlayers,
      chain: [for (final placed in chain) placed.copy()],
      leftEnd: leftEnd,
      rightEnd: rightEnd,
      boneyardCount: boneyard.length,
      turn: turn,
      forcedTile: forcedTile,
      round: round,
      status: status,
      starter: starter,
      roundKind: roundKind,
      outSeat: outSeat,
      goatSeat: goatSeat,
      winnerUserIds: List<String>.of(winnerUserIds),
      legal: legalMoves,
      targetScore: target,
      mode: normalizedMode,
      lastAction: lastAction,
      lastTile: shownTile,
      lastEnd: lastEnd,
      lastActor: lastActor,
      eventSeq: eventSeq,
    );
  }

  Map<String, dynamic> toJson() => {
        'players': [for (final player in players) player.toJson()],
        'boneyard': boneyard,
        'chain': [for (final placed in chain) placed.toJson()],
        'left_end': leftEnd,
        'right_end': rightEnd,
        'turn': turn,
        'forced_tile': forcedTile,
        'round': round,
        'status': status,
        'starter': starter,
        'round_kind': roundKind,
        'out_seat': outSeat,
        'goat_seat': goatSeat,
        'winner_user_ids': winnerUserIds,
        'last_action': lastAction,
        'last_tile': lastTile,
        'last_end': lastEnd,
        'last_actor': lastActor,
        'event_seq': eventSeq,
        'rng': rng.toString(),
        'target': target,
        'mode': normalizedMode,
      };

  String encode() => jsonEncode(toJson());

  factory DominoGame.decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic> && json is! Map) {
      throw StateError('domino: empty state');
    }
    final map = Map<String, dynamic>.from(json);
    final game = DominoGame(
      players: [
        for (final item in (map['players'] as List? ?? const []))
          DominoPlayer.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      boneyard: [
        for (final id in (map['boneyard'] as List? ?? const []))
          (id as num).toInt(),
      ],
      chain: [
        for (final item in (map['chain'] as List? ?? const []))
          DominoPlaced.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      leftEnd: (map['left_end'] as num?)?.toInt() ?? -1,
      rightEnd: (map['right_end'] as num?)?.toInt() ?? -1,
      turn: (map['turn'] as num?)?.toInt() ?? 0,
      forcedTile: (map['forced_tile'] as num?)?.toInt() ?? -1,
      round: (map['round'] as num?)?.toInt() ?? 1,
      status: (map['status'] ?? dominoStatusPlaying).toString(),
      starter: (map['starter'] as num?)?.toInt() ?? 0,
      roundKind: (map['round_kind'] ?? '').toString(),
      outSeat: (map['out_seat'] as num?)?.toInt() ?? -1,
      goatSeat: (map['goat_seat'] as num?)?.toInt() ?? -1,
      winnerUserIds: [
        for (final id in (map['winner_user_ids'] as List? ?? const []))
          id.toString(),
      ],
      lastAction: (map['last_action'] ?? '').toString(),
      lastTile: (map['last_tile'] as num?)?.toInt() ?? -1,
      lastEnd: (map['last_end'] ?? '').toString(),
      lastActor: (map['last_actor'] as num?)?.toInt() ?? -1,
      eventSeq: (map['event_seq'] as num?)?.toInt() ?? 0,
      rng: map['rng'],
      target: (map['target'] as num?)?.toInt() ?? 0,
      mode: dominoNormalizeMode(map['mode']?.toString()),
    );
    if (game.target == 0) game.target = dominoTargetFor(game.mode);
    return game;
  }
}
