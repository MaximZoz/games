import 'package:flutter/material.dart';

/// Иконка «Шахматы» — доска и король.
///
/// На 24–26 px сетка 8×8 сливается, поэтому рисуем 4×4 и одну крупную фигуру.
class ChessGameIcon extends StatelessWidget {
  const ChessGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  /// Запасной [IconData] для мест, где нужен только символ.
  static const IconData iconData = Icons.castle_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChessGameIconPainter(color: color ?? Colors.white),
      ),
    );
  }
}

class _ChessGameIconPainter extends CustomPainter {
  _ChessGameIconPainter({required this.color});

  final Color color;

  static const int _cells = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeW = s * 0.085;
    final boardSide = s * 0.92;
    final left = (size.width - boardSide) / 2;
    final top = (size.height - boardSide) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boardSide, boardSide),
      Radius.circular(s * 0.14),
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRRect(board, Paint()..color = color.withValues(alpha: 0.14));

    final inner = boardSide - strokeW * 2;
    final cell = inner / _cells;
    final originX = left + strokeW;
    final originY = top + strokeW;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(originX, originY, inner, inner),
        Radius.circular(s * 0.08),
      ),
    );
    final dark = Paint()..color = color.withValues(alpha: 0.88);
    for (var row = 0; row < _cells; row++) {
      for (var col = 0; col < _cells; col++) {
        if ((row + col).isEven) continue;
        canvas.drawRect(
          Rect.fromLTWH(originX + col * cell, originY + row * cell, cell, cell),
          dark,
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = color,
    );

    _drawKing(canvas, size.center(Offset.zero), s * 0.22, color);
    canvas.restore();
  }

  void _drawKing(Canvas canvas, Offset c, double r, Color color) {
    final fill = Paint()..color = color;
    final cross = Path()
      ..moveTo(c.dx - r * 0.16, c.dy - r * 1.05)
      ..lineTo(c.dx + r * 0.16, c.dy - r * 1.05)
      ..lineTo(c.dx + r * 0.16, c.dy - r * 0.72)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.72)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.42)
      ..lineTo(c.dx + r * 0.16, c.dy - r * 0.42)
      ..lineTo(c.dx + r * 0.16, c.dy - r * 0.18)
      ..lineTo(c.dx - r * 0.16, c.dy - r * 0.18)
      ..lineTo(c.dx - r * 0.16, c.dy - r * 0.42)
      ..lineTo(c.dx - r * 0.42, c.dy - r * 0.42)
      ..lineTo(c.dx - r * 0.42, c.dy - r * 0.72)
      ..lineTo(c.dx - r * 0.16, c.dy - r * 0.72)
      ..close();
    canvas.drawPath(cross, fill);

    final crown = Path()
      ..moveTo(c.dx - r * 0.72, c.dy - r * 0.12)
      ..lineTo(c.dx - r * 0.38, c.dy - r * 0.38)
      ..lineTo(c.dx, c.dy - r * 0.08)
      ..lineTo(c.dx + r * 0.38, c.dy - r * 0.38)
      ..lineTo(c.dx + r * 0.72, c.dy - r * 0.12)
      ..lineTo(c.dx + r * 0.55, c.dy + r * 0.18)
      ..lineTo(c.dx - r * 0.55, c.dy + r * 0.18)
      ..close();
    canvas.drawPath(crown, fill);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.55), width: r * 0.7, height: r * 0.85),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + r * 1.05), width: r * 1.05, height: r * 0.28),
        Radius.circular(r * 0.1),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ChessGameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
