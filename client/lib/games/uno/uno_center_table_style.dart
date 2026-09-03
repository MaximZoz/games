import 'package:flutter/painting.dart';

/// Размеры зелёного овала колоды/сброса Уно.
///
/// В альбоме высота стола ~150 px, а капсула с `borderRadius` 54 съедает
/// низ: подписи «Колода» / «Сброс» садятся на дугу. Здесь ниже радиус,
/// больше нижнее поле и чуть меньше карты — текст остаётся внутри овала.
class UnoCenterTableStyle {
  const UnoCenterTableStyle({
    required this.cardSize,
    required this.padding,
    required this.gap,
    required this.labelGap,
    required this.labelFontSize,
    required this.borderRadius,
    required this.pendingGap,
  });

  final Size cardSize;
  final EdgeInsets padding;
  final double gap;
  final double labelGap;
  final double labelFontSize;
  final double borderRadius;
  final double pendingGap;

  /// Карта + подпись + вертикальные поля. Без учёта pending-бейджа.
  double get minHeight =>
      padding.vertical + cardSize.height + labelGap + labelLineHeight;

  /// Строка подписи с запасом под метрики шрифта.
  double get labelLineHeight => labelFontSize + 3;

  static UnoCenterTableStyle of({
    required bool narrow,
    required bool phoneLandscape,
    double scale = 1,
  }) {
    final s = scale <= 0 ? 1.0 : scale;
    final base = phoneLandscape
        ? const Size(54, 81)
        : (narrow ? const Size(62, 93) : const Size(68, 102));
    final card = Size(base.width * s, base.height * s);
    final padV = (phoneLandscape ? 12.0 : (narrow ? 15.0 : 24.0)) * s;
    final padBottom = phoneLandscape ? padV + 8 : padV;
    return UnoCenterTableStyle(
      cardSize: card,
      padding: EdgeInsets.fromLTRB(
        phoneLandscape ? 16 : (narrow ? 22.0 : 48.0),
        padV,
        phoneLandscape ? 16 : (narrow ? 22.0 : 48.0),
        padBottom,
      ),
      gap: phoneLandscape ? 12 : (narrow ? 16.0 : 30.0),
      labelGap: phoneLandscape ? 4 : 5,
      labelFontSize: phoneLandscape ? 10 : 11,
      borderRadius: phoneLandscape ? 28 : (narrow ? 54.0 : 90.0),
      pendingGap: narrow ? 10 : 18,
    );
  }
}
