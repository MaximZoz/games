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
    this.animateBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final bool animate;
  /// Включает циклическую анимацию рамки. По умолчанию отключена для снижения нагрузки.
  final bool animateBorder;

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with TickerProviderStateMixin {
  AnimationController? _borderController;
  late AnimationController _appearController;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  static const _staticGradientStop = 0.2;

  @override
  void initState() {
    super.initState();
    _syncBorderAnimation();
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
  void didUpdateWidget(covariant GradientCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateBorder != widget.animateBorder) {
      _syncBorderAnimation();
    }
  }

  void _syncBorderAnimation() {
    if (widget.animateBorder) {
      _borderController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat();
      return;
    }
    _borderController?.dispose();
    _borderController = null;
  }

  @override
  void dispose() {
    _borderController?.dispose();
    _appearController.dispose();
    super.dispose();
  }

  Widget _cardWithGradient(Gradient gradient) {
    final r = AppRadius.card + widget.borderWidth;
    return Container(
      padding: EdgeInsets.all(widget.borderWidth),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withOpacity(0.12),
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
  }

  Widget _buildCard() {
    final animated = widget.animateBorder && _borderController != null;
    if (!animated) {
      return _cardWithGradient(AppGradients.borderAt(_staticGradientStop));
    }
    return AnimatedBuilder(
      animation: _borderController!,
      builder: (context, _) =>
          _cardWithGradient(AppGradients.borderAt(_borderController!.value)),
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
