import 'package:flutter/material.dart';

/// Иконка «Нарды» — доска с крупными пунктами и стопкой шашек.
///
/// На 24–26 px мелкие детали сливаются, поэтому на доске всего шесть пунктов
/// и две шашки: силуэт читается даже в чипе.
class NardyGameIcon extends StatelessWidget {
  const NardyGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  /// Запасной [IconData] для мест, где нужен только символ.
  static const IconData iconData = Icons.casino_rounded;

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

  /// Пунктов вдоль края. Больше четырёх — на 24 px сливается в полоску.
  static const int _pointsPerSide = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeW = s * 0.085;
    final boardW = s * 0.92;
    final boardH = s * 0.78;
    final left = (size.width - boardW) / 2;
    final top = (size.height - boardH) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boardW, boardH),
      Radius.circular(s * 0.14),
    );

    // Слой нужен, чтобы «вырез» под шашками стирал только саму иконку.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRRect(board, Paint()..color = color.withValues(alpha: 0.14));

    // Пункты рисуем внутри рамки, иначе острые углы лезут на скругления.
    final innerLeft = left + strokeW;
    final innerTop = top + strokeW;
    final innerW = boardW - strokeW * 2;
    final innerH = boardH - strokeW * 2;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(innerLeft, innerTop, innerW, innerH),
        Radius.circular(s * 0.09),
      ),
    );

    final pointW = innerW / _pointsPerSide;
    final pointH = innerH * 0.46;
    for (var i = 0; i < _pointsPerSide; i++) {
      final x = innerLeft + i * pointW;
      final strong = i.isEven;
      _drawPoint(
        canvas,
        x: x,
        y: innerTop,
        w: pointW,
        h: pointH,
        down: true,
        alpha: strong ? 0.95 : 0.4,
      );
      _drawPoint(
        canvas,
        x: x,
        y: innerTop + innerH - pointH,
        w: pointW,
        h: pointH,
        down: false,
        alpha: strong ? 0.4 : 0.95,
      );
    }
    canvas.restore();

    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Стопка шашек в углу — как на настоящей доске. По центру они смотрелись
    // как объектив, а не как нарды.
    final checkerR = s * 0.085;
    final checkerX = innerLeft + pointW * 0.5;
    final checkerY = innerTop + innerH - checkerR - s * 0.02;
    _drawChecker(canvas, Offset(checkerX, checkerY), checkerR, s);
    _drawChecker(
      canvas,
      Offset(checkerX, checkerY - checkerR * 1.85),
      checkerR,
      s,
    );
    canvas.restore();
  }

  void _drawPoint(
    Canvas canvas, {
    required double x,
    required double y,
    required double w,
    required double h,
    required bool down,
    required double alpha,
  }) {
    final inset = w * 0.08;
    final path = Path();
    if (down) {
      path
        ..moveTo(x + inset, y)
        ..lineTo(x + w - inset, y)
        ..lineTo(x + w / 2, y + h)
        ..close();
    } else {
      path
        ..moveTo(x + inset, y + h)
        ..lineTo(x + w - inset, y + h)
        ..lineTo(x + w / 2, y)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  /// Шашка с «вырезом» по контуру: кольцо отделяет её от пунктов под ней.
  void _drawChecker(Canvas canvas, Offset center, double radius, double s) {
    canvas.drawCircle(
      center,
      radius + s * 0.035,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NardyGameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
