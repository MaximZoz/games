import 'package:flutter/material.dart';

/// Общая анимация для ShimmeringGradient — все градиенты переливаются синхронно.
class ShimmerAnimationScope extends StatefulWidget {
  const ShimmerAnimationScope({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 28),
  });

  final Widget child;
  final Duration duration;

  /// Получить текущее значение анимации (0.0 .. 1.0).
  static Animation<double>? of(BuildContext context) {
    return _InheritedShimmerAnimation.maybeOf(context)?.animation;
  }

  @override
  State<ShimmerAnimationScope> createState() => _ShimmerAnimationScopeState();
}

class _ShimmerAnimationScopeState extends State<ShimmerAnimationScope>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedShimmerAnimation(
      animation: _animation,
      child: widget.child,
    );
  }
}

class _InheritedShimmerAnimation extends InheritedWidget {
  const _InheritedShimmerAnimation({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static _InheritedShimmerAnimation? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedShimmerAnimation>();
  }

  @override
  bool updateShouldNotify(_InheritedShimmerAnimation oldWidget) {
    return animation != oldWidget.animation;
  }
}
