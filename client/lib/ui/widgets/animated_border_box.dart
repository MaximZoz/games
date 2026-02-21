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
    this.animateBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final double? borderRadius;
  /// Включает циклическую анимацию градиентной рамки.
  final bool animateBorder;

  @override
  State<AnimatedBorderBox> createState() => _AnimatedBorderBoxState();
}

class _AnimatedBorderBoxState extends State<AnimatedBorderBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  static const _staticGradientStop = 0.22;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedBorderBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateBorder != widget.animateBorder) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.animateBorder) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat();
      _animation ??= CurvedAnimation(parent: _controller!, curve: Curves.linear);
      return;
    }
    _controller?.dispose();
    _controller = null;
    _animation = null;
  }

  Widget _buildContainer(Gradient gradient, double r) {
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
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius ?? AppRadius.card;
    final staticGradient = AppGradients.borderAt(_staticGradientStop);
    final animated = widget.animateBorder && _animation != null;
    return Container(
      margin: widget.margin,
      child: animated
          ? AnimatedBuilder(
              animation: _animation!,
              builder: (context, _) =>
                  _buildContainer(AppGradients.borderAt(_animation!.value), r),
            )
          : _buildContainer(staticGradient, r),
    );
  }
}
