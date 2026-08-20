import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/uno/uno_card.dart';

class UnoCardWidget extends StatelessWidget {
  const UnoCardWidget({
    super.key,
    required this.card,
    this.size = const Size(72, 108),
    this.faceDown = false,
    this.elevated = true,
    this.highlighted = false,
  });

  final UnoCard card;
  final Size size;
  final bool faceDown;
  final bool elevated;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: UnoCardPainter(
            card: card,
            faceDown: faceDown,
            elevated: elevated,
            highlighted: highlighted,
          ),
        ),
      ),
    );
  }
}

class UnoCardBackWidget extends StatelessWidget {
  const UnoCardBackWidget({
    super.key,
    this.size = const Size(72, 108),
    this.elevated = true,
  });

  final Size size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return UnoCardWidget(
      card: const UnoCard(
        id: 'back',
        color: UnoColor.wild,
        kind: UnoCardKind.wild,
      ),
      size: size,
      faceDown: true,
      elevated: elevated,
    );
  }
}

class UnoCardPainter extends CustomPainter {
  const UnoCardPainter({
    required this.card,
    required this.faceDown,
    required this.elevated,
    required this.highlighted,
  });

  final UnoCard card;
  final bool faceDown;
  final bool elevated;
  final bool highlighted;

  static const _red = Color(0xFFE53935);
  static const _yellow = Color(0xFFF9A825);
  static const _green = Color(0xFF2E7D32);
  static const _blue = Color(0xFF1565C0);
  static const _black = Color(0xFF181B22);

  Color get _faceColor => switch (card.color) {
        UnoColor.red => _red,
        UnoColor.yellow => _yellow,
        UnoColor.green => _green,
        UnoColor.blue => _blue,
        UnoColor.wild => _black,
      };

  /// Контрастный цвет символа на белом овале / в углу на цветном фоне.
  Color get _inkOnWhite => switch (card.color) {
        UnoColor.yellow => const Color(0xFF5D4037),
        UnoColor.wild => _black,
        _ => _faceColor,
      };

  Color get _inkOnFace =>
      card.color == UnoColor.yellow ? Colors.black87 : Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;
    final cardRect = Rect.fromLTWH(
      scale * 0.035,
      scale * 0.035,
      size.width - scale * 0.07,
      size.height - scale * 0.07,
    );
    final radius = Radius.circular(scale * 0.12);
    final cardRRect = RRect.fromRectAndRadius(cardRect, radius);

    if (elevated) {
      canvas.drawShadow(
        Path()..addRRect(cardRRect),
        Colors.black.withValues(alpha: 0.45),
        scale * 0.06,
        false,
      );
    }
    canvas.drawRRect(
      cardRRect,
      Paint()..color = faceDown ? _black : _faceColor,
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? scale * 0.07 : scale * 0.04
        ..color = highlighted
            ? const Color(0xFFFFE45C)
            : Colors.white.withValues(alpha: 0.98),
    );

    canvas.save();
    canvas.clipRRect(cardRRect);
    if (faceDown) {
      _paintBack(canvas, size, scale);
    } else {
      _paintFace(canvas, size, scale);
    }
    canvas.restore();
  }

  void _paintBack(Canvas canvas, Size size, double scale) {
    final stripe = Paint()
      ..color = const Color(0xFFCB262D)
      ..strokeWidth = scale * 0.12;
    for (var x = -size.height; x < size.width + size.height; x += scale * 0.3) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    final oval = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.78,
      height: size.height * 0.48,
    );
    canvas.save();
    canvas.translate(oval.center.dx, oval.center.dy);
    canvas.rotate(-math.pi / 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: oval.width,
        height: oval.height,
      ),
      Paint()..color = const Color(0xFFF5C329),
    );
    _paintPlainText(
      canvas,
      'UNO',
      Offset.zero,
      scale * 0.34,
      color: const Color(0xFFCC202C),
    );
    canvas.restore();
  }

  void _paintFace(Canvas canvas, Size size, double scale) {
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.78,
        height: size.height * 0.64,
      ),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    if (card.isWild) {
      _paintWild(canvas, center, scale);
    } else {
      _paintCenterBadge(canvas, center, scale);
    }

    _paintCorner(canvas, Offset(scale * 0.22, scale * 0.24), scale);
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    _paintCorner(canvas, Offset(scale * 0.22, scale * 0.24), scale);
    canvas.restore();
  }

  void _paintCenterBadge(Canvas canvas, Offset center, double scale) {
    switch (card.kind) {
      case UnoCardKind.number:
        _paintPlainText(
          canvas,
          '${card.number}',
          center,
          scale * 0.78,
          color: _inkOnWhite,
        );
      case UnoCardKind.drawTwo:
        _paintPlainText(
          canvas,
          '+2',
          center,
          scale * 0.58,
          color: _inkOnWhite,
        );
      case UnoCardKind.skip:
        _paintSkipIcon(canvas, center, scale * 0.52, _inkOnWhite);
      case UnoCardKind.reverse:
        _paintReverseIcon(canvas, center, scale * 0.52, _inkOnWhite);
      case UnoCardKind.wild:
      case UnoCardKind.wildDrawFour:
        break;
    }
  }

  void _paintCorner(Canvas canvas, Offset at, double scale) {
    switch (card.kind) {
      case UnoCardKind.number:
        _paintPlainText(
          canvas,
          '${card.number}',
          at,
          scale * 0.26,
          color: _inkOnFace,
        );
      case UnoCardKind.drawTwo:
        _paintPlainText(
          canvas,
          '+2',
          at,
          scale * 0.22,
          color: _inkOnFace,
        );
      case UnoCardKind.skip:
        _paintSkipIcon(canvas, at, scale * 0.22, _inkOnFace);
      case UnoCardKind.reverse:
        _paintReverseIcon(canvas, at, scale * 0.22, _inkOnFace);
      case UnoCardKind.wild:
        _paintPlainText(canvas, 'W', at, scale * 0.22, color: Colors.white);
      case UnoCardKind.wildDrawFour:
        _paintPlainText(canvas, '+4', at, scale * 0.2, color: Colors.white);
    }
  }

  /// Skip — круг с диагональной чертой (без unicode ⊘).
  void _paintSkipIcon(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.16
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, size * 0.42, paint);
    canvas.drawLine(
      Offset(center.dx - size * 0.28, center.dy + size * 0.28),
      Offset(center.dx + size * 0.28, center.dy - size * 0.28),
      paint,
    );
  }

  /// Reverse — две дуги со стрелками (без unicode ↻).
  void _paintReverseIcon(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.14
      ..strokeCap = StrokeCap.round;
    final r = size * 0.34;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi * 0.85,
      math.pi * 0.95,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi * 0.15,
      math.pi * 0.95,
      false,
      paint,
    );
    final tip = size * 0.18;
    // Верхняя стрелка.
    final a1 = Offset(center.dx + r * 0.15, center.dy - r);
    canvas.drawPath(
      Path()
        ..moveTo(a1.dx - tip * 0.2, a1.dy + tip)
        ..lineTo(a1.dx, a1.dy)
        ..lineTo(a1.dx + tip, a1.dy + tip * 0.15),
      paint,
    );
    // Нижняя стрелка.
    final a2 = Offset(center.dx - r * 0.15, center.dy + r);
    canvas.drawPath(
      Path()
        ..moveTo(a2.dx + tip * 0.2, a2.dy - tip)
        ..lineTo(a2.dx, a2.dy)
        ..lineTo(a2.dx - tip, a2.dy - tip * 0.15),
      paint,
    );
  }

  void _paintWild(Canvas canvas, Offset center, double scale) {
    final colors = [_red, _yellow, _green, _blue];
    final rect = Rect.fromCenter(
      center: center,
      width: scale * 0.62,
      height: scale * 0.62,
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * math.pi / 2,
        math.pi / 2,
        true,
        Paint()..color = colors[i],
      );
    }
    canvas.drawCircle(
      center,
      scale * 0.31,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.035
        ..color = Colors.white,
    );
    if (card.kind == UnoCardKind.wildDrawFour) {
      _paintPlainText(
        canvas,
        '+4',
        center,
        scale * 0.4,
        color: Colors.white,
      );
    }
  }

  /// Только заливка текста — без stroke (stroke давал «двойную» тень на Web).
  void _paintPlainText(
    Canvas canvas,
    String value,
    Offset center,
    double fontSize, {
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: value.length > 1 ? -fontSize * 0.04 : 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant UnoCardPainter oldDelegate) =>
      oldDelegate.card != card ||
      oldDelegate.faceDown != faceDown ||
      oldDelegate.elevated != elevated ||
      oldDelegate.highlighted != highlighted;
}
