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

/// Логотип Zozu Games: яркая индиго-фиолетовая плитка, золотая игровая карта
/// с короной и наклонённый белый игральный кубик — чистый символ настольных,
/// карточных и костяных мини-игр без букв.
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
            Color(0xFF2E1065),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
            Color(0xFFA855F7),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
        ).createShader(rect),
    );

    // Мягкое бирюзово-лавандовое свечение сверху и тёплый отсвет снизу.
    canvas.drawCircle(
      Offset(s * 0.24, s * 0.20),
      s * 0.56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF818CF8).withValues(alpha: 0.44),
            const Color(0xFF818CF8).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(s * 0.24, s * 0.20), radius: s * 0.56),
        ),
    );
    canvas.drawCircle(
      Offset(s * 0.80, s * 0.84),
      s * 0.50,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF472B6).withValues(alpha: 0.30),
            const Color(0xFFF472B6).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(s * 0.80, s * 0.84), radius: s * 0.50),
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
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0.08),
              const Color(0xFFC4B5FD).withValues(alpha: 0.24),
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

    _paintGamesEmblem(canvas, s);
    canvas.restore();
  }

  void _paintGamesEmblem(Canvas canvas, double s) {
    // 1) Задняя золотая игровая карта с короной (наклонена влево).
    _paintGoldCard(canvas, s);

    // 2) Передний белый игральный кубик с 5 точками (наклонён вправо).
    _paintWhiteDie(canvas, s);

    // 3) Яркая четырёхлучевая звезда-искра сверху справа.
    if (s >= 24) {
      final sparkCenter = Offset(s * 0.78, s * 0.23);
      final spark = _fourPointStar(sparkCenter, s * 0.064, s * 0.020);
      canvas.drawPath(
        spark,
        Paint()
          ..shader = RadialGradient(
            colors: const [Color(0xFFFFFFFF), Color(0xFFFDE68A)],
          ).createShader(
            Rect.fromCircle(center: sparkCenter, radius: s * 0.068),
          ),
      );
    }
  }

  void _paintGoldCard(Canvas canvas, double s) {
    final center = Offset(s * 0.39, s * 0.45);
    final cardW = s * 0.42;
    final cardH = s * 0.50;
    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: cardW,
      height: cardH,
    );
    final cardRRect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(s * 0.095),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.24);

    if (s >= 28) {
      canvas.drawRRect(
        cardRRect.shift(Offset(0, s * 0.024)),
        Paint()
          ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.42)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.026),
      );
    }

    canvas.drawRRect(
      cardRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7C2),
            Color(0xFFFFD447),
            Color(0xFFF59E0B),
            Color(0xFFEA580C),
          ],
          stops: [0.0, 0.34, 0.74, 1.0],
        ).createShader(cardRect),
    );

    if (s >= 32) {
      canvas.drawRRect(
        cardRRect.deflate(s * 0.006),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, s * 0.012)
          ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.72),
      );
    }

    // Небольшая корона/ромб в верхнем левом углу карты.
    final diamond = _diamondPath(
      Offset(-cardW * 0.23, -cardH * 0.20),
      s * 0.068,
      s * 0.084,
    );
    canvas.drawPath(diamond, Paint()..color = const Color(0xFF7C2D12));
    canvas.drawPath(
      _diamondPath(
        Offset(-cardW * 0.23, -cardH * 0.20),
        s * 0.056,
        s * 0.070,
      ),
      Paint()..color = const Color(0xFFFFFBEB),
    );

    canvas.restore();
  }

  void _paintWhiteDie(Canvas canvas, double s) {
    final center = Offset(s * 0.58, s * 0.56);
    final dieSize = s * 0.46;
    final dieRect = Rect.fromCenter(
      center: Offset.zero,
      width: dieSize,
      height: dieSize,
    );
    final dieRRect = RRect.fromRectAndRadius(
      dieRect,
      Radius.circular(s * 0.115),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.19);

    // Глубокая тень кубика поверх золотой карты.
    if (s >= 24) {
      canvas.drawRRect(
        dieRRect.shift(Offset(-s * 0.012, s * 0.026)),
        Paint()
          ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.46)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.028),
      );
    }

    canvas.drawRRect(
      dieRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F7FF),
            Color(0xFFE0E7FF),
          ],
          stops: [0.0, 0.62, 1.0],
        ).createShader(dieRect),
    );

    if (s >= 32) {
      canvas.drawRRect(
        dieRRect.deflate(s * 0.006),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, s * 0.012)
          ..color = Colors.white,
      );
    }

    // Пять точек на грани кубика: 4 индиго по углам и золотая/коралловая в центре.
    final off = dieSize * 0.255;
    final pipR = s * 0.038;
    final cornerPipPaint = Paint()..color = const Color(0xFF4338CA);
    for (final pt in [
      Offset(-off, -off),
      Offset(off, -off),
      Offset(-off, off),
      Offset(off, off),
    ]) {
      canvas.drawCircle(pt, pipR, cornerPipPaint);
    }

    final centerPipR = s * 0.046;
    canvas.drawCircle(
      Offset.zero,
      centerPipR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFB7185),
            Color(0xFFE11D48),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: centerPipR)),
    );

    canvas.restore();
  }

  static Path _diamondPath(Offset c, double rx, double ry) {
    return Path()
      ..moveTo(c.dx, c.dy - ry)
      ..lineTo(c.dx + rx, c.dy)
      ..lineTo(c.dx, c.dy + ry)
      ..lineTo(c.dx - rx, c.dy)
      ..close();
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
