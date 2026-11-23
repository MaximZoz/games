import 'package:flutter/material.dart';

import '../theme/game_palette.dart';

/// Поверхность игрового стола — одна на все игры.
///
/// Скруглённая панель в палитре приложения: игра кладёт на неё фишки и не
/// выбирает свой цвет «сукна».
class GameTableSurface extends StatelessWidget {
  const GameTableSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: GamePalette.tableGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GamePalette.tableBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: GamePalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
