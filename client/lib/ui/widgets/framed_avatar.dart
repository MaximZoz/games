import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Стиль металлической рамки аватара (бронза / серебро / золото).
class AvatarFrameStyle {
  const AvatarFrameStyle({
    required this.code,
    required this.colors,
    required this.glow,
  });

  final String code;
  final List<Color> colors;
  final Color glow;

  static const bronze = AvatarFrameStyle(
    code: 'frame_bronze',
    colors: [
      Color(0xFF5C3317),
      Color(0xFFCD7F32),
      Color(0xFFF0C27A),
      Color(0xFF8B5A2B),
      Color(0xFFE8A86A),
      Color(0xFF5C3317),
    ],
    glow: Color(0x66CD7F32),
  );

  static const silver = AvatarFrameStyle(
    code: 'frame_silver',
    colors: [
      Color(0xFF6B7280),
      Color(0xFFE5E7EB),
      Color(0xFF9CA3AF),
      Color(0xFFF9FAFB),
      Color(0xFFA8B0BC),
      Color(0xFF6B7280),
    ],
    glow: Color(0x669CA3AF),
  );

  static const gold = AvatarFrameStyle(
    code: 'frame_gold',
    colors: [
      Color(0xFF8B6914),
      Color(0xFFFFD700),
      Color(0xFFFFF1A8),
      Color(0xFFDAA520),
      Color(0xFFFFE566),
      Color(0xFF8B6914),
    ],
    glow: Color(0x66FFD700),
  );

  static AvatarFrameStyle? resolve({String? code, String? colorHex}) {
    final c = (code ?? '').trim().toLowerCase();
    switch (c) {
      case 'frame_bronze':
      case 'bronze':
        return bronze;
      case 'frame_silver':
      case 'silver':
        return silver;
      case 'frame_gold':
      case 'gold':
        return gold;
    }
    final hex = (colorHex ?? '').trim().toLowerCase().replaceFirst('#', '');
    if (hex.isEmpty) return null;
    // Эвристика по старым/новым hex из payload.
    if (hex.contains('cd7f32') ||
        hex.contains('b87333') ||
        hex.contains('8b5a2b')) {
      return bronze;
    }
    if (hex.contains('c0c0c0') ||
        hex.contains('a0a0a0') ||
        hex.contains('9ca3af')) {
      return silver;
    }
    if (hex.contains('ffd700') ||
        hex.contains('d4a600') ||
        hex.contains('daa520')) {
      return gold;
    }
    return null;
  }
}

/// Круглая аватарка с анимированной металлической рамкой.
class FramedAvatar extends StatefulWidget {
  const FramedAvatar({
    super.key,
    required this.child,
    this.frameCode,
    this.frameColor,
    this.size = 40,
    this.borderWidth = 3.2,
    this.animate = true,
  });

  final Widget child;
  final String? frameCode;
  final String? frameColor;
  final double size;
  final double borderWidth;
  final bool animate;

  @override
  State<FramedAvatar> createState() => _FramedAvatarState();
}

class _FramedAvatarState extends State<FramedAvatar>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AvatarFrameStyle? get _style => AvatarFrameStyle.resolve(
        code: widget.frameCode,
        colorHex: widget.frameColor,
      );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant FramedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.frameCode != widget.frameCode ||
        oldWidget.frameColor != widget.frameColor) {
      _sync();
    }
  }

  void _sync() {
    final style = _style;
    final want = widget.animate && style != null;
    if (want) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final child = SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(child: widget.child),
    );

    if (style == null) {
      return child;
    }

    final ring = widget.borderWidth;
    final outer = widget.size + ring * 2;
    final controller = _controller;

    Widget framed(double t) {
      return Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: t * math.pi * 2,
            colors: style.colors,
          ),
        ),
        padding: EdgeInsets.all(ring),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceCard,
            border: Border.all(
              color: AppColors.surfaceCard.withValues(alpha: 0.9),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      );
    }

    if (controller == null) {
      return framed(0.08);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => framed(controller.value),
    );
  }
}

/// Мини-превью рамки для карточек достижений / инвентаря.
class FramePreviewBadge extends StatelessWidget {
  const FramePreviewBadge({
    super.key,
    required this.frameCode,
    this.size = 44,
  });

  final String frameCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FramedAvatar(
      size: size * 0.62,
      borderWidth: 3.5,
      frameCode: frameCode,
      child: ColoredBox(
        color: AppColors.accentSoft,
        child: Icon(
          Icons.person_rounded,
          size: size * 0.36,
          color: AppColors.accentStart,
        ),
      ),
    );
  }
}
