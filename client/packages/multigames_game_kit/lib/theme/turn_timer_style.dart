import 'package:flutter/material.dart';

/// Цвет/градиент таймера хода: много времени — зелёный, мало — красный;
/// без лимита — мягкий фиолетовый.
class TurnTimerStyle {
  TurnTimerStyle._();

  static const Color noTimerA = Color(0xFF8B5CF6);
  static const Color noTimerB = Color(0xFFA78BFA);
  static const Color green = Color(0xFF34D399);
  static const Color orange = Color(0xFFFBBF24);
  static const Color red = Color(0xFFF87171);

  /// [fraction] = оставшаяся доля времени 0..1.
  static List<Color> colorsFor({
    required bool hasTimer,
    required double fraction,
  }) {
    if (!hasTimer) return const [noTimerA, noTimerB];
    final t = fraction.clamp(0.0, 1.0);
    if (t > 0.45) {
      final k = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      return [
        Color.lerp(orange, green, k)!,
        Color.lerp(
            orange.withValues(alpha: 0.75), green.withValues(alpha: 0.85), k)!,
      ];
    }
    if (t > 0.18) {
      final k = ((t - 0.18) / 0.27).clamp(0.0, 1.0);
      return [
        Color.lerp(red, orange, k)!,
        Color.lerp(
            red.withValues(alpha: 0.8), orange.withValues(alpha: 0.75), k)!,
      ];
    }
    return [red, red.withValues(alpha: 0.7)];
  }
}
