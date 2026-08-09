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
}
