/// Куда и под каким углом карта садится на сброс.
///
/// Смещение и наклон зависят от id, поэтому соседние карты не ложатся
/// одинаково и нижняя остаётся видна из-под верхней.
class UnoDiscardLand {
  const UnoDiscardLand({
    required this.dx,
    required this.dy,
    required this.angle,
  });

  final double dx;
  final double dy;

  /// Угол верхней карты в радианах, уже после приземления.
  final double angle;

  /// Угол в начале броска: карта вылетает сильнее наклонённой.
  double get tossAngle => angle + (angle >= 0 ? 0.78 : -0.78);
}

/// Поза броска поверх уже лежащей карты: другой край и противоположный наклон,
/// чтобы нижняя карта оставалась видна.
UnoDiscardLand unoDiscardThrowOnto(UnoDiscardLand covered) {
  final side = covered.angle >= 0 ? -1.0 : 1.0;
  final tilt = (covered.angle.abs() + 0.05).clamp(0.14, 0.22).toDouble();
  final shift = (covered.dx.abs() + 4).clamp(9.0, 14.0).toDouble();
  final dy = covered.dy == 0 ? 2.0 : -covered.dy;
  return UnoDiscardLand(dx: side * shift, dy: dy, angle: side * tilt);
}

UnoDiscardLand unoDiscardLandPose(String cardId) {
  var hash = 0;
  for (final unit in cardId.codeUnits) {
    hash = (hash * 33 + unit) & 0x7fffffff;
  }
  final side = hash.isEven ? 1.0 : -1.0;
  final tilt = 0.12 + (hash % 5) * 0.018;
  final dx = side * (7 + (hash % 4));
  final dy = (((hash ~/ 4) % 5) - 2).toDouble();
  return UnoDiscardLand(dx: dx, dy: dy, angle: side * tilt);
}
