import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';

void main() {
  group('battleship offline helpers', () {
    test('hit / sunk / bot neighbors', () {
      final ships = defaultBattleshipShips();
      expect(battleshipIsHit(ships, 0), isTrue);
      expect(battleshipIsHit(ships, 8), isFalse);

      final shots = <int>[0, 1, 2, 3];
      expect(battleshipAllSunk(ships, shots), isFalse);
      expect(battleshipCollectSunkShips(ships, shots).length, 1);
      expect(battleshipCollectHitCells(ships, [...shots, 8]), [0, 1, 2, 3]);

      final neighbors = battleshipBotNeighborCandidates(ships, [0]);
      expect(neighbors, containsAll([1, 10]));
      expect(neighbors, isNot(contains(0)));
    });

    test('bot pick prefers neighbors of hits', () {
      final ships = defaultBattleshipShips();
      final cell = battleshipBotPickShot(ships, [0], Random(1));
      expect([1, 10], contains(cell));
    });
  });

  group('OfflineBattleshipSession', () {
    test('setup → battle → shoot → forfeit/rematch', () async {
      final session = OfflineBattleshipSession.create(
        humanUserId: 'u1',
        gameId: 'offline:battleship:test-1',
      );
      addTearDown(session.dispose);

      expect(session.view.isSetup, isTrue);
      expect(session.view.stakeBronze, 0);
      expect(session.view.hasBotOpponent, isTrue);

      final ships = generateRandomBattleshipShips(7);
      final afterPlace = await session.placeShips(ships);
      expect(afterPlace.isBattle, isTrue);
      expect(afterPlace.p1Ready && afterPlace.p2Ready, isTrue);

      // Дождёмся своего хода, если первым ходит бот.
      for (var i = 0; i < 40 && !session.view.isMyTurn; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (session.view.isMyTurn && !session.view.isOver) {
        final free = List.generate(100, (i) => i)
            .where((c) => !session.view.myShots.contains(c))
            .first;
        await session.shoot(free);
        expect(session.view.myShots, contains(free));
      }

      session.restart();
      expect(session.view.isSetup, isTrue);
      expect(session.view.myShots, isEmpty);
    });

    test('после промаха бот ждёт паузу', () async {
      final session = OfflineBattleshipSession.create(
        humanUserId: 'u1',
        gameId: 'offline:battleship:test-delay',
      );
      addTearDown(session.dispose);

      await session.placeShips(generateRandomBattleshipShips(3));
      for (var i = 0; i < 50 && !session.view.isMyTurn; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      if (!session.view.isMyTurn || session.view.isOver) {
        return;
      }
      var missed = false;
      for (var cell = 0; cell < 100; cell++) {
        if (!session.view.isMyTurn || session.view.isOver) break;
        if (session.view.myShots.contains(cell)) continue;
        await session.shoot(cell);
        if (!session.view.isMyTurn) {
          missed = true;
          break;
        }
      }
      if (!missed || session.view.isOver) return;
      final botShotsRightAfter = session.view.opponentShots.length;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(session.view.opponentShots.length, botShotsRightAfter);
      await Future<void>.delayed(
        OfflineBattleshipSession.botDelay + const Duration(milliseconds: 250),
      );
      expect(
        session.view.opponentShots.length,
        greaterThan(botShotsRightAfter),
      );
    });
  });
}
