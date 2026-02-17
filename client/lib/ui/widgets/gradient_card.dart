import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Карточка с анимированной цветной рамкой и белым фоном внутри.
class GradientCard extends StatefulWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderWidth = 2,
    this.animate = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final bool animate;

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _appearController;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _appearController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );
    if (widget.animate) _appearController.forward();
  }

  @override
  void dispose() {
    _borderController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  Widget _buildCard() {
    final r = AppRadius.card + widget.borderWidth;
    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, _) {
        final gradient = AppGradients.borderAt(_borderController.value);
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(r),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentStart.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();
    if (!widget.animate) {
      return widget.margin != null
          ? Container(margin: widget.margin, child: card)
          : card;
    }
    final animated = AnimatedBuilder(
      animation: _appearController,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: card),
      ),
    );
    return widget.margin != null
        ? Container(margin: widget.margin, child: animated)
        : animated;
  }
}
