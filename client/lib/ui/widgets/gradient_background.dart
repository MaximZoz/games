import 'package:flutter/material.dart';

import 'floating_clouds.dart';
import 'shimmer_gradient.dart';

/// Фон с переливающимся градиентом и плывущими облаками.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.cloudIntensity = 0.7,
  });

  final Widget child;
  final double cloudIntensity;

  @override
  Widget build(BuildContext context) {
    return FloatingClouds(
      intensity: cloudIntensity,
      child: ShimmeringGradient(
        duration: const Duration(seconds: 28),
        child: child,
      ),
    );
  }
}
