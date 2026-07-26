import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

void main() {
  test('formatRewardBronze для ступеней входа', () {
    expect(formatRewardBronze(10), '10 бронзовых');
    expect(formatRewardBronze(50), '50 бронзовых');
    expect(formatRewardBronze(1000), '10 серебряных');
    expect(formatRewardBronze(3000), '30 серебряных');
  });

  test('rewardCoinType', () {
    expect(rewardCoinType(10), CoinType.bronze);
    expect(rewardCoinType(50), CoinType.bronze);
    expect(rewardCoinType(1000), CoinType.silver);
    expect(rewardCoinType(3000), CoinType.silver);
  });
}
