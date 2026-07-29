import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

void main() {
  group('formatStakeAmount', () {
    test('bronze amounts stay as-is', () {
      expect(formatStakeAmount(1), '1');
      expect(formatStakeAmount(10), '10');
      expect(formatStakeAmount(50), '50');
      expect(formatStakeAmount(150), '150');
    });

    test('exact silver multiples', () {
      expect(formatStakeAmount(100), '1');
      expect(formatStakeAmount(500), '5');
      expect(formatStakeAmount(5000), '50');
    });

    test('exact gold multiples', () {
      expect(formatStakeAmount(10000), '1');
      expect(formatStakeAmount(50000), '5');
    });
  });

  group('stakeCoinType', () {
    test('classifies bronze/silver/gold', () {
      expect(stakeCoinType(1), CoinType.bronze);
      expect(stakeCoinType(50), CoinType.bronze);
      expect(stakeCoinType(100), CoinType.silver);
      expect(stakeCoinType(5000), CoinType.silver);
      expect(stakeCoinType(10000), CoinType.gold);
      expect(stakeCoinType(50000), CoinType.gold);
    });

    test('non-divisible large stays bronze', () {
      expect(stakeCoinType(101), CoinType.bronze);
      expect(stakeCoinType(10001), CoinType.bronze);
    });

    test('helpers', () {
      expect(stakeIsSilver(100), isTrue);
      expect(stakeIsSilver(50), isFalse);
      expect(stakeIsGold(10000), isTrue);
      expect(stakeIsGold(100), isFalse);
    });
  });

  group('formatTurnTime / formatGridSize', () {
    test('known turn times', () {
      expect(formatTurnTime(0), '∞');
      expect(formatTurnTime(10), '10 с');
      expect(formatTurnTime(30), '30 с');
      expect(formatTurnTime(60), '1 мин');
      expect(formatTurnTime(600), '10 мин');
      expect(formatTurnTime(45), '45 с');
    });

    test('grid size', () {
      expect(formatGridSize(3), '3x3');
      expect(formatGridSize(8), '8x8');
    });
  });

  group('formatBalance', () {
    test('bronze only', () {
      expect(formatBalance(0), '0 бр');
      expect(formatBalance(99), '99 бр');
    });

    test('silver and mixed', () {
      expect(formatBalance(100), '1 с');
      expect(formatBalance(101), '1 с. 1 бр');
      expect(formatBalance(250), '2 с. 50 бр');
    });

    test('gold and diamond', () {
      expect(formatBalance(10000), '1 з');
      expect(formatBalance(10100), '1 з. 1 с. 0 бр');
      expect(formatBalance(1000000), '1 ◆');
    });
  });
}
