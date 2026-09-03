import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Иконка «Дурак» — официальный Material Symbol `playing_cards`.
class DurakGameIcon extends StatelessWidget {
  const DurakGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  static const IconData iconData = Symbols.playing_cards_rounded;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi,
      child: Icon(
        iconData,
        size: size,
        color: color,
        fill: 1,
      ),
    );
  }
}
