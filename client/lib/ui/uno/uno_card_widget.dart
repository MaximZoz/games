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
  static const _yellow = Color(0xFFFBC02D);
  static const _green = Color(0xFF2EAD62);
  static const _blue = Color(0xFF2583E8);
  static const _black = Color(0xFF181B22);

  Color get _faceColor => switch (card.color) {
        UnoColor.red => _red,
        UnoColor.yellow => _yellow,
        UnoColor.green => _green,
        UnoColor.blue => _blue,
        UnoColor.wild => _black,
      };

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
        Colors.black.withValues(alpha: 0.6),
        scale * 0.08,
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
        ..strokeWidth = highlighted ? scale * 0.07 : scale * 0.035
        ..color = highlighted
            ? const Color(0xFFFFE45C)
            : Colors.white.withValues(alpha: 0.96),
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
    _paintText(
      canvas,
      'UNO',
      Offset.zero,
      scale * 0.36,
      color: const Color(0xFFCC202C),
      strokeColor: Colors.white,
      strokeWidth: scale * 0.025,
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
        width: size.width * 0.76,
        height: size.height * 0.62,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.restore();

    if (card.isWild) {
      _paintWild(canvas, center, scale);
    } else {
      _paintText(
        canvas,
        _symbol,
        center,
        scale * (_symbol.length > 1 ? 0.48 : 0.72),
        color: _faceColor,
        strokeColor: _faceColor == _yellow ? Colors.black54 : Colors.black38,
        strokeWidth: scale * 0.018,
      );
    }

    final cornerColor =
        card.color == UnoColor.yellow ? Colors.black87 : Colors.white;
    _paintText(
      canvas,
      _symbol,
      Offset(scale * 0.21, scale * 0.23),
      scale * (_symbol.length > 1 ? 0.2 : 0.25),
      color: cornerColor,
    );
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    _paintText(
      canvas,
      _symbol,
      Offset(scale * 0.21, scale * 0.23),
      scale * (_symbol.length > 1 ? 0.2 : 0.25),
      color: cornerColor,
    );
    canvas.restore();
  }

  String get _symbol => switch (card.kind) {
        UnoCardKind.number => '${card.number}',
        UnoCardKind.skip => '⊘',
        UnoCardKind.reverse => '↻',
        UnoCardKind.drawTwo => '+2',
        UnoCardKind.wild => 'W',
        UnoCardKind.wildDrawFour => '+4',
      };

  void _paintWild(Canvas canvas, Offset center, double scale) {
    final colors = [_red, _yellow, _green, _blue];
    final rect = Rect.fromCenter(
      center: center,
      width: scale * 0.58,
      height: scale * 0.58,
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
    if (card.kind == UnoCardKind.wildDrawFour) {
      _paintText(
        canvas,
        '+4',
        center,
        scale * 0.42,
        color: Colors.white,
        strokeColor: Colors.black87,
        strokeWidth: scale * 0.025,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String value,
    Offset center,
    double fontSize, {
    required Color color,
    Color? strokeColor,
    double strokeWidth = 0,
  }) {
    void paint(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
      );
      painter.dispose();
    }

    if (strokeColor != null && strokeWidth > 0) {
      paint(TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor,
      ));
    }
    paint(TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      height: 1,
    ));
  }

  @override
  bool shouldRepaint(covariant UnoCardPainter oldDelegate) =>
      oldDelegate.card != card ||
      oldDelegate.faceDown != faceDown ||
      oldDelegate.elevated != elevated ||
      oldDelegate.highlighted != highlighted;
}
