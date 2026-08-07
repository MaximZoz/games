import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Логика веера: сжатие карт + растягивание на всю ширину.
({Size cardSize, double spacing}) fitHandFan({
  required int n,
  required double maxWidth,
  Size handCardSize = const Size(92, 132),
}) {
  if (n <= 0) return (cardSize: handCardSize, spacing: 0);
  var size = handCardSize;
  if (n > 28) {
    size = Size(handCardSize.width * 0.40, handCardSize.height * 0.40);
  } else if (n > 22) {
    size = Size(handCardSize.width * 0.48, handCardSize.height * 0.48);
  } else if (n > 18) {
    size = Size(handCardSize.width * 0.56, handCardSize.height * 0.56);
  } else if (n > 14) {
    size = Size(handCardSize.width * 0.66, handCardSize.height * 0.66);
  } else if (n > 11) {
    size = Size(handCardSize.width * 0.74, handCardSize.height * 0.74);
  } else if (n > 9) {
    size = Size(handCardSize.width * 0.82, handCardSize.height * 0.82);
  } else if (n > 7) {
    size = Size(handCardSize.width * 0.90, handCardSize.height * 0.90);
  }

  const fanPad = 4.0;
  final usable = (maxWidth - fanPad).clamp(72.0, maxWidth);

  double minSpacing(Size s) {
    if (n <= 1) return 0;
    final w = s.width;
    if (n > 28) return w * 0.05;
    if (n > 22) return w * 0.06;
    if (n > 18) return w * 0.08;
    if (n > 14) return w * 0.10;
    if (n > 11) return w * 0.12;
    if (n > 9) return w * 0.16;
    if (n > 7) return w * 0.22;
    if (n > 5) return w * 0.32;
    return w * 0.42;
  }

  for (var step = 0; step < 28; step++) {
    final need = size.width + minSpacing(size) * (n - 1);
    if (need <= usable || size.width <= 18) break;
    final scale = (usable / need).clamp(0.28, 0.96);
    size = Size(size.width * scale, size.height * scale);
  }

  if (n <= 1) return (cardSize: size, spacing: 0);
  final lo = minSpacing(size);
  final hi = size.width * 0.96;
  final fill = (usable - size.width) / (n - 1);
  final spacing = fill.clamp(lo, hi > lo ? hi : lo);
  return (cardSize: size, spacing: spacing);
}

void main() {
  test('12 cards: smaller cards, denser overlap, still full width', () {
    const maxW = 390.0;
    final six = fitHandFan(n: 6, maxWidth: maxW);
    final twelve = fitHandFan(n: 12, maxWidth: maxW);

    expect(twelve.cardSize.width, lessThan(six.cardSize.width));
    expect(
      twelve.spacing / twelve.cardSize.width,
      lessThan(six.spacing / six.cardSize.width),
    );

    final span12 = twelve.cardSize.width + twelve.spacing * 11;
    expect(span12, greaterThan(maxW * 0.90));
    expect(span12, lessThanOrEqualTo(maxW));
  });

  test('many cards fill width and stay within bounds', () {
    const maxW = 360.0;
    for (final n in [8, 10, 12, 16, 20, 24]) {
      final lay = fitHandFan(n: n, maxWidth: maxW);
      final span = lay.cardSize.width + lay.spacing * (n - 1);
      expect(span, greaterThan(maxW * 0.88), reason: 'n=$n fill');
      expect(span, lessThanOrEqualTo(maxW + 0.5), reason: 'n=$n bound');
    }
  });

  test('few cards stretch toward full width', () {
    const maxW = 390.0;
    final four = fitHandFan(n: 4, maxWidth: maxW);
    final span = four.cardSize.width + four.spacing * 3;
    expect(span, greaterThan(maxW * 0.90));
  });
}
