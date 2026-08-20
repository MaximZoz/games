import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/widgets/card_suit_paths.dart';

/// Иконка «Дурак» — атака и покрывающая карта (не общий веер и не Уно).
class DurakGameIcon extends StatelessWidget {
  const DurakGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;

  /// Раньше тинтовали Material-иконку; цветные карты его не используют.
  final Color? color;

  /// Fallback для мест, где нужен только [IconData].
  static const IconData iconData = Icons.style_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        key: ValueKey(color),
        painter: const _DurakGameIconPainter(),
      ),
    );
  }
}

class _DurakGameIconPainter extends CustomPainter {
  const _DurakGameIconPainter();

  static const _card = Color(0xFFFFF8F0);
  static const _edge = Color(0xFF2C2C2C);
  static const _heart = Color(0xFFD32F2F);
  static const _spade = Color(0xFF1B1B1B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cardW = s * 0.42;
    final cardH = s * 0.58;
    final radius = Radius.circular(s * 0.07);
    final center = Offset(s / 2, s / 2 + s * 0.02);

    void drawCard({
      required double angleDeg,
      required Offset shift,
      required Color suitColor,
      required Path Function(Offset center, double size) suit,
    }) {
      canvas.save();
      canvas.translate(center.dx + shift.dx, center.dy + shift.dy);
      canvas.rotate(angleDeg * math.pi / 180);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
        radius,
      );
      canvas.drawRRect(rect, Paint()..color = _card);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..color = _edge.withValues(alpha: 0.88),
      );
      canvas.drawPath(
        suit(Offset.zero, s * 0.22),
        Paint()..color = suitColor,
      );
      canvas.restore();
    }

    // Нижняя — заход, верхняя кроет: суть дурака.
    drawCard(
      angleDeg: -22,
      shift: Offset(-s * 0.10, s * 0.04),
      suitColor: _heart,
      suit: heartSuitPath,
    );
    drawCard(
      angleDeg: 18,
      shift: Offset(s * 0.11, -s * 0.02),
      suitColor: _spade,
      suit: spadeSuitPath,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
