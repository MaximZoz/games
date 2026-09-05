import 'package:flutter/material.dart';

/// Иконка «Шашки» — клеточная доска и две шашки.
///
/// На 24–26 px мелкая сетка 8×8 сливается, поэтому рисуем 4×4
/// и две крупные шашки: силуэт читается в шапке карточки.
class CheckersGameIcon extends StatelessWidget {
  const CheckersGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  /// Запасной [IconData] для мест, где нужен только символ.
  static const IconData iconData = Icons.grid_on_rounded;

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
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final pieceR = cell * 0.32;
    _drawPiece(
      canvas,
      Offset(originX + cell * 1.5, originY + cell * 0.5),
      pieceR,
      s,
      filled: true,
    );
    _drawPiece(
      canvas,
      Offset(originX + cell * 2.5, originY + cell * 3.5),
      pieceR,
      s,
      filled: false,
    );
    canvas.restore();
  }

  void _drawPiece(
    Canvas canvas,
    Offset center,
    double radius,
    double s, {
    required bool filled,
  }) {
    canvas.drawCircle(
      center,
      radius + s * 0.03,
      Paint()..blendMode = BlendMode.clear,
    );
    if (filled) {
      canvas.drawCircle(center, radius, Paint()..color = color);
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.07
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckersGameIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
