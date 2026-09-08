import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Обводка курсора геймпада вокруг кнопки, чата или карты.
Widget wrapGamepadCursor({
  required Widget child,
  required bool highlighted,
  double radius = 12,
}) {
  if (!highlighted) return child;
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.accentStart, width: 2.2),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentStart.withValues(alpha: 0.38),
          blurRadius: 8,
        ),
      ],
    ),
    child: child,
  );
}
