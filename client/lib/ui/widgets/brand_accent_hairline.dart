import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Прозрачность стрелок в нижнем тулбаре.
/// Splash гасит их на старте и поднимает при «приземлении» handoff-анимации.
final bootToolbarHairlinesOpacityProvider = StateProvider<double>((ref) => 1);

/// Градиентная «стрелка»-линия бренда Zozu (splash и подпись в тулбаре).
///
/// Стиль один: indigo → violet с прозрачными краями, скругление 99.
class BrandAccentHairline extends StatelessWidget {
  const BrandAccentHairline({
    super.key,
    this.width = 36,
    this.height = 2.5,
    this.side = BrandAccentHairlineSide.symmetric,
  });

  final double width;
  final double height;

  /// Для пары слева/справа от текста можно слегка зеркалить затухание.
  final BrandAccentHairlineSide side;

  static const List<Color> _symmetricColors = [
    Color(0x006366F1),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0x008B5CF6),
  ];

  static const List<double> _symmetricStops = [0.0, 0.28, 0.72, 1.0];

  /// Внешний край прозрачный, к тексту — плотнее.
  static const List<Color> _fromOutsideColors = [
    Color(0x006366F1),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<double> _fromOutsideStops = [0.0, 0.42, 1.0];

  static const List<Color> _towardOutsideColors = [
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0x006366F1),
  ];

  static const List<double> _towardOutsideStops = [0.0, 0.58, 1.0];

  @override
  Widget build(BuildContext context) {
    final (colors, stops) = switch (side) {
      BrandAccentHairlineSide.symmetric => (_symmetricColors, _symmetricStops),
      BrandAccentHairlineSide.fadeOutsideLeft => (
          _fromOutsideColors,
          _fromOutsideStops,
        ),
      BrandAccentHairlineSide.fadeOutsideRight => (
          _towardOutsideColors,
          _towardOutsideStops,
        ),
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: colors,
          stops: stops,
        ),
      ),
    );
  }
}

enum BrandAccentHairlineSide {
  symmetric,
  fadeOutsideLeft,
  fadeOutsideRight,
}
