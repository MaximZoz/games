import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';

BattleshipGameView _view({
  String id = 'g1',
  String status = 'active',
  List<int> myShots = const [],
  List<int> myHits = const [],
  List<int> opponentShots = const [],
  List<List<int>> opponentSunkShips = const [],
  bool isMyTurn = true,
  String turn = 'me',
  int lastShot = -1,
  bool lastShotHit = false,
}) {
  return BattleshipGameView(
    id: id,
    status: status,
    phase: 'battle',
    lobbyId: 'l',
    p1UserId: 'me',
    p2UserId: 'op',
    p1Ready: true,
    p2Ready: true,
    myShips: const [],
    myShots: myShots,
    myHits: myHits,
    opponentShots: opponentShots,
    opponentShipsHit: const [],
    opponentSunkShips: opponentSunkShips,
    opponentShips: const [],
    isMyTurn: isMyTurn,
    turn: turn,
    turnTimeSec: 30,
    turnDeadline: 0,
    setupDeadline: 0,
    stakeBronze: 2,
    lastShot: lastShot,
    lastShotHit: lastShotHit,
  );
}

void main() {
  group('fitBattleshipCellSize', () {
    test('на узком телефоне 10×10 влезает по высоте', () {
      const maxW = 360.0;
      const maxH = 220.0;
      final cell = fitBattleshipCellSize(maxWidth: maxW, maxHeight: maxH);
      const gap = 2.0;
      final board =
          cell * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
      expect(board, lessThanOrEqualTo(maxH + 0.01));
      expect(board, lessThanOrEqualTo(maxW + 0.01));
      expect(cell, greaterThanOrEqualTo(11));
      expect(cell, lessThan(28));
    });

    test('на очень коротком экране клетка сжимается ниже 16', () {
      final cell = fitBattleshipCellSize(
        maxWidth: 280,
        maxHeight: 140,
        minCell: 11,
      );
      const gap = 2.0;
      final board =
          cell * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
      expect(board, lessThanOrEqualTo(140.01));
      expect(cell, greaterThanOrEqualTo(11));
      expect(cell, lessThan(16));
    });

    test('после двух рядов кнопок 10×10 всё ещё влезает', () {
      const available = 400.0;
      const buttons = 120.0;
      final cell = fitBattleshipCellSize(
        maxWidth: 360,
        maxHeight: available - buttons,
        minCell: 11,
      );
      const gap = 2.0;
      final board =
          cell * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
      expect(board, lessThanOrEqualTo(available - buttons + 0.01));
      expect(cell, greaterThanOrEqualTo(11));
    });

    test('не раздувает клетку выше maxCell', () {
      final cell = fitBattleshipCellSize(
        maxWidth: 800,
        maxHeight: 800,
        maxCell: 40,
      );
      expect(cell, 40);
    });

    test('после двух строк кнопок 10×10 влезает в остаток Android', () {
      // 640 логических: appbar, status, nav, соперник, фаза, таймер, padding.
      const boardH = 640.0 - 56 - 24 - 48 - 72 - 16 - 40 - 12 - 8 - 112;
      final cell = fitBattleshipCellSize(
        maxWidth: 344,
        maxHeight: boardH,
        maxCell: 36,
      );
      const gap = 2.0;
      final side =
          cell * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
      expect(side, lessThanOrEqualTo(boardH + 0.01));
      expect(cell, greaterThanOrEqualTo(11));
    });
  });

  group('defaultBattleshipShips', () {
    test('валидна и совпадает с серверным дефолтом', () {
      final ships = defaultBattleshipShips();
      expect(validateBattleshipShips(ships), isTrue);
      expect(ships.first, [0, 1, 2, 3]);
      expect(ships.length, kBattleshipFleet.length);
    });
  });

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

  group('moveShipFromGrabAllowTouch', () {
    test('ставит корабль даже при касании', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 1);
      final other = ships.firstWhere((s) => s.length >= 3).first;
      expect(tryMoveShipFromGrab(ships, idx, 0, other), isNull);
      final next = moveShipFromGrabAllowTouch(ships, idx, 0, other);
      expect(next, isNotNull);
      expect(next![idx], [other]);
      expect(validateBattleshipShips(next), isFalse);
      expect(conflictingShipIndices(next), contains(idx));
    });
  });

  group('conflictingShipIndices', () {
    test('пустой при валидной расстановке', () {
      final ships = generateRandomBattleshipShips(42);
      expect(conflictingShipIndices(ships), isEmpty);
    });
  });

  group('tryMoveShipFromGrab', () {
    test('переносит корабль так, что схваченная клетка попадает в drop', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 1);
      expect(idx, greaterThanOrEqualTo(0));
      int? free;
      for (var cell = 0; cell < kBattleshipCellCount; cell++) {
        final trial = tryMoveShipFromGrab(ships, idx, 0, cell);
        if (trial != null && trial[idx].first != ships[idx].first) {
          free = cell;
          break;
        }
      }
      expect(free, isNotNull);
      final next = tryMoveShipFromGrab(ships, idx, 0, free!);
      expect(next, isNotNull);
      expect(next![idx], [free]);
      expect(validateBattleshipShips(next), isTrue);
    });

    test('отклоняет касание при переносе', () {
      final ships = generateRandomBattleshipShips(42);
      final idx = ships.indexWhere((s) => s.length == 1);
      final other = ships.firstWhere((s) => s.length >= 3).first;
      // Клетка рядом с чужим кораблём — касание.
      expect(tryMoveShipFromGrab(ships, idx, 0, other), isNull);
    });

    test('сдвиг за середину сохраняет ориентацию', () {
      // Горизонтальная четвёрка; хватаем 2-ю клетку (offset=1), кладём на 61 → head=60.
      final ships = <List<int>>[
        [0, 1, 2, 3],
        [20, 21, 22],
        [40, 41, 42],
        [60, 61],
        [63, 64],
        [66, 67],
        [80],
        [82],
        [84],
        [86],
      ];
      // Проверим валидность; если fallback невалиден — возьмём random.
      final base = validateBattleshipShips(ships)
          ? ships
          : generateRandomBattleshipShips(99);
      final idx = base.indexWhere((s) => s.length == 4 && isShipHorizontal(s));
      if (idx < 0) return;
      const grabOffset = 1;
      // Ищем drop, где tryMove даёт новый head.
      for (var cell = 0; cell < kBattleshipCellCount; cell++) {
        final next = tryMoveShipFromGrab(base, idx, grabOffset, cell);
        if (next == null) continue;
        expect(next[idx][grabOffset], cell);
        expect(isShipHorizontal(next[idx]), isTrue);
        break;
      }
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

  group('battleshipCellSpent', () {
    test('свободная клетка доступна', () {
      expect(
        battleshipCellSpent(
          cell: 0,
          myShots: const {},
          myHits: const {},
        ),
        isFalse,
      );
    });

    test('повтор, потоп и pending запрещены', () {
      expect(
        battleshipCellSpent(
          cell: 3,
          myShots: const {3},
          myHits: const {},
        ),
        isTrue,
      );
      expect(
        battleshipCellSpent(
          cell: 5,
          myShots: const {},
          myHits: const {5},
        ),
        isTrue,
      );
      expect(
        battleshipCellSpent(
          cell: 8,
          myShots: const {},
          myHits: const {},
          sunkCells: const {8},
        ),
        isTrue,
      );
      expect(
        battleshipCellSpent(
          cell: 11,
          myShots: const {},
          myHits: const {},
          pendingCell: 11,
        ),
        isTrue,
      );
    });

    test('вне поля нельзя', () {
      expect(
        battleshipCellSpent(
          cell: -1,
          myShots: const {},
          myHits: const {},
        ),
        isTrue,
      );
      expect(
        battleshipCellSpent(
          cell: kBattleshipCellCount,
          myShots: const {},
          myHits: const {},
        ),
        isTrue,
      );
    });
  });

  group('battleshipAttackMark', () {
    test('pending — не промах и не попадание', () {
      expect(
        battleshipAttackMark(
          cell: 7,
          myHits: const {},
          myShots: const {},
          pendingCell: 7,
        ),
        BattleshipAttackMark.pending,
      );
      expect(
        battleshipAttackMark(
          cell: 7,
          myHits: const {},
          myShots: const {3},
          pendingCell: 7,
        ),
        isNot(BattleshipAttackMark.miss),
      );
    });

    test('hit и sunk важнее pending', () {
      expect(
        battleshipAttackMark(
          cell: 4,
          myHits: const {4},
          myShots: const {4},
          pendingCell: 4,
        ),
        BattleshipAttackMark.hit,
      );
      expect(
        battleshipAttackMark(
          cell: 4,
          myHits: const {4},
          myShots: const {4},
          opponentSunkCells: const {4},
          pendingCell: 4,
        ),
        BattleshipAttackMark.sunk,
      );
    });

    test('выстрел без попадания — miss', () {
      expect(
        battleshipAttackMark(
          cell: 2,
          myHits: const {},
          myShots: const {2},
        ),
        BattleshipAttackMark.miss,
      );
    });
  });

  group('BattleshipClientOverlay', () {
    test('resolvePending сразу ставит финальную метку и не откатывается', () {
      var overlay = const BattleshipClientOverlay().beginPending(11);
      expect(overlay.pendingCell, 11);
      expect(
        battleshipAttackMark(
          cell: 11,
          myHits: overlay.hits,
          myShots: overlay.shots,
          pendingCell: overlay.pendingCell,
        ),
        BattleshipAttackMark.pending,
      );

      overlay = overlay.resolvePending(cell: 11, hit: true);
      expect(overlay.pendingCell, isNull);
      expect(overlay.shots, contains(11));
      expect(overlay.hits, contains(11));
      expect(
        battleshipAttackMark(
          cell: 11,
          myHits: overlay.hits,
          myShots: overlay.shots,
          pendingCell: overlay.pendingCell,
        ),
        BattleshipAttackMark.hit,
      );

      final stale = _view(myShots: const [], myHits: const []);
      overlay = overlay.absorbServer(stale);
      expect(overlay.shots, contains(11));
      expect(overlay.hits, contains(11));
    });

    test('потопленный корабль мержится без дубля', () {
      const ship = [0, 1, 2];
      var overlay = const BattleshipClientOverlay().resolvePending(
        cell: 1,
        hit: true,
        sunkShip: ship,
      );
      overlay = overlay.absorbServer(
        _view(
          myShots: const [1],
          myHits: const [1],
          opponentSunkShips: const [ship],
        ),
      );
      expect(overlay.sunkShips.length, 1);
      expect(overlay.sunkShips.first, ship);
    });
  });

  group('resolveBattleshipClientView', () {
    test('берёт ход и выстрелы из ответа shoot, пока refetch старый', () {
      final server = _view(
        myShots: const [0],
        isMyTurn: true,
        turn: 'me',
      );
      final optimistic = _view(
        myShots: const [0, 5],
        myHits: const [5],
        isMyTurn: false,
        turn: 'op',
        lastShot: 5,
        lastShotHit: true,
      );
      final overlay =
          const BattleshipClientOverlay().resolvePending(cell: 5, hit: true);
      final view = resolveBattleshipClientView(
        server: server,
        optimistic: optimistic,
        overlay: overlay,
      );
      expect(view.myShots, containsAll([0, 5]));
      expect(view.myHits, contains(5));
      expect(view.isMyTurn, isFalse);
      expect(view.turn, 'op');
    });

    test('чужой id optimistic не подмешивается', () {
      final server = _view(id: 'a', myShots: const [1]);
      final optimistic = _view(id: 'b', myShots: const [1, 2], isMyTurn: false);
      final view = resolveBattleshipClientView(
        server: server,
        optimistic: optimistic,
        overlay: const BattleshipClientOverlay(),
      );
      expect(view.id, 'a');
      expect(view.myShots, [1]);
      expect(view.isMyTurn, isTrue);
    });
  });

  group('mergeBattleshipSunkShips', () {
    test('склеивает и убирает перестановки клеток', () {
      final merged = mergeBattleshipSunkShips(
        const [
          [3, 2, 1],
        ],
        const [
          [1, 2, 3],
          [10, 11],
        ],
      );
      expect(merged.length, 2);
      expect(merged.last, [10, 11]);
    });
  });

  group('battleshipKeepAttacking', () {
    test('попадание — сразу ещё один выстрел', () {
      final view = _view(
        myShots: const [5],
        myHits: const [5],
        isMyTurn: true,
        lastShot: 5,
        lastShotHit: true,
      );
      expect(battleshipKeepAttacking(view, shotCell: 5), isTrue);
    });

    test('промах — ход отдан, даже если lastShot уже чужой', () {
      final afterBot = _view(
        myShots: const [5],
        myHits: const [],
        opponentShots: const [11],
        isMyTurn: false,
        turn: 'op',
        lastShot: 11,
        lastShotHit: true,
      );
      expect(battleshipKeepAttacking(afterBot, shotCell: 5), isFalse);
    });

    test('промах бота в том же ответе — наш ход, но не combo', () {
      final view = _view(
        myShots: const [5],
        myHits: const [],
        opponentShots: const [11],
        isMyTurn: true,
        lastShot: 11,
        lastShotHit: false,
      );
      expect(battleshipKeepAttacking(view, shotCell: 5), isFalse);
      expect(battleshipKeepAttacking(view), isFalse);
    });
  });

  group('battleshipBoardAfterLocalShot', () {
    test('промах в PvP — отпускаем поле после пульса', () {
      expect(
        battleshipBoardAfterLocalShot(keepAttacking: false, vsBot: false),
        isNull,
      );
    });

    test('попадание или бот — поле соперника остаётся', () {
      expect(
        battleshipBoardAfterLocalShot(keepAttacking: true, vsBot: false),
        isFalse,
      );
      expect(
        battleshipBoardAfterLocalShot(keepAttacking: false, vsBot: true),
        isFalse,
      );
    });
  });

  group('battleshipFleetSunkSlots', () {
    test('пустой залп — весь флот на плаву', () {
      final slots = battleshipFleetSunkSlots(const []);
      expect(slots, List<bool>.filled(kBattleshipFleet.length, false));
      expect(battleshipFleetSunkCount(const []), 0);
      expect(battleshipFleetRemainingCount(const []), 10);
    });

    test('помечает слоты 4 и 1, лишние единицы не добавляют корабль', () {
      final slots = battleshipFleetSunkSlots(const [
        [0, 1, 2, 3],
        [10],
        [12],
        [14],
        [16],
        [18],
      ]);
      expect(slots, [
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
      ]);
      expect(
        battleshipFleetSunkCount(const [
          [0, 1, 2, 3],
          [10],
          [12],
          [14],
          [16],
          [18],
        ]),
        5,
      );
      expect(
        battleshipFleetRemainingCount(const [
          [0, 1, 2, 3],
          [10],
          [12],
          [14],
          [16],
          [18],
        ]),
        5,
      );
    });

    test('два трёхпалубных занимают оба слота тройки', () {
      final slots = battleshipFleetSunkSlots(const [
        [1, 2, 3],
        [11, 12, 13],
      ]);
      expect(slots[1], isTrue);
      expect(slots[2], isTrue);
      expect(slots.where((s) => s).length, 2);
    });
  });

  group('battleshipNewlySunkShip', () {
    test('возвращает новый корабль после выстрела', () {
      expect(
        battleshipNewlySunkShip(
          after: const [
            [4, 5],
            [8],
          ],
          before: const [
            [4, 5],
          ],
          lastShot: 8,
        ),
        [8],
      );
    });
  });
}
