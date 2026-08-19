import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Иконка «Уно» — веер из трёх цветных карт с овалом (не как у Дурака).
class UnoGameIcon extends StatelessWidget {
  const UnoGameIcon({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _UnoGameIconPainter(),
      ),
    );
  }
}

class _UnoGameIconPainter extends CustomPainter {
  static const _red = Color(0xFFE53935);
  static const _yellow = Color(0xFFFDD835);
  static const _blue = Color(0xFF1E88E5);
  static const _green = Color(0xFF43A047);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cardW = s * 0.40;
    final cardH = s * 0.56;
    final radius = Radius.circular(s * 0.075);
    final center = Offset(s / 2, s / 2 + s * 0.02);

    void drawCard(Color fill, double angleDeg, Offset shift, {bool front = false}) {
      canvas.save();
      canvas.translate(center.dx + shift.dx, center.dy + shift.dy);
      canvas.rotate(angleDeg * math.pi / 180);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
        radius,
      );
      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04
          ..color = Colors.white.withValues(alpha: 0.95),
      );
      if (front) {
        final oval = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: cardW * 0.72,
            height: cardH * 0.36,
          ),
          Radius.circular(s * 0.08),
        );
        canvas.drawRRect(oval, Paint()..color = _yellow);
        final uPainter = TextPainter(
          text: TextSpan(
            text: 'U',
            style: TextStyle(
              color: _red,
              fontSize: s * 0.28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        uPainter.paint(
          canvas,
          Offset(-uPainter.width / 2, -uPainter.height / 2),
        );
        uPainter.dispose();
      }
      canvas.restore();
    }

    drawCard(_blue, -32, Offset(-s * 0.16, s * 0.03));
    drawCard(_green, 30, Offset(s * 0.16, s * 0.03));
    drawCard(_red, 0, Offset.zero, front: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
