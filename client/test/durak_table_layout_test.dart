import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_table_layout.dart';

void main() {
  const card = Size(43, 61);

  group('ряды стола дурака', () {
    test('портрет: второй ряд с обычным шагом', () {
      expect(
        durakTableRowTop(card, 1, 2, compact: false),
        durakTableNormalRowStep(card),
      );
      expect(durakTableUsesRowStack(2, compact: false), isFalse);
    });

    test('портрет: при трёх рядах второй наезжает кромкой', () {
      expect(
        durakTableRowTop(card, 1, 3, compact: false),
        durakTableCompactPeek(card),
      );
      expect(durakTableUsesRowStack(3, compact: false), isTrue);
    });

    test('альбом: кромка уже со второго ряда', () {
      expect(
        durakTableRowTop(card, 1, 2, compact: true),
        durakTableCompactPeek(card),
      );
      expect(durakTableUsesRowStack(2, compact: true), isTrue);
    });

    test('альбом: два ряда помещаются в коридор между шапкой и кнопкой', () {
      // Реальные числа телефона в альбоме: доске достаётся ~130 px,
      // из них ~43 отданы слоту кнопки «Бито».
      const corridor = 130.0 - 43.0;
      expect(
        durakTableStackHeight(card, 1, compact: true),
        lessThan(corridor),
      );
      // Второй ряд в портретном шаге не влез бы совсем.
      expect(
        durakTableStackHeight(card, 2, compact: false),
        greaterThan(corridor * 1.5),
      );
      // С кромкой перебор остаётся в пределах запаса под кнопкой.
      expect(
        durakTableStackHeight(card, 2, compact: true),
        lessThan(corridor * 1.3),
      );
    });

    test('высота стопки растёт монотонно и совпадает с верхом последнего ряда',
        () {
      for (final compact in [false, true]) {
        var prev = 0.0;
        for (var rows = 1; rows <= 4; rows++) {
          final h = durakTableStackHeight(card, rows, compact: compact);
          expect(h, greaterThan(prev));
          expect(
            h,
            durakTableRowTop(card, rows - 1, rows, compact: compact) +
                durakTablePairHeight(card),
          );
          prev = h;
        }
      }
    });

    test('нулевой ряд всегда сверху', () {
      for (final compact in [false, true]) {
        expect(durakTableRowTop(card, 0, 3, compact: compact), 0);
      }
      expect(durakTableStackHeight(card, 0, compact: true), 0);
    });

    test('полёт прячет серверную пару до посадки', () {
      expect(
        durakKeepServerTablePair(optimistic: true, flyingToTable: true),
        isFalse,
      );
      expect(
        durakKeepServerTablePair(optimistic: true, flyingToTable: false),
        isFalse,
      );
      expect(
        durakKeepServerTablePair(optimistic: false, flyingToTable: false),
        isTrue,
      );
      expect(
        durakKeepServerTablePair(
          optimistic: false,
          flyingToTable: false,
          remoteFlying: true,
        ),
        isFalse,
      );
      expect(
        durakHideDeferredRemoteAttack(
          existedOnPrevTable: false,
          optimistic: false,
          localFlying: false,
          fxDeferred: true,
        ),
        isTrue,
      );
      expect(
        durakHideDeferredRemoteAttack(
          existedOnPrevTable: true,
          optimistic: false,
          localFlying: false,
          fxDeferred: true,
        ),
        isFalse,
      );
      expect(
        durakHideDeferredRemoteAttack(
          existedOnPrevTable: false,
          optimistic: false,
          localFlying: false,
          fxDeferred: true,
          seated: true,
        ),
        isFalse,
      );
      expect(
        durakShouldHideRemoteTableCard(
          markedRemoteFlying: true,
          seated: true,
          optimistic: false,
          localFlying: false,
        ),
        isFalse,
      );
      expect(
        durakShouldHideRemoteTableCard(
          markedRemoteFlying: true,
          seated: false,
          optimistic: false,
          localFlying: false,
        ),
        isTrue,
      );
      expect(
        durakShouldRevealDeferredRemoteCard(
          hiddenAsRemote: true,
          seated: false,
          optimistic: true,
          localFlying: false,
        ),
        isTrue,
      );
      expect(
        durakShouldRevealDeferredRemoteCard(
          hiddenAsRemote: true,
          seated: false,
          optimistic: false,
          localFlying: false,
        ),
        isFalse,
      );
      expect(durakShouldSeatPrevTableCard(remoteFlying: true), isFalse);
      expect(durakShouldSeatPrevTableCard(remoteFlying: false), isTrue);
      expect(
        durakTableFxDeferred(
          fxScheduled: false,
          busy: false,
          localAttackHold: false,
          cardFlightActive: false,
          holdingFanCard: true,
        ),
        isTrue,
      );
      expect(
        durakTableFxDeferred(
          fxScheduled: false,
          busy: false,
          localAttackHold: false,
          cardFlightActive: false,
          holdingFanCard: false,
        ),
        isFalse,
      );
      expect(
        durakTableFxDeferred(
          fxScheduled: true,
          busy: false,
          localAttackHold: false,
          cardFlightActive: false,
          holdingFanCard: false,
        ),
        isTrue,
      );
      expect(
        durakRemoteAttackFromSeat(attackerIndex: 0, throwerIndex: 2),
        2,
      );
      expect(
        durakRemoteAttackFromSeat(attackerIndex: 1, throwerIndex: -1),
        1,
      );
      expect(durakTableSlotOpacity(inFlight: true), 0);
      expect(durakTableSlotOpacity(inFlight: false), 1);
      expect(
        durakTableAttackSlotInFlight(localFlying: false, remoteFlying: true),
        isTrue,
      );
      expect(
        durakTableAttackSlotInFlight(localFlying: true, remoteFlying: false),
        isTrue,
      );
      expect(
        durakTableAttackSlotInFlight(localFlying: false, remoteFlying: false),
        isFalse,
      );
      expect(
        durakTableDefenseHiddenDuringFlight(
          localDefendLock: false,
          remoteDefenseFlying: true,
        ),
        isTrue,
      );
      expect(
        durakTableDefenseHiddenDuringFlight(
          localDefendLock: true,
          remoteDefenseFlying: false,
        ),
        isTrue,
      );
      expect(
        durakTableDefenseHiddenDuringFlight(
          localDefendLock: false,
          remoteDefenseFlying: false,
        ),
        isFalse,
      );
      expect(
        durakNeedsPendingAttackSlot(
          attackAlreadyOnTable: true,
          stillFlying: true,
        ),
        isTrue,
      );
      expect(
        durakNeedsPendingAttackSlot(
          attackAlreadyOnTable: true,
          stillFlying: false,
        ),
        isFalse,
      );
      expect(
        durakNeedsPendingAttackSlot(attackAlreadyOnTable: false),
        isTrue,
      );
      expect(
        durakHoldTableFxForLocalAttack(
          optimisticAttack: true,
          flyingToTable: false,
        ),
        isTrue,
      );
      expect(
        durakHoldTableFxForLocalAttack(
          optimisticAttack: false,
          flyingToTable: false,
        ),
        isFalse,
      );
      expect(durakSeatedTablePairInLayout(seated: true), isTrue);
      expect(durakSeatedTablePairInLayout(seated: false), isFalse);
      expect(
        durakSeatedTablePairInLayout(
          seated: false,
          reserveForFlight: true,
        ),
        isTrue,
      );
      expect(
        durakSeatedTableSlotOpacity(seated: true, inFlight: true),
        1,
      );
      expect(
        durakSeatedTableSlotOpacity(seated: false, inFlight: true),
        0,
      );
    });

    test('посадка атаки совпадает с сеткой стола, не с «центром рядом»', () {
      const center = Offset(200, 160);
      final first = durakEstimateAttackLandRect(
        tableCenter: center,
        cardSize: card,
        pairIndex: 0,
        pairCount: 1,
        compact: false,
      );
      final second = durakEstimateAttackLandRect(
        tableCenter: center,
        cardSize: card,
        pairIndex: 1,
        pairCount: 2,
        compact: false,
      );
      expect(first.width, card.width);
      expect(first.height, card.height);
      expect(second.left, greaterThan(first.left));
      expect(second.top, first.top);
      final defend = durakEstimateDefenseLandRect(first);
      expect(defend.left, first.left + kDurakDefendOffset.dx);
      expect(defend.top, first.top + kDurakDefendOffset.dy);
      expect(durakTablePairSlotWidth(card), card.width + 26);
    });

    test('запас снизу не съедает высоту одной пары', () {
      const boardH = 140.0;
      final minTable = durakTableAreaMinHeight(card);
      final clamped = durakClampedTableBottomReserve(
        reserve: 200,
        boardHeight: boardH,
        cardSize: card,
      );
      expect(clamped, lessThan(boardH));
      expect(boardH - clamped, greaterThanOrEqualTo(minTable));
      expect(
        durakClampedTableBottomReserve(
          reserve: 10,
          boardHeight: 200,
          cardSize: card,
        ),
        10,
      );
      expect(
        durakClampedTableBottomReserve(
          reserve: 80,
          boardHeight: 40,
          cardSize: card,
        ),
        0,
      );
    });
  });
}
