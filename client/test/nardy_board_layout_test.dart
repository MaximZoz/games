import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_board_layout.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

NardyGameView _viewFrom(NardyEngine engine, {int myIndex = 0}) {
  final myTurn = !engine.isOver && engine.turn == myIndex;
  return NardyGameView(
    id: 'g',
    lobbyId: '',
    gameMode: engine.mode,
    board: engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: engine.dice,
    rolled: engine.rolled,
    turn: engine.turn,
    turnNo: engine.turnNo,
    seq: engine.seq,
    headMoved: engine.headMoved,
    players: const [],
    playerIds: const ['me', 'bot:nardy'],
    legalMoves: myTurn ? engine.legalMoves() : const [],
    myIndex: myIndex,
    isMyTurn: myTurn,
    needsRoll: myTurn && engine.dice.isEmpty && !engine.canUndo,
    canUndo: myTurn && engine.canUndo,
    turnComplete: myTurn && engine.turnComplete,
    currentTurn: myTurn ? engine.currentTurn : const [],
    lastTurn: engine.lastTurn,
    lastTurnSeat: engine.lastTurnSeat,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: 0,
    isOver: engine.isOver,
    winnerIndex: engine.winner,
    winnerUserId: '',
    winKind: engine.winKind,
  );
}

void main() {
  group('раскладка коротких нард на экране', () {
    final engine = NardyEngine.newGame(nardyModeShort);
    final view = _viewFrom(engine);

    int atColumn(List<int> row, int column) =>
        view.myCountAt(row[column]);

    test('слева сверху 2, справа сверху 5', () {
      expect(atColumn(NardyBoardLayout.topRow, 0), 2);
      expect(atColumn(NardyBoardLayout.topRow, 11), 5);
    });

    test('снизу справа 3, снизу слева 5', () {
      // Нижний ряд слева направо: 23..18 | 17..12.
      expect(atColumn(NardyBoardLayout.bottomRow, 7), 3);
      expect(atColumn(NardyBoardLayout.bottomRow, 5), 5);
    });

    test('дом игрока — левый нижний квадрант', () {
      for (var column = 0; column < NardyBoardLayout.quadrant; column++) {
        expect(
          NardyBoardLayout.isHome(NardyBoardLayout.bottomRow[column]),
          isTrue,
        );
      }
      for (var column = 0; column < NardyBoardLayout.quadrant; column++) {
        expect(NardyBoardLayout.isHome(NardyBoardLayout.topRow[column]), isFalse);
      }
    });

    test('у соперника расстановка зеркальная по вертикали', () {
      // Слева снизу 2 и справа снизу 5 — зеркало моей верхней половины.
      expect(view.opponentCountAt(NardyBoardLayout.bottomRow[0]), 2);
      expect(view.opponentCountAt(NardyBoardLayout.bottomRow[11]), 5);
      // Сверху справа 3 и сверху слева 5 — зеркало моей нижней половины.
      expect(view.opponentCountAt(NardyBoardLayout.topRow[7]), 3);
      expect(view.opponentCountAt(NardyBoardLayout.topRow[5]), 5);
    });

    test('свои и чужие шашки не стоят на одном пункте', () {
      for (final track in NardyBoardLayout.allTracks) {
        final mine = view.myCountAt(track);
        final theirs = view.opponentCountAt(track);
        expect(mine == 0 || theirs == 0, isTrue,
            reason: 'пункт $track: свои $mine, чужие $theirs');
      }
    });

    test('на доске ровно по 15 шашек с каждой стороны', () {
      var mine = 0;
      var theirs = 0;
      for (final track in NardyBoardLayout.allTracks) {
        mine += view.myCountAt(track);
        theirs += view.opponentCountAt(track);
      }
      expect(mine, nardyCheckers);
      expect(theirs, nardyCheckers);
    });

    test('каждый пункт лежит ровно в одном ряду', () {
      final all = NardyBoardLayout.allTracks;
      expect(all.length, nardyPoints);
      expect(all.toSet().length, nardyPoints);
    });
  });

  group('геометрия доски', () {
    final geometry = NardyBoardGeometry(
      size: const Size(700, 480),
      showBar: true,
    );

    test('пункты не пересекаются и лежат внутри доски', () {
      final rects = [
        for (final track in NardyBoardLayout.allTracks)
          geometry.trackRect(track),
      ];
      for (final rect in rects) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(700));
        expect(rect.bottom, lessThanOrEqualTo(480));
      }
      // Верхний и нижний ряды не накладываются.
      final top = geometry.trackRect(NardyBoardLayout.topRow.first);
      final bottom = geometry.trackRect(NardyBoardLayout.bottomRow.first);
      expect(top.bottom, lessThanOrEqualTo(bottom.top + 0.01));
    });

    test('касание попадает в свой пункт', () {
      for (final track in NardyBoardLayout.allTracks) {
        final rect = geometry.trackRect(track);
        expect(geometry.trackAt(rect.center), track);
      }
    });

    test('зона снятия и бар не пересекаются с пунктами', () {
      final tray = geometry.trayRect;
      for (final track in NardyBoardLayout.allTracks) {
        expect(geometry.trackRect(track).overlaps(tray), isFalse);
      }
      expect(geometry.barRect.width, greaterThan(0));
    });

    test('шашки в стопке не выходят за пункт', () {
      const track = 3;
      final rect = geometry.trackRect(track);
      for (var i = 0; i < 5; i++) {
        final center = geometry.checkerCenter(track, i, 5);
        expect(center.dy, greaterThanOrEqualTo(rect.top));
        expect(center.dy, lessThanOrEqualTo(rect.bottom));
      }
    });
  });

  group('высокая стопка', () {
    /// Экраны от узкого телефона до планшета.
    final geometries = [
      NardyBoardGeometry(size: const Size(330, 232), showBar: true),
      NardyBoardGeometry(size: const Size(520, 366), showBar: false),
      NardyBoardGeometry(size: const Size(900, 634), showBar: true),
    ];

    for (final geometry in geometries) {
      final label = '${geometry.size.width.toInt()}x'
          '${geometry.size.height.toInt()}';

      test('$label: видны все шашки, включая шестую', () {
        for (final count in [2, 5, 6, 8, 10, 15]) {
          final centers = [
            for (var i = 0; i < count; i++)
              geometry.checkerCenter(3, i, count).dy,
          ];
          // Ни одна шашка не прячется за другой — стопку можно пересчитать.
          expect(centers.toSet(), hasLength(count),
              reason: '$label, стопка $count: шашки слиплись');
          final step = geometry.stackStep(count);
          expect(step, greaterThan(0),
              reason: '$label, стопка $count: нулевой шаг');
        }
      });

      test('$label: стопка любой высоты помещается в пункт', () {
        for (final count in [2, 6, 10, 15]) {
          final rect = geometry.trackRect(3);
          final diameter = geometry.stackCheckerSize(count);
          for (var i = 0; i < count; i++) {
            final center = geometry.checkerCenter(3, i, count);
            expect(center.dy - diameter / 2, greaterThanOrEqualTo(rect.top - 1),
                reason: '$label, стопка $count: шашка $i вылезла сверху');
            expect(center.dy + diameter / 2, lessThanOrEqualTo(rect.bottom + 1),
                reason: '$label, стопка $count: шашка $i вылезла снизу');
          }
        }
      });

      test('$label: чем выше стопка, тем плотнее и мельче шашки', () {
        expect(geometry.stackStep(15),
            lessThanOrEqualTo(geometry.stackStep(6)));
        expect(geometry.stackCheckerSize(15),
            lessThanOrEqualTo(geometry.stackCheckerSize(6)));
        // Низкая стопка рисуется шашками обычного размера.
        expect(geometry.stackCheckerSize(2), geometry.checkerSize);
      });
    }

    test('нижний ряд наращивает стопку вверх, верхний — вниз', () {
      final geometry =
          NardyBoardGeometry(size: const Size(640, 450), showBar: true);
      final top = NardyBoardLayout.topRow.first;
      final bottom = NardyBoardLayout.bottomRow.first;
      expect(geometry.checkerCenter(top, 5, 6).dy,
          greaterThan(geometry.checkerCenter(top, 0, 6).dy));
      expect(geometry.checkerCenter(bottom, 5, 6).dy,
          lessThan(geometry.checkerCenter(bottom, 0, 6).dy));
    });
  });

  test('доска вписывается в экран с сохранением пропорций', () {
    final wide = nardyFitBoard(const Size(1000, 300));
    expect(wide.height, closeTo(300, 0.01));
    expect(wide.width / wide.height, closeTo(kNardyBoardAspect, 0.01));

    final tall = nardyFitBoard(const Size(400, 900));
    expect(tall.width, closeTo(400, 0.01));
    expect(tall.width / tall.height, closeTo(kNardyBoardAspect, 0.01));
  });

  group('трекер шашек', () {
    test('сходившая шашка сохраняет свой номер', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(5, 3);
      final tracker = NardyCheckerTracker();
      final before = tracker.spotsFor(_viewFrom(engine), 0);
      final headIds = {
        for (final spot in before)
          if (spot.track == 0) spot.id,
      };
      expect(headIds.length, nardyCheckers);

      engine.applyMove(0, const NardyMove(0, 5));
      final after = tracker.spotsFor(_viewFrom(engine), 0);
      final moved = after.where((s) => s.track == 5).toList();
      expect(moved, hasLength(1));
      // Уехавшая шашка — одна из тех, что стояли на голове.
      expect(headIds.contains(moved.first.id), isTrue);
      // Остальные остались на голове со своими номерами.
      final stillHead = {
        for (final spot in after)
          if (spot.track == 0) spot.id,
      };
      expect(stillHead.length, nardyCheckers - 1);
      expect(stillHead.union({moved.first.id}), headIds);
    });

    test('номера уникальны и покрывают все шашки', () {
      final engine = NardyEngine.newGame(nardyModeShort);
      final tracker = NardyCheckerTracker();
      for (final seat in [0, 1]) {
        final spots = tracker.spotsFor(_viewFrom(engine), seat);
        expect(spots, hasLength(nardyCheckers));
        expect(spots.map((s) => s.id).toSet(), hasLength(nardyCheckers));
      }
    });
  });

  group('отмена хода', () {
    test('возвращает шашку и кубик', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(6, 2);
      final boardBefore = engine.board;
      expect(engine.applyMove(0, const NardyMove(0, 6)), isTrue);
      expect(engine.canUndo, isTrue);
      expect(engine.currentTurn.single.from, 0);
      expect(engine.currentTurn.single.to, 6);

      expect(engine.undo(0), isTrue);
      expect(engine.board, boardBefore);
      expect(engine.dice, containsAll([6, 2]));
      expect(engine.canUndo, isFalse);
    });

    test('ход не закрывается сам, пока не подтверждён', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      engine.rollWith(6, 2);
      engine.applyMove(0, const NardyMove(0, 6));
      engine.applyMove(0, const NardyMove(6, 2));
      expect(engine.turn, 0);
      expect(engine.turnComplete, isTrue);
      expect(engine.canUndo, isTrue);
      engine.endTurn();
      expect(engine.turn, 1);
      expect(engine.lastTurn, hasLength(2));
      expect(engine.lastTurnSeat, 0);
    });

    test('seq растёт и при ходе, и при отмене', () {
      final engine = NardyEngine.newGame(nardyModeLong);
      final start = engine.seq;
      engine.rollWith(6, 2);
      final afterRoll = engine.seq;
      expect(afterRoll, greaterThan(start));
      engine.applyMove(0, const NardyMove(0, 6));
      final afterMove = engine.seq;
      expect(afterMove, greaterThan(afterRoll));
      engine.undo(0);
      expect(engine.seq, greaterThan(afterMove));
    });
  });

  group('нижняя панель в портрете', () {
    test('во время партии слот фиксирован', () {
      expect(nardyBottomPanelHeight(isOver: false), 148.0);
    });

    test('после партии высота по содержимому — кнопки не обрезаются', () {
      expect(nardyBottomPanelHeight(isOver: true), isNull);
    });
  });

}
