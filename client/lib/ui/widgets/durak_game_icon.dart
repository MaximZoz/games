import 'package:flutter/material.dart';

/// Иконка «Дурак» — Material `style_rounded` (веер карт), зеркально по X.
class DurakGameIcon extends StatelessWidget {
  const DurakGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  /// Исходная иконка веера карт (до отражения).
  static const IconData iconData = Icons.style_rounded;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: true,
      child: Icon(iconData, size: size, color: color),
    );
  }
}
