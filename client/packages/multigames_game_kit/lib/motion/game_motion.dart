import 'package:flutter/animation.dart';

/// Длительности и кривые игровых анимаций — одни на все игры.
class GameMotion {
  GameMotion._();

  /// Фишка летит через стол (ход, взятие из прикупа).
  static const Duration flight = Duration(milliseconds: 460);

  /// Пауза между фишками, когда летит несколько подряд.
  static const Duration stagger = Duration(milliseconds: 110);

  /// Соседние фишки раздвигаются / съезжаются.
  static const Duration settle = Duration(milliseconds: 280);

  /// Появление / исчезновение элемента хрома.
  static const Duration fade = Duration(milliseconds: 200);

  static const Curve flightCurve = Curves.easeInOutCubic;
  static const Curve settleCurve = Curves.easeOutCubic;
}
