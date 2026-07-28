import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Однородный фон приложения (без shimmer и облаков).
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.cloudIntensity = 0.7,
  });

  final Widget child;
  /// Устарело: оставлено для совместимости вызовов, игнорируется.
  final double cloudIntensity;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceUnified,
      child: child,
    );
  }
}
