import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

void main() {
  group('emergingDenominations', () {
    test('появление серебра при переходе через 100', () {
      expect(
        emergingDenominations(50, 150),
        {CoinType.silver},
      );
    });

    test('без новых номиналов', () {
      expect(emergingDenominations(10, 20), isEmpty);
      expect(emergingDenominations(150, 250), isEmpty);
    });

    test('появление золота', () {
      expect(
        emergingDenominations(5000, 10000),
        {CoinType.gold},
      );
    });
  });

  group('denominationOf', () {
    test('разбивка', () {
      expect(denominationOf(CoinType.bronze, 123).toInt(), 23);
      expect(denominationOf(CoinType.silver, 123).toInt(), 1);
      expect(denominationOf(CoinType.gold, 10000).toInt(), 1);
    });
  });
}
