import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_fx_layout.dart';

void main() {
  group('веер дурака сжимается плавно', () {
    test('масштаб убывает без ступенек', () {
      var previous = durakFanScaleFor(1);
      for (var n = 2; n <= 36; n++) {
        final scale = durakFanScaleFor(n);
        expect(scale, lessThanOrEqualTo(previous));
        // Одна карта не должна ронять веер больше чем на 5%.
        expect(previous - scale, lessThan(0.05),
            reason: 'скачок на $n картах');
        previous = scale;
      }
    });

    test('крайние значения в разумных пределах', () {
      expect(durakFanScaleFor(1), 1.0);
      expect(durakFanScaleFor(6), 1.0);
      expect(durakFanScaleFor(36), 0.40);
      expect(durakFanScaleFor(60), 0.40);
    });

    test('шаг между картами тоже без ступенек', () {
      var previous = durakFanMinSpacingFrac(1);
      for (var n = 2; n <= 36; n++) {
        final step = durakFanMinSpacingFrac(n);
        expect(step, lessThanOrEqualTo(previous));
        expect(previous - step, lessThan(0.06), reason: 'скачок на $n картах');
        previous = step;
      }
      expect(durakFanMinSpacingFrac(2), 0.42);
      expect(durakFanMinSpacingFrac(36), 0.05);
    });
  });

  group('твины раскладки', () {
    test('в альбоме твин короткий, но не нулевой', () {
      final compact = durakLayoutTweenDuration(compact: true);
      expect(compact, greaterThan(Duration.zero));
      expect(compact.inMilliseconds, lessThan(300));
      expect(
        durakLayoutTweenDuration(compact: false).inMilliseconds,
        greaterThan(compact.inMilliseconds),
      );
    });

    test('ключ меняется при повороте и держится при мелком джиттере', () {
      final portrait = durakLayoutTweenKey(const Size(390, 844));
      final landscape = durakLayoutTweenKey(const Size(844, 390));
      expect(portrait, isNot(landscape));
      expect(durakLayoutTweenKey(const Size(392, 846)), portrait);
    });
  });
}
