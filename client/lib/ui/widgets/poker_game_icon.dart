import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/widgets/card_suit_paths.dart';

/// Иконка «Покер» — две карманные карты и фишка (не кости казино).
class PokerGameIcon extends StatelessWidget {
  const PokerGameIcon({
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
        painter: const _PokerGameIconPainter(),
      ),
    );
  }
}

class _PokerGameIconPainter extends CustomPainter {
  const _PokerGameIconPainter();

  static const _card = Color(0xFFFFF8F0);
  static const _edge = Color(0xFF2C2C2C);
  static const _heart = Color(0xFFD32F2F);
  static const _spade = Color(0xFF1B1B1B);
  static const _chip = Color(0xFFE53935);
  static const _chipRing = Color(0xFFFFF3C4);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cardW = s * 0.36;
    final cardH = s * 0.50;
    final radius = Radius.circular(s * 0.065);
    final cardsAt = Offset(s * 0.40, s * 0.40);

    void drawCard({
      required double angleDeg,
      required Offset shift,
      required Color suitColor,
      required Path Function(Offset center, double size) suit,
    }) {
      canvas.save();
      canvas.translate(cardsAt.dx + shift.dx, cardsAt.dy + shift.dy);
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
          ..strokeWidth = s * 0.04
          ..color = _edge.withValues(alpha: 0.88),
      );
      final rank = TextPainter(
        text: TextSpan(
          text: 'A',
          style: TextStyle(
            color: suitColor,
            fontSize: s * 0.16,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rank.paint(canvas, Offset(-cardW * 0.38, -cardH * 0.42));
      rank.dispose();
      canvas.drawPath(
        suit(Offset(0, s * 0.04), s * 0.17),
        Paint()..color = suitColor,
      );
      canvas.restore();
    }

    drawCard(
      angleDeg: -16,
      shift: Offset(-s * 0.10, s * 0.01),
      suitColor: _spade,
      suit: spadeSuitPath,
    );
    drawCard(
      angleDeg: 14,
      shift: Offset(s * 0.10, 0),
      suitColor: _heart,
      suit: heartSuitPath,
    );

    final chipC = Offset(s * 0.72, s * 0.74);
    final chipR = s * 0.20;
    canvas.drawCircle(chipC, chipR, Paint()..color = _chip);
    canvas.drawCircle(
      chipC,
      chipR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = _chipRing,
    );
    canvas.drawCircle(
      chipC,
      chipR * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = _chipRing.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
