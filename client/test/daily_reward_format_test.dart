import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

void main() {
  test('formatRewardBronze для ступеней входа', () {
    expect(formatRewardBronze(10), '10 бронзовых');
    expect(formatRewardBronze(50), '50 бронзовых');
    expect(formatRewardBronze(1000), '10 серебряных');
    expect(formatRewardBronze(3000), '30 серебряных');
  });

  test('formatRewardBronze округляет вверх до большей монеты', () {
    expect(formatRewardBronze(1), '1 бронзовых');
    expect(formatRewardBronze(99), '99 бронзовых');
    expect(formatRewardBronze(100), '1 серебряных');
    expect(formatRewardBronze(101), '2 серебряных');
    expect(formatRewardBronze(150), '2 серебряных');
    expect(formatRewardBronze(9999), '1 золотых'); // 100 серебра → 1 золото
    expect(formatRewardBronze(10000), '1 золотых');
    expect(formatRewardBronze(10001), '2 золотых');
  });

  test('formatRewardBronzePerDay', () {
    expect(formatRewardBronzePerDay(10), '10 бронзовых в день');
    expect(formatRewardBronzePerDay(100), '1 серебряных в день');
  });

  test('rewardCoinType', () {
    expect(rewardCoinType(10), CoinType.bronze);
    expect(rewardCoinType(50), CoinType.bronze);
    expect(rewardCoinType(100), CoinType.silver);
    expect(rewardCoinType(150), CoinType.silver);
    expect(rewardCoinType(1000), CoinType.silver);
    expect(rewardCoinType(3000), CoinType.silver);
    expect(rewardCoinType(10000), CoinType.gold);
    expect(rewardCoinType(9999), CoinType.gold);
  });

  test('rewardCoinAmount', () {
    expect(rewardCoinAmount(10), 10);
    expect(rewardCoinAmount(101), 2);
    expect(rewardCoinAmount(10000), 1);
    expect(rewardCoinAmount(10001), 2);
  });
}
