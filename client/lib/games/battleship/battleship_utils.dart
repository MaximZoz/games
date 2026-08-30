/// Утилиты «Морского боя» (клиент).
/// Восстановлено по чатам Cursor (март 2026) и контракту сервера PROD v276.
library;

import 'package:multigames_client/games/battleship/battleship_repository.dart';

const int kBattleshipBoardSize = 10;
const int kBattleshipCellCount = kBattleshipBoardSize * kBattleshipBoardSize;

/// Классический русский флот.
const List<int> kBattleshipFleet = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

/// Горизонтальный ли корабль (одиночная клетка — считаем горизонтальным).
bool isShipHorizontal(List<int> ship) {
  if (ship.length <= 1) return true;
  final row = ship.first ~/ kBattleshipBoardSize;
  return ship.every((c) => c ~/ kBattleshipBoardSize == row);
}

/// Клетки корабля длины [length] с головой [headCell] (без валидации соседей).
/// `null`, если не влезает в поле.
List<int>? shipCellsAt({
  required int length,
  required int headCell,
  required bool horizontal,
}) {
  if (length <= 0 || length > 4) return null;
  if (headCell < 0 || headCell >= kBattleshipCellCount) return null;
  final hr = headCell ~/ kBattleshipBoardSize;
  final hc = headCell % kBattleshipBoardSize;
  final cells = <int>[];
  for (var i = 0; i < length; i++) {
    late final int c;
    if (horizontal) {
      if (hc + i >= kBattleshipBoardSize) return null;
      c = hr * kBattleshipBoardSize + (hc + i);
    } else {
      if (hr + i >= kBattleshipBoardSize) return null;
      c = (hr + i) * kBattleshipBoardSize + hc;
    }
    cells.add(c);
  }
  return cells;
}

/// Голова корабля при переносе: клетка [grabOffset] должна оказаться в [dropCell].
int? headCellFromGrab({
  required List<int> ship,
  required int grabOffset,
  required int dropCell,
}) {
  if (grabOffset < 0 || grabOffset >= ship.length) return null;
  if (dropCell < 0 || dropCell >= kBattleshipCellCount) return null;
  final horiz = isShipHorizontal(ship);
  final dropR = dropCell ~/ kBattleshipBoardSize;
  final dropC = dropCell % kBattleshipBoardSize;
  if (horiz) {
    final hc = dropC - grabOffset;
    if (hc < 0) return null;
    return dropR * kBattleshipBoardSize + hc;
  }
  final hr = dropR - grabOffset;
  if (hr < 0) return null;
  return hr * kBattleshipBoardSize + dropC;
}

/// Превью клеток при переносе (даже если будет касание/пересечение).
/// `null` только если корабль не влезает в поле.
List<int>? previewMoveShipCells(
  List<int> ship,
  int grabOffset,
  int dropCell,
) {
  final head = headCellFromGrab(
    ship: ship,
    grabOffset: grabOffset,
    dropCell: dropCell,
  );
  if (head == null) return null;
  return shipCellsAt(
    length: ship.length,
    headCell: head,
    horizontal: isShipHorizontal(ship),
  );
}

/// Перенос корабля: клетка с индексом [grabOffset] в корабле должна
/// оказаться в [dropCell]. Учитывает ориентацию и валидацию касаний.
List<List<int>>? tryMoveShipFromGrab(
  List<List<int>> ships,
  int shipIndex,
  int grabOffset,
  int dropCell,
) {
  if (shipIndex < 0 || shipIndex >= ships.length) return null;
  final ship = ships[shipIndex];
  final head = headCellFromGrab(
    ship: ship,
    grabOffset: grabOffset,
    dropCell: dropCell,
  );
  if (head == null) return null;
  return tryPlaceShip(
    ships,
    shipIndex,
    head,
    horizontal: isShipHorizontal(ship),
  );
}

/// Перенос без проверки касаний (только границы поля) — для UI-редактирования.
List<List<int>>? moveShipFromGrabAllowTouch(
  List<List<int>> ships,
  int shipIndex,
  int grabOffset,
  int dropCell,
) {
  if (shipIndex < 0 || shipIndex >= ships.length) return null;
  final ship = ships[shipIndex];
  final cells = previewMoveShipCells(ship, grabOffset, dropCell);
  if (cells == null) return null;
  final next = ships.map((s) => List<int>.from(s)).toList();
  next[shipIndex] = cells;
  return next;
}

/// Индексы кораблей, которые пересекаются или соприкасаются с другими.
Set<int> conflictingShipIndices(List<List<int>> ships) {
  final bad = <int>{};
  if (ships.isEmpty) return bad;
  for (var i = 0; i < ships.length; i++) {
    for (var j = i + 1; j < ships.length; j++) {
      if (_shipsConflict(ships[i], ships[j])) {
        bad.add(i);
        bad.add(j);
      }
    }
  }
  return bad;
}

bool _shipsConflict(List<int> a, List<int> b) {
  final setB = b.toSet();
  for (final c in a) {
    if (setB.contains(c)) return true;
    final r = c ~/ kBattleshipBoardSize;
    final col = c % kBattleshipBoardSize;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = col + dc;
        if (nr < 0 ||
            nr >= kBattleshipBoardSize ||
            nc < 0 ||
            nc >= kBattleshipBoardSize) {
          continue;
        }
        if (setB.contains(nr * kBattleshipBoardSize + nc)) return true;
      }
    }
  }
  return false;
}

/// Поворот корабля вокруг [headCell] (первая клетка в списке).
/// Возвращает новый список клеток или `null`, если не влезает в поле.
List<int>? rotateShip(List<int> ship) {
  if (ship.length <= 1) return List<int>.from(ship);
  final head = ship.first;
  final hr = head ~/ kBattleshipBoardSize;
  final hc = head % kBattleshipBoardSize;
  final horiz = ship.every((c) => c ~/ kBattleshipBoardSize == hr);
  final out = <int>[head];
  for (var i = 1; i < ship.length; i++) {
    late final int cell;
    if (horiz) {
      // horizontal → vertical down
      cell = (hr + i) * kBattleshipBoardSize + hc;
    } else {
      // vertical → horizontal right
      cell = hr * kBattleshipBoardSize + (hc + i);
    }
    if (cell < 0 || cell >= kBattleshipCellCount) return null;
    if (!horiz && cell ~/ kBattleshipBoardSize != hr) return null;
    out.add(cell);
  }
  return out;
}

/// Пробует разместить корабль [shipIndex] в [headCell].
/// Возвращает новый список кораблей или `null`.
List<List<int>>? tryPlaceShip(
  List<List<int>> ships,
  int shipIndex,
  int headCell, {
  bool horizontal = true,
}) {
  if (shipIndex < 0 || shipIndex >= ships.length) return null;
  final cells = shipCellsAt(
    length: ships[shipIndex].length,
    headCell: headCell,
    horizontal: horizontal,
  );
  if (cells == null) return null;
  final next = ships.map((s) => List<int>.from(s)).toList();
  next[shipIndex] = cells;
  if (!_validatePlacement(next)) return null;
  return next;
}

/// Размещение без проверки касаний (только границы поля).
List<List<int>>? placeShipAllowTouch(
  List<List<int>> ships,
  int shipIndex,
  int headCell, {
  bool horizontal = true,
}) {
  if (shipIndex < 0 || shipIndex >= ships.length) return null;
  final cells = shipCellsAt(
    length: ships[shipIndex].length,
    headCell: headCell,
    horizontal: horizontal,
  );
  if (cells == null) return null;
  final next = ships.map((s) => List<int>.from(s)).toList();
  next[shipIndex] = cells;
  return next;
}

bool _validatePlacement(List<List<int>> ships) {
  if (ships.length != kBattleshipFleet.length) return false;
  final lengths = ships.map((s) => s.length).toList()..sort();
  final expected = List<int>.from(kBattleshipFleet)..sort();
  for (var i = 0; i < lengths.length; i++) {
    if (lengths[i] != expected[i]) return false;
  }
  final occupied = <int>{};
  for (final ship in ships) {
    if (!_isStraightShip(ship)) return false;
    for (final c in ship) {
      if (c < 0 || c >= kBattleshipCellCount || occupied.contains(c)) {
        return false;
      }
      occupied.add(c);
    }
  }
  for (final c in occupied) {
    final r = c ~/ kBattleshipBoardSize;
    final col = c % kBattleshipBoardSize;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= kBattleshipBoardSize || nc < 0 || nc >= kBattleshipBoardSize) {
          continue;
        }
        final n = nr * kBattleshipBoardSize + nc;
        if (!occupied.contains(n)) continue;
        if (!_sameShip(ships, c, n)) return false;
      }
    }
  }
  return true;
}

bool _isStraightShip(List<int> ship) {
  if (ship.isEmpty || ship.length > 4) return false;
  if (ship.length == 1) return true;
  final rows = ship.map((c) => c ~/ kBattleshipBoardSize).toSet();
  final cols = ship.map((c) => c % kBattleshipBoardSize).toSet();
  if (rows.length == 1) {
    final sorted = ship.map((c) => c % kBattleshipBoardSize).toList()..sort();
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1] + 1) return false;
    }
    return true;
  }
  if (cols.length == 1) {
    final sorted = ship.map((c) => c ~/ kBattleshipBoardSize).toList()..sort();
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1] + 1) return false;
    }
    return true;
  }
  return false;
}

bool _sameShip(List<List<int>> ships, int a, int b) {
  for (final ship in ships) {
    if (ship.contains(a) && ship.contains(b)) return true;
  }
  return false;
}

/// Валидна ли полная расстановка.
bool validateBattleshipShips(List<List<int>> ships) => _validatePlacement(ships);

/// Случайная валидная расстановка.
List<List<int>> generateRandomBattleshipShips([int? seed]) {
  final rnd = seed ?? DateTime.now().microsecondsSinceEpoch;
  var state = rnd & 0x7fffffff;
  int next() {
    state = (1103515245 * state + 12345) & 0x7fffffff;
    return state;
  }

  for (var attempt = 0; attempt < 400; attempt++) {
    final ships = <List<int>>[];
    final blocked = <int>{};
    var ok = true;
    for (final length in kBattleshipFleet) {
      var placed = false;
      for (var tryN = 0; tryN < 200; tryN++) {
        final horiz = next() % 2 == 0;
        late final List<int> cells;
        if (horiz) {
          final r = next() % kBattleshipBoardSize;
          final c0 = next() % (kBattleshipBoardSize - length + 1);
          cells = List.generate(length, (i) => r * kBattleshipBoardSize + c0 + i);
        } else {
          final c = next() % kBattleshipBoardSize;
          final r0 = next() % (kBattleshipBoardSize - length + 1);
          cells = List.generate(length, (i) => (r0 + i) * kBattleshipBoardSize + c);
        }
        if (cells.any(blocked.contains)) continue;
        ships.add(cells);
        for (final cell in cells) {
          final r = cell ~/ kBattleshipBoardSize;
          final col = cell % kBattleshipBoardSize;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final nr = r + dr;
              final nc = col + dc;
              if (nr < 0 ||
                  nr >= kBattleshipBoardSize ||
                  nc < 0 ||
                  nc >= kBattleshipBoardSize) {
                continue;
              }
              blocked.add(nr * kBattleshipBoardSize + nc);
            }
          }
        }
        placed = true;
        break;
      }
      if (!placed) {
        ok = false;
        break;
      }
    }
    if (ok && _validatePlacement(ships)) return ships;
  }
  return defaultBattleshipShips();
}

/// После своего выстрела: попадание — сразу ещё один выстрел; промах/конец — ход отдан.
///
/// [shotCell] — клетка, которую послали мы. После промаха бот может сходить
/// в том же ответе, и тогда `lastShot` уже чужой.
bool battleshipKeepAttacking(BattleshipGameView view, {int? shotCell}) {
  if (view.isOver || !view.isMyTurn) return false;
  if (shotCell != null) return view.myHits.contains(shotCell);
  return view.lastShotHit;
}

/// Клетка уже стреляная, в полёте или потоплена — повторный выстрел нельзя.
bool battleshipCellSpent({
  required int cell,
  required Set<int> myShots,
  required Set<int> myHits,
  Set<int> sunkCells = const {},
  int? pendingCell,
}) {
  if (cell < 0 || cell >= kBattleshipCellCount) return true;
  if (pendingCell != null && cell == pendingCell) return true;
  return myShots.contains(cell) ||
      myHits.contains(cell) ||
      sunkCells.contains(cell);
}

/// Финальная метка клетки на поле атаки. Pending — не промах.
enum BattleshipAttackMark { water, pending, miss, hit, sunk }

BattleshipAttackMark battleshipAttackMark({
  required int cell,
  required Set<int> myHits,
  required Set<int> myShots,
  Set<int> opponentSunkCells = const {},
  int? pendingCell,
}) {
  if (opponentSunkCells.contains(cell)) return BattleshipAttackMark.sunk;
  if (myHits.contains(cell)) return BattleshipAttackMark.hit;
  if (pendingCell != null && cell == pendingCell) {
    return BattleshipAttackMark.pending;
  }
  if (myShots.contains(cell)) return BattleshipAttackMark.miss;
  return BattleshipAttackMark.water;
}

String battleshipSunkShipKey(List<int> ship) {
  if (ship.isEmpty) return '';
  final sorted = List<int>.from(ship)..sort();
  return sorted.join(',');
}

/// Объединяет потопленные корабли без дублей (порядок: сначала server).
List<List<int>> mergeBattleshipSunkShips(
  List<List<int>> server,
  List<List<int>> extra,
) {
  if (extra.isEmpty) return server;
  final seen = <String>{};
  final out = <List<int>>[];
  void add(List<int> ship) {
    if (ship.isEmpty) return;
    final key = battleshipSunkShipKey(ship);
    if (key.isEmpty || !seen.add(key)) return;
    out.add(List<int>.from(ship));
  }

  for (final ship in server) {
    add(ship);
  }
  for (final ship in extra) {
    add(ship);
  }
  return out;
}

/// Корабль, который появился в [after] после [before], иначе корабль с [lastShot].
List<int>? battleshipNewlySunkShip({
  required List<List<int>> after,
  required List<List<int>> before,
  int lastShot = -1,
}) {
  final known = <String>{
    for (final ship in before) battleshipSunkShipKey(ship),
  };
  for (final ship in after) {
    if (ship.isEmpty) continue;
    if (!known.contains(battleshipSunkShipKey(ship))) {
      return List<int>.from(ship);
    }
  }
  if (lastShot >= 0) {
    for (final ship in after) {
      if (ship.contains(lastShot)) return List<int>.from(ship);
    }
  }
  return null;
}

/// Локальный монотонный слой выстрелов: не откатывается, пока сервер догоняет.
class BattleshipClientOverlay {
  const BattleshipClientOverlay({
    this.shots = const {},
    this.hits = const {},
    this.sunkShips = const [],
    this.opponentShots = const {},
    this.pendingCell,
  });

  final Set<int> shots;
  final Set<int> hits;
  final List<List<int>> sunkShips;
  final Set<int> opponentShots;
  final int? pendingCell;

  bool get isEmpty =>
      shots.isEmpty &&
      hits.isEmpty &&
      sunkShips.isEmpty &&
      opponentShots.isEmpty &&
      pendingCell == null;

  bool sameAs(BattleshipClientOverlay other) {
    if (pendingCell != other.pendingCell) return false;
    if (shots.length != other.shots.length || !shots.containsAll(other.shots)) {
      return false;
    }
    if (hits.length != other.hits.length || !hits.containsAll(other.hits)) {
      return false;
    }
    if (opponentShots.length != other.opponentShots.length ||
        !opponentShots.containsAll(other.opponentShots)) {
      return false;
    }
    if (sunkShips.length != other.sunkShips.length) return false;
    final keys = <String>{
      for (final ship in sunkShips) battleshipSunkShipKey(ship),
    };
    for (final ship in other.sunkShips) {
      if (!keys.contains(battleshipSunkShipKey(ship))) return false;
    }
    return true;
  }

  BattleshipClientOverlay beginPending(int cell) {
    if (shots.contains(cell) || hits.contains(cell)) return this;
    if (pendingCell == cell) return this;
    return BattleshipClientOverlay(
      shots: shots,
      hits: hits,
      sunkShips: sunkShips,
      opponentShots: opponentShots,
      pendingCell: cell,
    );
  }

  BattleshipClientOverlay clearPending() {
    if (pendingCell == null) return this;
    return BattleshipClientOverlay(
      shots: shots,
      hits: hits,
      sunkShips: sunkShips,
      opponentShots: opponentShots,
    );
  }

  BattleshipClientOverlay resolvePending({
    required int cell,
    required bool hit,
    List<int>? sunkShip,
  }) {
    return BattleshipClientOverlay(
      shots: {...shots, cell},
      hits: hit ? {...hits, cell} : hits,
      sunkShips: sunkShip == null || sunkShip.isEmpty
          ? sunkShips
          : mergeBattleshipSunkShips(sunkShips, [sunkShip]),
      opponentShots: opponentShots,
      pendingCell: pendingCell == cell ? null : pendingCell,
    );
  }

  BattleshipClientOverlay absorbServer(BattleshipGameView view) {
    final nextPending = pendingCell != null &&
            (view.myShots.contains(pendingCell) ||
                view.myHits.contains(pendingCell))
        ? null
        : pendingCell;
    return BattleshipClientOverlay(
      shots: {...shots, ...view.myShots},
      hits: {...hits, ...view.myHits},
      sunkShips: mergeBattleshipSunkShips(sunkShips, view.opponentSunkShips),
      opponentShots: {...opponentShots, ...view.opponentShots},
      pendingCell: nextPending,
    );
  }
}

/// Сервер + ответ `shoot()` + оверлей. Лишние локальные выстрелы не откатываются.
BattleshipGameView resolveBattleshipClientView({
  required BattleshipGameView server,
  BattleshipGameView? optimistic,
  required BattleshipClientOverlay overlay,
}) {
  final BattleshipGameView base;
  if (optimistic != null &&
      optimistic.id == server.id &&
      (optimistic.myShots.length > server.myShots.length ||
          optimistic.myHits.length > server.myHits.length ||
          optimistic.opponentShots.length > server.opponentShots.length ||
          optimistic.opponentSunkShips.length > server.opponentSunkShips.length ||
          (optimistic.isOver && !server.isOver))) {
    base = optimistic;
  } else {
    base = server;
  }
  final shots = <int>{...base.myShots, ...overlay.shots};
  final hits = <int>{...base.myHits, ...overlay.hits};
  final oppShots = <int>{...base.opponentShots, ...overlay.opponentShots};
  final sunk = mergeBattleshipSunkShips(
    base.opponentSunkShips,
    overlay.sunkShips,
  );
  if (shots.length == base.myShots.length &&
      hits.length == base.myHits.length &&
      oppShots.length == base.opponentShots.length &&
      sunk.length == base.opponentSunkShips.length) {
    return base;
  }
  return base.copyWith(
    myShots: shots.toList(),
    myHits: hits.toList(),
    opponentShots: oppShots.toList(),
    opponentSunkShips: sunk,
  );
}

/// Сторона клетки 10×10, чтобы доска целиком влезла в [maxWidth]×[maxHeight].
double fitBattleshipCellSize({
  required double maxWidth,
  required double maxHeight,
  double gap = 2,
  double minCell = 11,
  double maxCell = 40,
}) {
  final side = maxWidth < maxHeight ? maxWidth : maxHeight;
  if (side <= 0) return minCell;
  return ((side - gap * (kBattleshipBoardSize - 1)) / kBattleshipBoardSize)
      .clamp(minCell, maxCell);
}

/// Дефолтная валидная расстановка (как на сервере при таймауте setup).
List<List<int>> defaultBattleshipShips() {
  return [
    [0, 1, 2, 3],
    [5, 6, 7],
    [20, 21, 22],
    [40, 41],
    [43, 44],
    [46, 47],
    [60],
    [62],
    [64],
    [66],
  ];
}
