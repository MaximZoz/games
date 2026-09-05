import 'package:flutter/material.dart';

/// Иконка «Шашки» — мини-доска с двумя шашками на тёмных клетках.
class CheckersGameIcon extends StatelessWidget {
  const CheckersGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  static const IconData iconData = Icons.circle_outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CheckersGameIconPainter(color: color ?? Colors.white),
      ),
    );
  }
}

class _CheckersGameIconPainter extends CustomPainter {
  _CheckersGameIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeW = s * 0.08;
    final boardS = s * 0.88;
    final left = (size.width - boardS) / 2;
    final top = (size.height - boardS) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boardS, boardS),
      Radius.circular(s * 0.12),
    );

    canvas.drawRRect(board, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = color,
    );

    const n = 4;
    final cell = boardS / n;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if ((r + c) % 2 == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(left + c * cell, top + r * cell, cell, cell),
          Paint()..color = color.withValues(alpha: 0.28),
        );
      }
    }

    final pieceR = cell * 0.32;
    canvas.drawCircle(
      Offset(left + 1.5 * cell, top + 0.5 * cell),
      pieceR,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(left + 2.5 * cell, top + 3.5 * cell),
      pieceR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckersGameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
