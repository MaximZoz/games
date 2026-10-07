import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Флакон эликсира: стекло, жидкость и знак набора.
class ElixirIcon extends StatelessWidget {
  const ElixirIcon({
    super.key,
    required this.set,
    required this.effect,
    this.size = 48,
  });

  final String set;
  final String effect;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ElixirPainter(set: set, effect: effect),
      ),
    );
  }
}

class _ElixirTheme {
  const _ElixirTheme({
    required this.liquid,
    required this.deep,
    required this.glass,
    required this.accent,
    required this.cork,
    required this.glow,
  });

  final Color liquid;
  final Color deep;
  final Color glass;
  final Color accent;
  final Color cork;
  final Color glow;
}

_ElixirTheme _themeFor(String set) {
  switch (set) {
    case 'nature':
      return const _ElixirTheme(
        liquid: Color(0xFF43A047),
        deep: Color(0xFF1B5E20),
        glass: Color(0xFFE8F5E9),
        accent: Color(0xFF8BC34A),
        cork: Color(0xFF6D4C41),
        glow: Color(0xFF81C784),
      );
    case 'legends':
      return const _ElixirTheme(
        liquid: Color(0xFF7E57C2),
        deep: Color(0xFF311B92),
        glass: Color(0xFFEDE7F6),
        accent: Color(0xFFFFD54F),
        cork: Color(0xFF5D4037),
        glow: Color(0xFFB39DDB),
      );
    case 'cosmic':
      return const _ElixirTheme(
        liquid: Color(0xFF3949AB),
        deep: Color(0xFF0D1642),
        glass: Color(0xFFE8EAF6),
        accent: Color(0xFF80DEEA),
        cork: Color(0xFF4E342E),
        glow: Color(0xFF7986CB),
      );
    case 'adventure':
      return const _ElixirTheme(
        liquid: Color(0xFFEF6C00),
        deep: Color(0xFFBF360C),
        glass: Color(0xFFFBE9E7),
        accent: Color(0xFF26C6DA),
        cork: Color(0xFF5D4037),
        glow: Color(0xFFFFAB40),
      );
    case 'jewels':
      return const _ElixirTheme(
        liquid: Color(0xFFC62828),
        deep: Color(0xFF6A1B3A),
        glass: Color(0xFFFCE4EC),
        accent: Color(0xFFE0F7FA),
        cork: Color(0xFFFFD54F),
        glow: Color(0xFFF48FB1),
      );
    case 'celebration':
    default:
      return const _ElixirTheme(
        liquid: Color(0xFFE91E63),
        deep: Color(0xFFAD1457),
        glass: Color(0xFFFFE4F2),
        accent: Color(0xFFFFD54F),
        cork: Color(0xFF8D6E63),
        glow: Color(0xFFFF80AB),
      );
  }
}

class _ElixirPainter extends CustomPainter {
  _ElixirPainter({required this.set, required this.effect});

  final String set;
  final String effect;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = _themeFor(set);
    final s = size.shortestSide;
    final ox = (size.width - s) / 2;
    final oy = (size.height - s) / 2;
    canvas.save();
    canvas.translate(ox, oy);

    final glow = Paint()
      ..color = theme.glow.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.62),
        width: s * 0.72,
        height: s * 0.42,
      ),
      glow,
    );

    final bottle = _bottlePath(s);
    canvas.save();
    canvas.clipPath(bottle);
    final glass = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          theme.glass.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.12),
        ],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), glass);

    final liquidTop = s * (effect == 'age' ? 0.40 : 0.46);
    final liquid = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(theme.liquid, Colors.white, 0.25)!,
          theme.liquid,
          theme.deep,
        ],
      ).createShader(Rect.fromLTWH(0, liquidTop, s, s));
    final wave = Path()
      ..moveTo(0, liquidTop + s * 0.03)
      ..quadraticBezierTo(s * 0.25, liquidTop - s * 0.03, s * 0.5, liquidTop)
      ..quadraticBezierTo(
          s * 0.75, liquidTop + s * 0.04, s, liquidTop - s * 0.01)
      ..lineTo(s, s)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(wave, liquid);

    if (effect == 'age') {
      canvas.drawRect(
        Rect.fromLTWH(s * 0.22, s * 0.78, s * 0.56, s * 0.08),
        Paint()..color = const Color(0xFF3E2723).withValues(alpha: 0.45),
      );
    }

    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final bubbles = effect == 'accelerate'
        ? const [
            Offset(0.38, 0.58),
            Offset(0.55, 0.66),
            Offset(0.46, 0.74),
            Offset(0.62, 0.56),
          ]
        : const [
            Offset(0.40, 0.62),
            Offset(0.58, 0.70),
            Offset(0.48, 0.78),
          ];
    for (final b in bubbles) {
      canvas.drawCircle(Offset(s * b.dx, s * b.dy), s * 0.018, bubble);
    }
    canvas.restore();

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * 0.028)
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(bottle, rim);
    canvas.drawPath(
      bottle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, s * 0.012)
        ..color = theme.deep.withValues(alpha: 0.55),
    );

    final highlight = Path()
      ..moveTo(s * 0.38, s * 0.36)
      ..quadraticBezierTo(s * 0.34, s * 0.55, s * 0.36, s * 0.78);
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, s * 0.035)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    _paintCork(canvas, s, theme);
    _paintMotif(canvas, s, theme);
    _paintEffect(canvas, s, theme);
    canvas.restore();
  }

  Path _bottlePath(double s) {
    return Path()
      ..moveTo(s * 0.40, s * 0.16)
      ..lineTo(s * 0.40, s * 0.30)
      ..quadraticBezierTo(s * 0.18, s * 0.38, s * 0.20, s * 0.58)
      ..quadraticBezierTo(s * 0.20, s * 0.90, s * 0.50, s * 0.90)
      ..quadraticBezierTo(s * 0.80, s * 0.90, s * 0.80, s * 0.58)
      ..quadraticBezierTo(s * 0.82, s * 0.38, s * 0.60, s * 0.30)
      ..lineTo(s * 0.60, s * 0.16)
      ..quadraticBezierTo(s * 0.50, s * 0.12, s * 0.40, s * 0.16)
      ..close();
  }

  void _paintCork(Canvas canvas, double s, _ElixirTheme theme) {
    final cork = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.38, s * 0.07, s * 0.24, s * 0.11),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(
      cork,
      Paint()
        ..shader = LinearGradient(
          colors: [theme.cork.withValues(alpha: 0.7), theme.cork],
        ).createShader(Rect.fromLTWH(s * 0.38, s * 0.07, s * 0.24, s * 0.11)),
    );
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.10),
      s * 0.045,
      Paint()..color = theme.accent,
    );
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.10),
      s * 0.02,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _paintMotif(Canvas canvas, double s, _ElixirTheme theme) {
    final center = Offset(s * 0.56, s * 0.64);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    switch (set) {
      case 'nature':
        final leaf = Path()
          ..moveTo(center.dx, center.dy - s * 0.07)
          ..quadraticBezierTo(
            center.dx + s * 0.08,
            center.dy,
            center.dx,
            center.dy + s * 0.07,
          )
          ..quadraticBezierTo(
            center.dx - s * 0.08,
            center.dy,
            center.dx,
            center.dy - s * 0.07,
          );
        canvas.drawPath(leaf, paint);
        break;
      case 'cosmic':
        canvas.drawCircle(center, s * 0.02, paint);
        canvas.drawCircle(
          center.translate(-s * 0.06, s * 0.04),
          s * 0.012,
          paint,
        );
        canvas.drawCircle(
          center.translate(s * 0.05, -s * 0.03),
          s * 0.01,
          paint,
        );
        break;
      case 'adventure':
        canvas.drawCircle(
          center,
          s * 0.055,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, s * 0.018)
            ..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.drawLine(
          center.translate(0, -s * 0.04),
          center.translate(0, s * 0.02),
          Paint()
            ..strokeWidth = math.max(1, s * 0.016)
            ..strokeCap = StrokeCap.round
            ..color = Colors.white,
        );
        break;
      case 'legends':
        final rune = Path()
          ..moveTo(center.dx, center.dy - s * 0.07)
          ..lineTo(center.dx + s * 0.055, center.dy + s * 0.05)
          ..lineTo(center.dx - s * 0.055, center.dy + s * 0.05)
          ..close();
        canvas.drawPath(rune, paint);
        break;
      case 'jewels':
        final gem = Path()
          ..moveTo(center.dx, center.dy - s * 0.07)
          ..lineTo(center.dx + s * 0.06, center.dy)
          ..lineTo(center.dx, center.dy + s * 0.07)
          ..lineTo(center.dx - s * 0.06, center.dy)
          ..close();
        canvas.drawPath(
          gem,
          Paint()..color = theme.accent.withValues(alpha: 0.95),
        );
        break;
      default:
        canvas.drawCircle(center, s * 0.018, Paint()..color = theme.accent);
        canvas.drawCircle(
          center.translate(-s * 0.05, -s * 0.04),
          s * 0.012,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          center.translate(s * 0.045, s * 0.03),
          s * 0.01,
          Paint()..color = const Color(0xFF80DEEA),
        );
    }
  }

  void _paintEffect(Canvas canvas, double s, _ElixirTheme theme) {
    final paint = Paint()
      ..color = theme.accent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.1, s * 0.02);
    if (effect == 'rejuvenate') {
      canvas.drawLine(
        Offset(s * 0.22, s * 0.42),
        Offset(s * 0.22, s * 0.30),
        paint,
      );
      canvas.drawLine(
        Offset(s * 0.17, s * 0.36),
        Offset(s * 0.27, s * 0.36),
        paint,
      );
    } else if (effect == 'age') {
      final crack = Paint()
        ..color = const Color(0xFF3E2723).withValues(alpha: 0.8)
        ..strokeWidth = math.max(0.8, s * 0.012)
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(s * 0.30, s * 0.48)
        ..lineTo(s * 0.36, s * 0.58)
        ..lineTo(s * 0.31, s * 0.68);
      canvas.drawPath(path, crack);
    } else if (effect == 'accelerate') {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * 0.78, s * 0.40),
          width: s * 0.16,
          height: s * 0.16,
        ),
        -1.2,
        2.4,
        false,
        paint,
      );
      canvas.drawLine(
        Offset(s * 0.70, s * 0.34),
        Offset(s * 0.78, s * 0.28),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElixirPainter oldDelegate) {
    return oldDelegate.set != set || oldDelegate.effect != effect;
  }
}
