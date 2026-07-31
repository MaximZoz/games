import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('formatRewardBronze для ступеней входа', () {
    expect(formatRewardBronze(10), '10 бронзовых');
    expect(formatRewardBronze(50), '50 бронзовых');
    expect(formatRewardBronze(1000), '10 серебряных');
    expect(formatRewardBronze(3000), '30 серебряных');
  });

  test('formatRewardBronze без округления вверх', () {
    expect(formatRewardBronze(1), '1 бронзовых');
    expect(formatRewardBronze(99), '99 бронзовых');
    expect(formatRewardBronze(100), '1 серебряных');
    expect(formatRewardBronze(101), '1 серебряных 1 бронзовых');
    expect(formatRewardBronze(133), '1 серебряных 33 бронзовых');
    expect(formatRewardBronze(150), '1 серебряных 50 бронзовых');
    expect(formatRewardBronze(63), '63 бронзовых');
    expect(formatRewardBronze(9999), '99 серебряных 99 бронзовых');
    expect(formatRewardBronze(10000), '1 золотых');
    expect(formatRewardBronze(10001), '1 золотых 1 бронзовых');
  });

  test('formatRewardBronzeAbbr', () {
    expect(formatRewardBronzeAbbr(10), '10 бр');
    expect(formatRewardBronzeAbbr(63), '63 бр');
    expect(formatRewardBronzeAbbr(100), '1 с.');
    expect(formatRewardBronzeAbbr(133), '1 с. 33 бр');
  });

  test('formatRewardBronzePerDay', () {
    expect(formatRewardBronzePerDay(10), '10 бр/день');
    expect(formatRewardBronzePerDay(63), '63 бр/день');
    expect(formatRewardBronzePerDay(100), '1 с./день');
    expect(formatRewardBronzePerDay(133), '1 с. 33 бр/день');
  });

  test('rewardCoinType — старший ненулевой номинал', () {
    expect(rewardCoinType(10), CoinType.bronze);
    expect(rewardCoinType(50), CoinType.bronze);
    expect(rewardCoinType(100), CoinType.silver);
    expect(rewardCoinType(150), CoinType.silver);
    expect(rewardCoinType(1000), CoinType.silver);
    expect(rewardCoinType(3000), CoinType.silver);
    expect(rewardCoinType(10000), CoinType.gold);
    expect(rewardCoinType(9999), CoinType.silver);
    expect(rewardCoinType(10001), CoinType.gold);
  });

  test('rewardCoinAmount — количество старшего номинала', () {
    expect(rewardCoinAmount(10), 10);
    expect(rewardCoinAmount(101), 1);
    expect(rewardCoinAmount(133), 1);
    expect(rewardCoinAmount(10000), 1);
    expect(rewardCoinAmount(10001), 1);
    expect(rewardCoinAmount(250), 2);
  });
}
