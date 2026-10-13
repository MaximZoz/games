import 'package:flutter/material.dart';

/// Две кости «Козла»: дубль стоит, обычная лежит, зелёное сукно.
class DominoGameIcon extends StatelessWidget {
  const DominoGameIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _DominoIconPainter(),
    );
  }
}

class _DominoIconPainter extends CustomPainter {
  const _DominoIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ground = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(ground, Paint()..color = const Color(0xFF1B5E3B));
    final tile = Paint()..color = const Color(0xFFF7F1E3);
    final pip = Paint()..color = const Color(0xFF243042);
    final vertical = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.16, size.width * 0.28, size.height * 0.68),
      Radius.circular(size.width * 0.06),
    );
    final horizontal = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.34, size.width * 0.42, size.height * 0.32),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(vertical, tile);
    canvas.drawRRect(horizontal, tile);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.34),
      size.width * 0.035,
      pip,
    );
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.66),
      size.width * 0.035,
      pip,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.50),
      size.width * 0.03,
      pip,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.50),
      size.width * 0.03,
      pip,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
