import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Медленно плывущие «облака» — мягкие светлые пятна для фона и тулбара.
class FloatingClouds extends StatefulWidget {
  const FloatingClouds({
    super.key,
    required this.child,
    this.intensity = 0.5,
  });

  final Widget child;
  final double intensity;

  @override
  State<FloatingClouds> createState() => _FloatingCloudsState();
}

class _FloatingCloudsState extends State<FloatingClouds>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _CloudsPainter(
                t: _controller.value,
                intensity: widget.intensity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudsPainter extends CustomPainter {
  _CloudsPainter({required this.t, this.intensity = 0.5});

  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.max(size.width, size.height) * 0.6;

    for (var i = 0; i < 5; i++) {
      final phase = i * 0.2 + t * 2 * math.pi;
      final x = centerX + math.cos(phase) * radius * 0.35;
      final y = centerY + math.sin(phase * 0.7) * radius * 0.3;
      final r = 80.0 + i * 30.0 + math.sin(phase * 1.3) * 20;
      final alpha = (0.12 + intensity * 0.18) * (0.85 + 0.15 * math.sin(phase * 2));

      final rect = Rect.fromCircle(center: Offset(x, y), radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}

/// Только слой «облаков» без ребёнка — для вставки в тулбар или другой контейнер.
class FloatingCloudsLayer extends StatefulWidget {
  const FloatingCloudsLayer({super.key, this.intensity = 0.5});
  final double intensity;

  @override
  State<FloatingCloudsLayer> createState() => _FloatingCloudsLayerState();
}

class _FloatingCloudsLayerState extends State<FloatingCloudsLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CloudsPainter(
              t: _controller.value,
              intensity: widget.intensity,
            ),
          ),
        );
      },
    );
  }
}
