import 'package:flutter/material.dart';

/// Иконка «Четыре в ряд» — решётка с четырьмя фишками по диагонали.
class Connect4GameIcon extends StatelessWidget {
  const Connect4GameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  static const IconData iconData = Icons.grid_view_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Connect4GameIconPainter(color: color ?? Colors.white),
      ),
    );
  }
}

class _Connect4GameIconPainter extends CustomPainter {
  _Connect4GameIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeW = s * 0.08;
    final boardW = s * 0.92;
    final boardH = s * 0.78;
    final left = (size.width - boardW) / 2;
    final top = (size.height - boardH) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boardW, boardH),
      Radius.circular(s * 0.14),
    );

    canvas.drawRRect(board, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = color,
    );

    const cols = 4;
    const rows = 3;
    final cellW = boardW / cols;
    final cellH = boardH / rows;
    final discR = s * 0.075;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = left + (c + 0.5) * cellW;
        final cy = top + (r + 0.5) * cellH;
        final filled = r + c == 3 || (r == 2 && c == 0);
        canvas.drawCircle(
          Offset(cx, cy),
          discR,
          Paint()..color = color.withValues(alpha: filled ? 1 : 0.28),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Connect4GameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
