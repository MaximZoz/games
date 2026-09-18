import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/game_stake.dart';

void main() {
  group('canAffordStake', () {
    test('1 серебро + 1 бронза хватает на ставку 2 бронзы', () {
      expect(
        canAffordStake(balanceBronze: 101, stakeBronze: 2),
        isTrue,
      );
    });

    test('1 серебро + 1 бронза не хватает на 2 серебра (200)', () {
      expect(
        canAffordStake(balanceBronze: 101, stakeBronze: 200),
        isFalse,
      );
    });
  });

  group('affordableStakeOptions / clampStakeToAffordable', () {
    const unlocked = [2, 10, 50, 200, 500];

    test('при балансе 101 остаются только бронзовые ставки', () {
      expect(
        affordableStakeOptions(101, unlocked),
        [2, 10, 50],
      );
    });

    test('ставка 200 сжимается до 50', () {
      expect(
        clampStakeToAffordable(200, 101, unlocked),
        50,
      );
    });

    test('посильная ставка не меняется', () {
      expect(
        clampStakeToAffordable(2, 101, unlocked),
        2,
      );
    });
  });

  group('stakeLostOnFinish / stakeFinishRewardChip', () {
    test('ничья не списывает ставку и не показывает чип', () {
      expect(
        stakeLostOnFinish(stakeBronze: 50, isDraw: true, iWon: false),
        0,
      );
      expect(
        stakeFinishRewardChip(stakeBronze: 50, isDraw: true, iWon: false),
        0,
      );
      expect(
        stakeShowFinishReward(
          stakeBronze: 50,
          isOver: true,
          isDraw: true,
          rewardChip: 0,
        ),
        isFalse,
      );
    });

    test('поражение списывает ставку, победа даёт чистый плюс', () {
      expect(
        stakeLostOnFinish(stakeBronze: 50, isDraw: false, iWon: false),
        50,
      );
      expect(
        stakeFinishRewardChip(
          stakeBronze: 50,
          isDraw: false,
          iWon: false,
        ),
        -50,
      );
      expect(
        stakeFinishRewardChip(
          stakeBronze: 50,
          isDraw: false,
          iWon: true,
          netProfit: 50,
        ),
        50,
      );
    });
  });

  group('pokerPlaceCredit', () {
    test('банк сохраняется для 2–6 игроков', () {
      for (final n in [2, 3, 4, 5, 6]) {
        for (final stake in [2, 10, 50]) {
          var sum = 0;
          for (var place = 1; place <= n; place++) {
            sum += pokerPlaceCredit(
              stake: stake,
              playerCount: n,
              place: place,
            );
          }
          expect(sum, stake * n, reason: 'n=$n stake=$stake');
        }
      }
    });

    test('доли 3/4/5/6 игроков', () {
      expect(pokerPlaceCredit(stake: 10, playerCount: 3, place: 1), 20);
      expect(pokerPlaceCredit(stake: 10, playerCount: 3, place: 2), 10);
      expect(pokerPlaceCredit(stake: 10, playerCount: 4, place: 1), 30);
      expect(pokerPlaceCredit(stake: 10, playerCount: 5, place: 1), 30);
      expect(pokerPlaceCredit(stake: 10, playerCount: 6, place: 1), 40);
      expect(
        pokerPlaceNetProfit(stake: 10, playerCount: 3, place: 2),
        0,
      );
    });
  });
}
