import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';

void main() {
  group('validateBattleshipShips', () {
    test('принимает валидную расстановку', () {
      final ships = generateRandomBattleshipShips(42);
      expect(validateBattleshipShips(ships), isTrue);
      expect(ships.length, kBattleshipFleet.length);
      final lengths = ships.map((s) => s.length).toList()..sort();
      final expected = List<int>.from(kBattleshipFleet)..sort();
      expect(lengths, expected);
    });

    test('отклоняет пустой список', () {
      expect(validateBattleshipShips(const []), isFalse);
    });

    test('отклоняет пересечение кораблей', () {
      final ships = generateRandomBattleshipShips(42);
      // Дублируем первую клетку второго корабля в первом.
      ships[0] = [...ships[0]]..[0] = ships[1].first;
      expect(validateBattleshipShips(ships), isFalse);
    });

    test('отклоняет касание по диагонали', () {
      // Два одноклеточных корабля по диагонали + остальной валидный флот
      // собран вручную без касаний.
      final ships = <List<int>>[
        [0, 1, 2, 3], // row 0
        [5, 6, 7], // row 0
        [30, 31, 32], // row 3
        [50, 51], // row 5
        [53, 54], // row 5
        [56, 57], // row 5
        [70], // row 7
        [72],
        [74],
        [16], // касается [5,6,7] по диагонали (клетка 5 → 16)
      ];
      expect(validateBattleshipShips(ships), isFalse);
    });
  });

  group('generateRandomBattleshipShips', () {
    test('детерминирован при одинаковом seed', () {
      final a = generateRandomBattleshipShips(7);
      final b = generateRandomBattleshipShips(7);
      expect(a, b);
      expect(validateBattleshipShips(a), isTrue);
    });

    test('разные seed дают валидные флоты', () {
      for (final seed in [1, 99, 12345, 999999]) {
        final ships = generateRandomBattleshipShips(seed);
        expect(validateBattleshipShips(ships), isTrue, reason: 'seed=$seed');
      }
    });
  });

  group('rotateShip', () {
    test('горизонтальный → вертикальный', () {
      final rotated = rotateShip([0, 1, 2, 3]);
      expect(rotated, [0, 10, 20, 30]);
    });

    test('вертикальный → горизонтальный', () {
      final rotated = rotateShip([0, 10, 20, 30]);
      expect(rotated, [0, 1, 2, 3]);
    });

    test('одиночная клетка без изменений', () {
      expect(rotateShip([55]), [55]);
    });

    test('не влезает в поле → null', () {
      // Горизонтальный у нижнего края: вертикальный вниз выйдет за поле.
      expect(rotateShip([90, 91, 92]), isNull);
    });
  });

  group('tryPlaceShip', () {
    test('переносит одноклеточный корабль на свободное место', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 1);
      expect(idx, greaterThanOrEqualTo(0));

      // Ищем свободную клетку, не соседнюю с другими кораблями.
      int? free;
      final occupied = <int>{for (final s in ships) ...s};
      for (var cell = 0; cell < kBattleshipCellCount; cell++) {
        if (occupied.contains(cell)) continue;
        final trial = tryPlaceShip(ships, idx, cell, horizontal: true);
        if (trial != null) {
          free = cell;
          break;
        }
      }
      expect(free, isNotNull);
      final next = tryPlaceShip(ships, idx, free!, horizontal: true);
      expect(next, isNotNull);
      expect(next![idx], [free]);
      expect(validateBattleshipShips(next), isTrue);
    });

    test('отклоняет выход за край', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 4);
      expect(tryPlaceShip(ships, idx, 8, horizontal: true), isNull);
    });

    test('отклоняет наложение', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 4);
      final other = ships.firstWhere((s) => s.length == 3).first;
      expect(tryPlaceShip(ships, idx, other, horizontal: true), isNull);
    });

    test('вертикальное размещение одноклеточного', () {
      final ships = generateRandomBattleshipShips(7);
      final idx = ships.indexWhere((s) => s.length == 1);
      int? free;
      for (var cell = 0; cell < kBattleshipCellCount; cell++) {
        final trial = tryPlaceShip(ships, idx, cell, horizontal: false);
        if (trial != null) {
          free = cell;
          break;
        }
      }
      expect(free, isNotNull);
      final next = tryPlaceShip(ships, idx, free!, horizontal: false);
      expect(next, isNotNull);
      expect(validateBattleshipShips(next!), isTrue);
    });
  });
}
