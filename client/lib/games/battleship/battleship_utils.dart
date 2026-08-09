/// Утилиты «Морского боя» (клиент).
/// Восстановлено по чатам Cursor (март 2026) и контракту сервера PROD v276.
library;

const int kBattleshipBoardSize = 10;
const int kBattleshipCellCount = kBattleshipBoardSize * kBattleshipBoardSize;

/// Классический русский флот.
const List<int> kBattleshipFleet = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

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
  if (headCell < 0 || headCell >= kBattleshipCellCount) return null;
  final len = ships[shipIndex].length;
  if (len <= 0 || len > 4) return null;
  final hr = headCell ~/ kBattleshipBoardSize;
  final hc = headCell % kBattleshipBoardSize;
  final cells = <int>[];
  for (var i = 0; i < len; i++) {
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
  final next = ships.map((s) => List<int>.from(s)).toList();
  next[shipIndex] = cells;
  if (!_validatePlacement(next)) return null;
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
  // Fallback
  return [
    [0, 1, 2, 3],
    [5, 6, 7],
    [9, 19, 29],
    [20, 21],
    [23, 24],
    [26, 27],
    [40],
    [42],
    [44],
    [46],
  ];
}
