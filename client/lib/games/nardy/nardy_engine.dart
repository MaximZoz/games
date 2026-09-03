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
  })  : _board = board,
        _bar = bar,
        _off = off,
        _dice = dice,
        _rolled = rolled;

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

  final String mode;
  final List<int> _board;
  final List<int> _bar;
  final List<int> _off;
  final List<int> _dice;
  final List<int> _rolled;

  int turn;
  int headMoved;
  int turnNo;
  int winner;
  String winKind;

  List<int> get board => List<int>.unmodifiable(_board);
  List<int> get bar => List<int>.unmodifiable(_bar);
  List<int> get off => List<int>.unmodifiable(_off);
  List<int> get dice => List<int>.unmodifiable(_dice);
  List<int> get rolled => List<int>.unmodifiable(_rolled);

  bool get isLong => nardyNormalizeMode(mode) == nardyModeLong;
  bool get isOver => winner >= 0;

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
    if (to < nardyPoints) return canLand(seat, to);
    if (!home) return false;
    if (to == nardyPoints) return true;
    // Перебор: снимать можно только с самого дальнего занятого пункта.
    for (var t = nardyHomeStart; t < from; t++) {
      if (countAt(seat, t) > 0) return false;
    }
    return true;
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
    headMoved = 0;
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
      if (!probe._applyMoveRaw(mv)) continue;
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
    if (!_applyMoveRaw(mv)) return false;
    _checkWinner();
    if (isOver) {
      _dice.clear();
      return true;
    }
    _dropUnusableDice();
    if (_dice.isEmpty) endTurn();
    return true;
  }

  /// Ход без проверки легальности — для перебора вариантов ботом на клоне.
  bool applyMoveUnchecked(NardyMove mv) => _applyMoveRaw(mv);

  bool _applyMoveRaw(NardyMove mv) {
    final seat = turn;
    final idx = _dice.indexOf(mv.die);
    if (idx < 0) return false;
    if (mv.from == nardyBarTrack) {
      if (_bar[seat] == 0) return false;
      final to = mv.die - 1;
      _bar[seat]--;
      _hitIfNeeded(seat, to);
      _addAt(seat, to, 1);
      _dice.removeAt(idx);
      return true;
    }
    if (countAt(seat, mv.from) == 0) return false;
    _addAt(seat, mv.from, -1);
    if (mv.from == 0 && isLong) headMoved++;
    final to = mv.from + mv.die;
    if (to >= nardyPoints) {
      _off[seat]++;
    } else {
      _hitIfNeeded(seat, to);
      _addAt(seat, to, 1);
    }
    _dice.removeAt(idx);
    return true;
  }

  void _hitIfNeeded(int seat, int track) {
    if (isLong) return;
    if (opponentAt(seat, track) != 1) return;
    final opp = nardyOpponent(seat);
    final oppTrack =
        nardyBoardToTrack(mode, opp, nardyTrackToBoard(mode, seat, track));
    _addAt(opp, oppTrack, -1);
    _bar[opp]++;
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
    _dice.clear();
    headMoved = 0;
    turn = nardyOpponent(turn);
    turnNo++;
  }

  /// Сдача: побеждает соперник.
  void forfeit(int seat) {
    if (isOver) return;
    winner = nardyOpponent(seat);
    winKind = 'single';
    _dice.clear();
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
