import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

/// Пунктов на доске.
const int nardyPoints = 24;

/// Шашек у каждого игрока.
const int nardyCheckers = 15;

/// Первый индекс дорожки, входящий в дом.
const int nardyHomeStart = 18;

/// Псевдо-индекс дорожки для шашки на баре (короткие нарды).
const int nardyBarTrack = -1;

/// Длина заблокированного ряда в длинных нардах.
///
/// Шесть своих пунктов подряд запирают соперника наглухо, поэтому такой ряд
/// разрешён, только если хотя бы одна его шашка уже прошла блок.
const int nardyPrimeLimit = 6;

/// У [seat] есть ряд из [nardyPrimeLimit] занятых пунктов подряд, который не
/// обошла ни одна шашка соперника.
///
/// Считаем в координатах дорожки соперника: он идёт 0 → 23, поэтому «прошла»
/// значит стоит дальше конца ряда либо уже снята с доски.
bool nardyHasSealedPrime({
  required String mode,
  required int seat,
  required List<int> board,
  required int opponentOff,
}) {
  if (nardyNormalizeMode(mode) != nardyModeLong) return false;
  if (opponentOff > 0) return false;
  final opp = nardyOpponent(seat);
  final mine = List<bool>.filled(nardyPoints, false);
  final theirs = List<bool>.filled(nardyPoints, false);
  for (var t = 0; t < nardyPoints; t++) {
    final p = nardyTrackToBoard(mode, opp, t);
    if (p < 0 || p >= board.length) continue;
    final v = board[p];
    mine[t] = seat == 0 ? v > 0 : v < 0;
    theirs[t] = seat == 0 ? v < 0 : v > 0;
  }
  var run = 0;
  for (var t = 0; t < nardyPoints; t++) {
    if (!mine[t]) {
      run = 0;
      continue;
    }
    run++;
    if (run < nardyPrimeLimit) continue;
    var ahead = false;
    for (var k = t + 1; k < nardyPoints; k++) {
      if (theirs[k]) {
        ahead = true;
        break;
      }
    }
    if (!ahead) return true;
  }
  return false;
}

/// Ход: с какого пункта дорожки и каким кубиком.
class NardyMove {
  const NardyMove(this.from, this.die);

  final int from;
  final int die;

  @override
  bool operator ==(Object other) =>
      other is NardyMove && other.from == from && other.die == die;

  @override
  int get hashCode => Object.hash(from, die);

  @override
  String toString() => 'NardyMove($from, $die)';
}

/// Сыгранный ход и всё нужное, чтобы его откатить.
class NardyMoveRecord {
  NardyMoveRecord({
    required this.from,
    required this.die,
    required this.hit,
    required this.boreOff,
    required this.diceBefore,
    required this.headBefore,
  });

  final int from;
  final int die;
  final bool hit;
  final bool boreOff;

  /// Кубики до хода: правило максимума могло срезать оставшиеся.
  final List<int> diceBefore;
  final int headBefore;
}

/// Сыгранная в этом ходу шашка в координатах своей дорожки.
class NardyPlayedMove {
  const NardyPlayedMove({
    required this.from,
    required this.to,
    required this.die,
    this.boreOff = false,
  });

  final int from;

  /// [nardyPoints] — шашка снята с доски.
  final int to;
  final int die;
  final bool boreOff;

  factory NardyPlayedMove.fromJson(Map<String, dynamic> json) => NardyPlayedMove(
        from: (json['from'] as num?)?.toInt() ?? 0,
        to: (json['to'] as num?)?.toInt() ?? 0,
        die: (json['die'] as num?)?.toInt() ?? 0,
        boreOff: json['bore_off'] == true,
      );
}

/// Ход в физических пунктах доски — для подсветки хода соперника.
class NardyTurnMove {
  const NardyTurnMove({
    required this.fromPoint,
    required this.toPoint,
    this.fromBar = false,
    this.boreOff = false,
    this.hit = false,
  });

  /// `-1` — с бара.
  final int fromPoint;

  /// `-1` — снято с доски.
  final int toPoint;
  final bool fromBar;
  final bool boreOff;
  final bool hit;

  factory NardyTurnMove.fromJson(Map<String, dynamic> json) => NardyTurnMove(
        fromPoint: (json['from_point'] as num?)?.toInt() ?? -1,
        toPoint: (json['to_point'] as num?)?.toInt() ?? -1,
        fromBar: json['from_bar'] == true,
        boreOff: json['bore_off'] == true,
        hit: json['hit'] == true,
      );
}

/// Индекс дорожки игрока → физический пункт доски.
int nardyTrackToBoard(String mode, int seat, int track) {
  if (track < 0 || track >= nardyPoints) return -1;
  if (seat == 0) return nardyPoints - 1 - track;
  if (nardyNormalizeMode(mode) == nardyModeLong) {
    return ((11 - track) + nardyPoints) % nardyPoints;
  }
  return track;
}

/// Физический пункт → индекс дорожки игрока.
int nardyBoardToTrack(String mode, int seat, int point) {
  if (point < 0 || point >= nardyPoints) return -1;
  if (seat == 0) return nardyPoints - 1 - point;
  if (nardyNormalizeMode(mode) == nardyModeLong) {
    return ((11 - point) + nardyPoints) % nardyPoints;
  }
  return point;
}

int nardyOpponent(int seat) => seat == 0 ? 1 : 0;

/// Состояние партии нард. Порт серверного движка `internal/nardy`.
class NardyEngine {
  NardyEngine._({
    required this.mode,
    required List<int> board,
    required List<int> bar,
    required List<int> off,
    required this.turn,
    required List<int> dice,
    required List<int> rolled,
    required this.headMoved,
    required this.turnNo,
    required this.winner,
    required this.winKind,
    List<NardyMoveRecord>? history,
    List<NardyTurnMove>? lastTurn,
    this.lastTurnSeat = -1,
    this.seq = 0,
  })  : _board = board,
        _bar = bar,
        _off = off,
        _dice = dice,
        _rolled = rolled,
        _history = history ?? <NardyMoveRecord>[],
        _lastTurn = lastTurn ?? <NardyTurnMove>[];

  /// Стартовая расстановка выбранного режима.
  factory NardyEngine.newGame(String mode) {
    final normalized = nardyNormalizeMode(mode);
    final engine = NardyEngine._(
      mode: normalized,
      board: List<int>.filled(nardyPoints, 0),
      bar: [0, 0],
      off: [0, 0],
      turn: 0,
      dice: <int>[],
      rolled: <int>[],
      headMoved: 0,
      turnNo: 0,
      winner: -1,
      winKind: '',
    );
    if (normalized == nardyModeLong) {
      engine._setTrack(0, 0, nardyCheckers);
      engine._setTrack(1, 0, nardyCheckers);
      return engine;
    }
    for (final seat in [0, 1]) {
      engine._setTrack(seat, 0, 2);
      engine._setTrack(seat, 11, 5);
      engine._setTrack(seat, 16, 3);
      engine._setTrack(seat, 18, 5);
    }
    return engine;
  }

  /// Собрать движок из серверного/репозиторного снимка.
  ///
  /// Используется клиентом для локального планирования подсветки: например,
  /// дубль 4-4-4 должен подсветить для одной шашки не только +4, но и +8/+12,
  /// если эти промежуточные ходы легальны.
  factory NardyEngine.fromSnapshot({
    required String mode,
    required List<int> board,
    required List<int> bar,
    required List<int> off,
    required int turn,
    required List<int> dice,
    required List<int> rolled,
    required int headMoved,
    required int turnNo,
    int winner = -1,
    String winKind = '',
    int seq = 0,
  }) {
    final normalizedBoard = List<int>.filled(nardyPoints, 0);
    for (var i = 0; i < board.length && i < nardyPoints; i++) {
      normalizedBoard[i] = board[i];
    }
    return NardyEngine._(
      mode: nardyNormalizeMode(mode),
      board: normalizedBoard,
      bar: [
        bar.isNotEmpty ? bar[0] : 0,
        bar.length > 1 ? bar[1] : 0,
      ],
      off: [
        off.isNotEmpty ? off[0] : 0,
        off.length > 1 ? off[1] : 0,
      ],
      turn: turn,
      dice: List<int>.of(dice),
      rolled: List<int>.of(rolled),
      headMoved: headMoved,
      turnNo: turnNo,
      winner: winner,
      winKind: winKind,
      seq: seq,
    );
  }

  final String mode;
  final List<int> _board;
  final List<int> _bar;
  final List<int> _off;
  final List<int> _dice;
  final List<int> _rolled;
  final List<NardyMoveRecord> _history;
  List<NardyTurnMove> _lastTurn;

  int turn;
  int headMoved;
  int turnNo;
  int winner;
  String winKind;
  int lastTurnSeat;

  /// Монотонный счётчик изменений — отмена хода откатывает позицию.
  int seq;

  List<int> get board => List<int>.unmodifiable(_board);
  List<int> get bar => List<int>.unmodifiable(_bar);
  List<int> get off => List<int>.unmodifiable(_off);
  List<int> get dice => List<int>.unmodifiable(_dice);
  List<int> get rolled => List<int>.unmodifiable(_rolled);
  List<NardyTurnMove> get lastTurn => List<NardyTurnMove>.unmodifiable(_lastTurn);

  bool get isLong => nardyNormalizeMode(mode) == nardyModeLong;
  bool get isOver => winner >= 0;

  /// Кубиков не осталось — ход ждёт подтверждения.
  bool get turnComplete => !isOver && _dice.isEmpty;

  /// Есть что откатить в текущем ходу.
  bool get canUndo => !isOver && _history.isNotEmpty;

  /// Шашки, сыгранные в этом ходу, в координатах своей дорожки.
  List<NardyPlayedMove> get currentTurn => [
        for (final rec in _history)
          NardyPlayedMove(
            from: rec.from,
            to: rec.boreOff
                ? nardyPoints
                : (rec.from == nardyBarTrack
                    ? rec.die - 1
                    : rec.from + rec.die),
            die: rec.die,
            boreOff: rec.boreOff,
          ),
      ];

  NardyEngine clone() => NardyEngine._(
        mode: mode,
        board: List<int>.of(_board),
        bar: List<int>.of(_bar),
        off: List<int>.of(_off),
        turn: turn,
        dice: List<int>.of(_dice),
        rolled: List<int>.of(_rolled),
        headMoved: headMoved,
        turnNo: turnNo,
        winner: winner,
        winKind: winKind,
        history: List<NardyMoveRecord>.of(_history),
        lastTurn: List<NardyTurnMove>.of(_lastTurn),
        lastTurnSeat: lastTurnSeat,
        seq: seq,
      );

  /// Расставить позицию вручную — только для тестов и восстановления.
  @visibleForTesting
  void debugSetPosition({
    Map<int, int>? tracksForSeat0,
    Map<int, int>? tracksForSeat1,
    List<int>? bar,
    List<int>? off,
    bool clear = true,
  }) {
    if (clear) {
      for (var i = 0; i < nardyPoints; i++) {
        _board[i] = 0;
      }
    }
    tracksForSeat0?.forEach((track, count) => _setTrack(0, track, count));
    tracksForSeat1?.forEach((track, count) => _setTrack(1, track, count));
    if (bar != null && bar.length == 2) {
      _bar[0] = bar[0];
      _bar[1] = bar[1];
    }
    if (off != null && off.length == 2) {
      _off[0] = off[0];
      _off[1] = off[1];
    }
  }

  void _setTrack(int seat, int track, int count) {
    final p = nardyTrackToBoard(mode, seat, track);
    if (p < 0) return;
    _board[p] = seat == 0 ? count : -count;
  }

  /// Сколько шашек игрока стоит на пункте его дорожки.
  int countAt(int seat, int track) {
    final p = nardyTrackToBoard(mode, seat, track);
    if (p < 0) return 0;
    final v = _board[p];
    if (seat == 0) return v > 0 ? v : 0;
    return v < 0 ? -v : 0;
  }

  /// Сколько шашек соперника стоит на пункте дорожки игрока.
  int opponentAt(int seat, int track) {
    final p = nardyTrackToBoard(mode, seat, track);
    if (p < 0) return 0;
    final v = _board[p];
    if (seat == 0) return v < 0 ? -v : 0;
    return v > 0 ? v : 0;
  }

  void _addAt(int seat, int track, int delta) {
    final p = nardyTrackToBoard(mode, seat, track);
    if (p < 0) return;
    _board[p] += seat == 0 ? delta : -delta;
  }

  /// Все шашки игрока в доме — можно выбрасывать.
  bool allHome(int seat) {
    if (_bar[seat] > 0) return false;
    for (var t = 0; t < nardyHomeStart; t++) {
      if (countAt(seat, t) > 0) return false;
    }
    return true;
  }

  /// Можно ли поставить шашку на пункт дорожки.
  bool canLand(int seat, int track) {
    if (track < 0 || track >= nardyPoints) return false;
    final opp = opponentAt(seat, track);
    if (opp == 0) return true;
    if (isLong) return false;
    return opp == 1;
  }

  /// Сколько шашек можно снять с головы за ход.
  int get headAllowance {
    if (!isLong) return nardyCheckers;
    if (turnNo < 2 && _rolled.length == 4) {
      if (_rolled[0] == 3 || _rolled[0] == 4 || _rolled[0] == 6) return 2;
    }
    return 1;
  }

  bool get _headLimitReached => isLong && headMoved >= headAllowance;

  /// Все допустимые ходы текущими кубиками.
  List<NardyMove> legalMoves() {
    if (isOver || _dice.isEmpty) return const [];
    final seat = turn;
    final unique = _dice.toSet().toList()..sort();
    final out = <NardyMove>[];
    if (!isLong && _bar[seat] > 0) {
      for (final die in unique) {
        if (canLand(seat, die - 1)) out.add(NardyMove(nardyBarTrack, die));
      }
      return out;
    }
    final home = allHome(seat);
    for (var t = 0; t < nardyPoints; t++) {
      if (countAt(seat, t) == 0) continue;
      for (final die in unique) {
        if (_moveAllowed(seat, t, die, home)) out.add(NardyMove(t, die));
      }
    }
    return out;
  }

  bool _moveAllowed(int seat, int from, int die, bool home) {
    if (from < 0 || from >= nardyPoints || die < 1 || die > 6) return false;
    if (countAt(seat, from) == 0) return false;
    if (from == 0 && _headLimitReached) return false;
    final to = from + die;
    if (to < nardyPoints) {
      return canLand(seat, to) && !_buildsSealedPrime(seat, from, to);
    }
    if (!home) return false;
    if (to == nardyPoints) return true;
    // Перебор: снимать можно только с самого дальнего занятого пункта.
    for (var t = nardyHomeStart; t < from; t++) {
      if (countAt(seat, t) > 0) return false;
    }
    return true;
  }

  /// Ход достраивает запертый ряд из [nardyPrimeLimit] пунктов.
  bool _buildsSealedPrime(int seat, int from, int to) {
    if (!isLong) return false;
    final fromPoint = nardyTrackToBoard(mode, seat, from);
    final toPoint = nardyTrackToBoard(mode, seat, to);
    if (fromPoint < 0 || toPoint < 0) return false;
    final board = List<int>.of(_board);
    board[fromPoint] += seat == 0 ? -1 : 1;
    board[toPoint] += seat == 0 ? 1 : -1;
    return nardyHasSealedPrime(
      mode: mode,
      seat: seat,
      board: board,
      opponentOff: _off[nardyOpponent(seat)],
    );
  }

  bool get hasLegalMove => legalMoves().isNotEmpty;

  /// Бросок кубиков за текущего игрока.
  bool roll(math.Random rng) {
    if (isOver || _dice.isNotEmpty) return false;
    return rollWith(rng.nextInt(6) + 1, rng.nextInt(6) + 1);
  }

  /// Заданный бросок (восстановление состояния и тесты).
  bool rollWith(int a, int b) {
    if (isOver || _dice.isNotEmpty) return false;
    if (a < 1 || a > 6 || b < 1 || b > 6) return false;
    seq++;
    headMoved = 0;
    _history.clear();
    _rolled.clear();
    _dice.clear();
    if (a == b) {
      _rolled.addAll([a, a, a, a]);
      _dice.addAll([a, a, a, a]);
    } else {
      _rolled.addAll([a, b]);
      _dice.addAll([a, b]);
    }
    _dropUnusableDice();
    if (_dice.isEmpty) endTurn();
    return true;
  }

  void _dropUnusableDice() {
    if (_dice.isEmpty) return;
    if (hasLegalMove) {
      _enforceMaxDice();
      return;
    }
    _dice.clear();
  }

  /// Играется только один кубик из пары — обязателен больший.
  void _enforceMaxDice() {
    if (_dice.length != 2 || _dice[0] == _dice[1]) return;
    final a = _dice[0];
    final b = _dice[1];
    if (_bestSequence(2) == 2) return;
    final canA = _playableSingle(a);
    final canB = _playableSingle(b);
    _dice.clear();
    if (canA && canB) {
      _dice.add(a > b ? a : b);
      return;
    }
    if (canA) {
      _dice.add(a);
      return;
    }
    if (canB) _dice.add(b);
  }

  bool _playableSingle(int die) {
    final probe = clone();
    probe._dice
      ..clear()
      ..add(die);
    return probe.hasLegalMove;
  }

  int _bestSequence(int limit) {
    if (limit <= 0 || _dice.isEmpty) return 0;
    var best = 0;
    for (final mv in legalMoves()) {
      final probe = clone();
      if (probe._applyMoveTracked(mv) == null) continue;
      final got = 1 + probe._bestSequence(limit - 1);
      if (got > best) best = got;
      if (best >= limit) return best;
    }
    return best;
  }

  /// Выполнить ход текущего игрока. `false` — ход недопустим.
  bool applyMove(int seat, NardyMove mv) {
    if (isOver || seat != turn || _dice.isEmpty) return false;
    if (!legalMoves().contains(mv)) return false;
    final diceBefore = List<int>.of(_dice);
    final headBefore = headMoved;
    final result = _applyMoveTracked(mv);
    if (result == null) return false;
    _history.add(NardyMoveRecord(
      from: mv.from,
      die: mv.die,
      hit: result.hit,
      boreOff: result.boreOff,
      diceBefore: diceBefore,
      headBefore: headBefore,
    ));
    seq++;
    _checkWinner();
    if (isOver) {
      _dice.clear();
      _history.clear();
      return true;
    }
    // Ход не закрываем сами: игрок ещё может отменить последнюю шашку.
    _dropUnusableDice();
    return true;
  }

  /// Откатить последний ход текущего игрока.
  bool undo(int seat) {
    if (isOver || seat != turn || _history.isEmpty) return false;
    final rec = _history.removeLast();
    var to = rec.from + rec.die;
    if (rec.from == nardyBarTrack) to = rec.die - 1;
    if (rec.boreOff) {
      _off[seat]--;
    } else {
      _addAt(seat, to, -1);
      if (rec.hit) {
        final opp = nardyOpponent(seat);
        final oppTrack =
            nardyBoardToTrack(mode, opp, nardyTrackToBoard(mode, seat, to));
        _addAt(opp, oppTrack, 1);
        _bar[opp]--;
      }
    }
    if (rec.from == nardyBarTrack) {
      _bar[seat]++;
    } else {
      _addAt(seat, rec.from, 1);
    }
    _dice
      ..clear()
      ..addAll(rec.diceBefore);
    headMoved = rec.headBefore;
    seq++;
    return true;
  }

  /// Ход без проверки легальности — для перебора вариантов ботом на клоне.
  bool applyMoveUnchecked(NardyMove mv) => _applyMoveTracked(mv) != null;

  ({bool hit, bool boreOff})? _applyMoveTracked(NardyMove mv) {
    final seat = turn;
    final idx = _dice.indexOf(mv.die);
    if (idx < 0) return null;
    if (mv.from == nardyBarTrack) {
      if (_bar[seat] == 0) return null;
      final to = mv.die - 1;
      _bar[seat]--;
      final hit = _hitIfNeeded(seat, to);
      _addAt(seat, to, 1);
      _dice.removeAt(idx);
      return (hit: hit, boreOff: false);
    }
    if (countAt(seat, mv.from) == 0) return null;
    _addAt(seat, mv.from, -1);
    if (mv.from == 0 && isLong) headMoved++;
    final to = mv.from + mv.die;
    var hit = false;
    var boreOff = false;
    if (to >= nardyPoints) {
      _off[seat]++;
      boreOff = true;
    } else {
      hit = _hitIfNeeded(seat, to);
      _addAt(seat, to, 1);
    }
    _dice.removeAt(idx);
    return (hit: hit, boreOff: boreOff);
  }

  bool _hitIfNeeded(int seat, int track) {
    if (isLong) return false;
    if (opponentAt(seat, track) != 1) return false;
    final opp = nardyOpponent(seat);
    final oppTrack =
        nardyBoardToTrack(mode, opp, nardyTrackToBoard(mode, seat, track));
    _addAt(opp, oppTrack, -1);
    _bar[opp]++;
    return true;
  }

  void _checkWinner() {
    for (var seat = 0; seat < 2; seat++) {
      if (_off[seat] < nardyCheckers) continue;
      winner = seat;
      winKind = _off[nardyOpponent(seat)] == 0 ? 'mars' : 'single';
      return;
    }
  }

  /// Передать ход сопернику. Бросок остаётся видимым до броска соперника.
  void endTurn() {
    if (isOver) return;
    _lastTurn = _turnMovesForHighlight();
    lastTurnSeat = turn;
    _history.clear();
    _dice.clear();
    headMoved = 0;
    turn = nardyOpponent(turn);
    turnNo++;
    seq++;
  }

  /// Ходы этого хода в физических пунктах — соперник видит, что произошло.
  List<NardyTurnMove> _turnMovesForHighlight() {
    final seat = turn;
    return [
      for (final rec in _history)
        NardyTurnMove(
          fromPoint: rec.from == nardyBarTrack
              ? -1
              : nardyTrackToBoard(mode, seat, rec.from),
          toPoint: rec.boreOff
              ? -1
              : nardyTrackToBoard(
                  mode,
                  seat,
                  rec.from == nardyBarTrack ? rec.die - 1 : rec.from + rec.die,
                ),
          fromBar: rec.from == nardyBarTrack,
          boreOff: rec.boreOff,
          hit: rec.hit,
        ),
    ];
  }

  /// Сдача: побеждает соперник.
  void forfeit(int seat) {
    if (isOver) return;
    winner = nardyOpponent(seat);
    winKind = 'single';
    _dice.clear();
    _history.clear();
    seq++;
  }

  /// Сколько очков осталось пройти игроку до снятия всех шашек.
  int pips(int seat) {
    var total = _bar[seat] * (nardyPoints + 1);
    for (var t = 0; t < nardyPoints; t++) {
      total += countAt(seat, t) * (nardyPoints - t);
    }
    return total;
  }
}
