import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Контейнер с анимированной градиентной рамкой (белый фон внутри).
class AnimatedBorderBox extends StatefulWidget {
  const AnimatedBorderBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderWidth = 2,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final double? borderRadius;

  @override
  State<AnimatedBorderBox> createState() => _AnimatedBorderBoxState();
}

class _AnimatedBorderBoxState extends State<AnimatedBorderBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
    final r = widget.borderRadius ?? AppRadius.card;
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final gradient = AppGradients.borderAt(_animation.value);
          return Container(
            padding: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(r + widget.borderWidth),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentStart.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(r),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
