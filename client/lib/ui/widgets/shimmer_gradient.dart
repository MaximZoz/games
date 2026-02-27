import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'shimmer_animation_scope.dart';

/// Переливающийся градиент фона: цвета плавно сдвигаются.
/// Использует общую анимацию из [ShimmerAnimationScope], если доступна.
class ShimmeringGradient extends StatefulWidget {
  const ShimmeringGradient({
    super.key,
    this.duration = const Duration(seconds: 25),
    this.child,
  });

  final Duration duration;
  final Widget? child;

  @override
  State<ShimmeringGradient> createState() => _ShimmeringGradientState();
}

class _ShimmeringGradientState extends State<ShimmeringGradient>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = ShimmerAnimationScope.of(context);
    if (shared != null) {
      if (_ownController != null) {
        _ownController!.dispose();
        _ownController = null;
      }
      _animation = shared;
    } else if (_ownController == null) {
      _ownController = AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat();
      _animation = CurvedAnimation(
        parent: _ownController!,
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.shimmerColors;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        final colorCount = colors.length;
        final n = colorCount - 1;
        final stops = List.generate(colorCount, (i) => i / n);
        // Плавная интерполяция между цветами (без скачков)
        final interpolatedColors = List.generate(colorCount, (i) {
          final position = (t + i / n) % 1.0;
          final colorIndex = position * n;
          final baseIndex = colorIndex.floor() % colorCount;
          final nextIndex = (baseIndex + 1) % colorCount;
          final localT = colorIndex - colorIndex.floor();
          return Color.lerp(
            colors[baseIndex],
            colors[nextIndex],
            localT,
          )!;
        });
        // Направление градиента очень медленно поворачивается
        final angle = t * 2 * math.pi;
        final begin = Alignment(math.cos(angle), math.sin(angle));
        final end = Alignment(-math.cos(angle), -math.sin(angle));
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              stops: stops,
              colors: interpolatedColors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
