import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ZozuLogoStyle {
  /// Скруглённая плитка на прозрачном фоне (Android, macOS, favicon, UI).
  rounded,

  /// Плитка во весь квадрат без прозрачных углов (iOS AppIcon, PWA Icon).
  fullBleed,

  /// Maskable PWA: знак чуть компактнее внутри safe-zone 80%.
  maskable,
}

/// Логотип Zozu Games: яркая индиго-фиолетовая плитка и два скошенных
/// крыла игровой кости, сложенных в букву «Z» с золотой фишкой в центре.
class ZozuAppLogo extends StatelessWidget {
  const ZozuAppLogo({
    super.key,
    this.size = 64,
    this.style = ZozuLogoStyle.rounded,
  });

  final double size;
  final ZozuLogoStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: ZozuAppLogoPainter(style: style),
    );
  }
}

class ZozuAppLogoPainter extends CustomPainter {
  const ZozuAppLogoPainter({this.style = ZozuLogoStyle.rounded});

  final ZozuLogoStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);

    final RRect tile;
    if (style == ZozuLogoStyle.rounded) {
      final inset = s * 0.04;
      tile = RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(s * 0.24),
      );
      if (s >= 48) {
        canvas.drawRRect(
          tile.shift(Offset(0, s * 0.022)),
          Paint()
            ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.28)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.028),
        );
      }
    } else {
      tile = RRect.fromRectAndRadius(rect, Radius.zero);
    }

    canvas.save();
    if (style == ZozuLogoStyle.rounded) {
      canvas.clipRRect(tile);
    } else {
      canvas.clipRect(rect);
    }

    // Насыщенный диагональный градиент плитки в палитре Zozu Games.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.9, -0.95),
          end: Alignment(0.95, 0.95),
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF6D28D9),
            Color(0xFF9333EA),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
        ).createShader(rect),
    );

    // Мягкое верхнее свечение и тёплый отсвет снизу.
    canvas.drawCircle(
      Offset(s * 0.24, s * 0.18),
      s * 0.56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFA5B4FC).withValues(alpha: 0.42),
            const Color(0xFFA5B4FC).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(s * 0.24, s * 0.18), radius: s * 0.56),
        ),
    );
    canvas.drawCircle(
      Offset(s * 0.82, s * 0.86),
      s * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF472B6).withValues(alpha: 0.26),
            const Color(0xFFF472B6).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(s * 0.82, s * 0.86), radius: s * 0.48),
        ),
    );

    // Тонкий внутренний кант для иконок со скруглением.
    if (style == ZozuLogoStyle.rounded && s >= 32) {
      final stroke = math.max(1.0, s * 0.014);
      canvas.drawRRect(
        tile.deflate(stroke * 0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.36),
              Colors.white.withValues(alpha: 0.06),
              const Color(0xFFC4B5FD).withValues(alpha: 0.22),
            ],
          ).createShader(rect),
      );
    }

    // Масштаб знака: для maskable держим внутри безопасного круга.
    final markScale = switch (style) {
      ZozuLogoStyle.maskable => 0.78,
      ZozuLogoStyle.fullBleed => 0.92,
      ZozuLogoStyle.rounded => 0.94,
    };
    canvas.translate(s * 0.5, s * 0.5);
    canvas.scale(markScale);
    canvas.translate(-s * 0.5, -s * 0.5);

    _paintZMark(canvas, s);
    canvas.restore();
  }

  void _paintZMark(Canvas canvas, double s) {
    // Буква Z из двух игровых плиток и яркой золотой перекладины:
    // верхняя и нижняя плашки со скошенным краем + диагональный золотой луч,
    // плюс круглые точки кости/домино.
    final topBar = _roundedPolygon([
      Offset(s * 0.21, s * 0.21),
      Offset(s * 0.79, s * 0.21),
      Offset(s * 0.69, s * 0.37),
      Offset(s * 0.21, s * 0.37),
    ], s * 0.055);

    final bottomBar = _roundedPolygon([
      Offset(s * 0.31, s * 0.63),
      Offset(s * 0.79, s * 0.63),
      Offset(s * 0.79, s * 0.79),
      Offset(s * 0.21, s * 0.79),
    ], s * 0.055);

    final diagBar = _roundedPolygon([
      Offset(s * 0.60, s * 0.21),
      Offset(s * 0.79, s * 0.21),
      Offset(s * 0.40, s * 0.79),
      Offset(s * 0.21, s * 0.79),
    ], s * 0.052);

    // Мягкая тень под знаком.
    if (s >= 28) {
      final shadowPaint = Paint()
        ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.026);
      canvas.save();
      canvas.translate(0, s * 0.024);
      canvas.drawPath(topBar, shadowPaint);
      canvas.drawPath(bottomBar, shadowPaint);
      canvas.drawPath(diagBar, shadowPaint);
      canvas.restore();
    }

    // Белые игровые плашки сверху и снизу (как кости домино / карты).
    final barBounds = Rect.fromLTWH(s * 0.2, s * 0.2, s * 0.6, s * 0.6);
    final whitePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFEEF2FF),
          Color(0xFFE0E7FF),
        ],
      ).createShader(barBounds);

    canvas.drawPath(topBar, whitePaint);
    canvas.drawPath(bottomBar, whitePaint);

    // Небольшая тень от диагонали на белые плашки для объёма.
    if (s >= 28) {
      final overlapShadow = Paint()
        ..color = const Color(0xFF312E81).withValues(alpha: 0.24)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.018);
      canvas.drawPath(diagBar.shift(Offset(0, s * 0.01)), overlapShadow);
    }

    // Золотая диагональ — как победный ход и золотая монета Zozu Games.
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFFF3B0),
          Color(0xFFFFD147),
          Color(0xFFF59E0B),
          Color(0xFFEA580C),
        ],
        stops: [0.0, 0.34, 0.76, 1.0],
      ).createShader(barBounds);
    canvas.drawPath(diagBar, goldPaint);

    // Тонкий светлый блик по золотой диагонали.
    if (s >= 32) {
      canvas.drawPath(
        diagBar,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, s * 0.011)
          ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.62),
      );
    }

    // Точки игровой кости на верхней и нижней плашках + центральная искра.
    final pipPaint = Paint()..color = const Color(0xFF4338CA);
    final pipR = s * 0.032;
    canvas.drawCircle(Offset(s * 0.31, s * 0.29), pipR, pipPaint);
    canvas.drawCircle(Offset(s * 0.42, s * 0.29), pipR, pipPaint);
    canvas.drawCircle(Offset(s * 0.58, s * 0.71), pipR, pipPaint);
    canvas.drawCircle(Offset(s * 0.69, s * 0.71), pipR, pipPaint);

    // Белая четырёхлучевая звезда-блик в центре золотой грани.
    final star =
        _fourPointStar(Offset(s * 0.50, s * 0.50), s * 0.068, s * 0.022);
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFFFFF));
  }

  static Path _roundedPolygon(List<Offset> pts, double radius) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final curr = pts[i];
      final next = pts[(i + 1) % n];

      final v1 = prev - curr;
      final v2 = next - curr;
      final l1 = v1.distance;
      final l2 = v2.distance;
      final r = math.min(radius, math.min(l1, l2) * 0.45);

      final p1 = curr + v1 * (r / l1);
      final p2 = curr + v2 * (r / l2);

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  static Path _fourPointStar(Offset c, double outerR, double innerR) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? outerR : innerR;
      final p = Offset(c.dx + math.cos(angle) * r, c.dy + math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ZozuAppLogoPainter oldDelegate) =>
      oldDelegate.style != style;
}
