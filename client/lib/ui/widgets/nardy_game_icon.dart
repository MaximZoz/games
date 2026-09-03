import 'package:flutter/material.dart';

/// Иконка «Нарды» — миниатюрная доска с треугольниками и шашками.
class NardyGameIcon extends StatelessWidget {
  const NardyGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  /// Запасной [IconData] для мест, где нужен только символ.
  static const IconData iconData = Icons.view_module_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NardyGameIconPainter(color: color ?? Colors.white),
      ),
    );
  }
}

class _NardyGameIconPainter extends CustomPainter {
  _NardyGameIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final boardW = s * 0.86;
    final boardH = s * 0.62;
    final left = (size.width - boardW) / 2;
    final top = (size.height - boardH) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boardW, boardH),
      Radius.circular(s * 0.06),
    );

    final fill = Paint()..color = color.withValues(alpha: 0.18);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..color = color.withValues(alpha: 0.95);
    canvas.drawRRect(board, fill);
    canvas.drawRRect(board, stroke);

    final barW = s * 0.05;
    final barLeft = left + boardW / 2 - barW / 2;
    canvas.drawRect(
      Rect.fromLTWH(barLeft, top, barW, boardH),
      Paint()..color = color.withValues(alpha: 0.55),
    );

    const pointsPerSide = 6;
    final pointW = boardW / pointsPerSide;
    final halfH = boardH / 2;

    void drawTriangle({
      required double x,
      required double y,
      required double w,
      required double h,
      required bool pointsDown,
      required double alpha,
    }) {
      final path = Path();
      if (pointsDown) {
        path
          ..moveTo(x, y)
          ..lineTo(x + w, y)
          ..lineTo(x + w / 2, y + h)
          ..close();
      } else {
        path
          ..moveTo(x, y + h)
          ..lineTo(x + w, y + h)
          ..lineTo(x + w / 2, y)
          ..close();
      }
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..color = color.withValues(alpha: 0.35),
      );
    }

    for (var i = 0; i < pointsPerSide; i++) {
      final x = left + i * pointW;
      final light = i.isEven;
      drawTriangle(
        x: x,
        y: top,
        w: pointW,
        h: halfH,
        pointsDown: true,
        alpha: light ? 0.92 : 0.42,
      );
      drawTriangle(
        x: x,
        y: top + halfH,
        w: pointW,
        h: halfH,
        pointsDown: false,
        alpha: light ? 0.42 : 0.92,
      );
    }

    void drawChecker(Offset center, {required bool filled}) {
      final radius = s * 0.055;
      if (filled) {
        canvas.drawCircle(center, radius, Paint()..color = color);
      } else {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.035
            ..color = color,
        );
        canvas.drawCircle(
          center,
          radius * 0.55,
          Paint()..color = color.withValues(alpha: 0.25),
        );
      }
    }

    final baseX = left + pointW * 1.5;
    final baseY = top + boardH - halfH * 0.22;
    drawChecker(Offset(baseX, baseY), filled: true);
    drawChecker(Offset(baseX, baseY - s * 0.11), filled: true);

    final topX = left + pointW * 4.5;
    final topY = top + halfH * 0.24;
    drawChecker(Offset(topX, topY), filled: false);
    drawChecker(Offset(topX, topY + s * 0.11), filled: false);
  }

  @override
  bool shouldRepaint(covariant _NardyGameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
