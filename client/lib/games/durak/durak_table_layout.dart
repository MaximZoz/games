import 'dart:ui';

/// Геометрия рядов пар на столе дурака.
///
/// Вынесена из экрана, потому что одни и те же числа нужны и вёрстке стола,
/// и расчёту точки посадки летящей карты: разойдутся — карта сядет мимо.

/// Высота слота пары (карта атаки + карта защиты со сдвигом).
double durakTablePairHeight(Size cardSize) => cardSize.height + 20;

/// Обычный вертикальный шаг между рядами (без наезда).
double durakTableNormalRowStep(Size cardSize) =>
    durakTablePairHeight(cardSize) + 10;

/// Наезд «кромкой»: от предыдущего ряда виден ранг с мастью.
double durakTableCompactPeek(Size cardSize) => cardSize.height * 0.40;

/// Y-координата верха ряда [row] (0-based) при [rowCount] рядах.
///
/// [compact] — телефон в альбоме: между шапкой соперников и кнопкой действия
/// остаётся ~90 px, обычный шаг не помещается уже на втором ряду, поэтому
/// ряды всегда идут «кромкой».
double durakTableRowTop(
  Size cardSize,
  int row,
  int rowCount, {
  required bool compact,
}) {
  if (row <= 0) return 0;
  final peek = durakTableCompactPeek(cardSize);
  if (compact) return row * peek;
  if (rowCount < 3) return row * durakTableNormalRowStep(cardSize);
  // Ряд 1 (второй): чуть ниже, чтобы читалась масть у первого ряда.
  if (row == 1) return peek;
  // Ряд 2+ (третий…): как обычно относительно предыдущего полного ряда.
  return peek + (row - 1) * durakTableNormalRowStep(cardSize);
}

/// Полная высота стопки рядов.
double durakTableStackHeight(
  Size cardSize,
  int rowCount, {
  required bool compact,
}) {
  if (rowCount <= 0) return 0;
  return durakTableRowTop(cardSize, rowCount - 1, rowCount, compact: compact) +
      durakTablePairHeight(cardSize);
}

/// Раскладывать ряды стопкой с наездом, а не колонкой с зазором.
bool durakTableUsesRowStack(int rowCount, {required bool compact}) =>
    rowCount >= 3 || (compact && rowCount >= 2);
