import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

/// Размер кости в цепи при масштабе 1.
const double kDominoLong = 54;
const double kDominoShort = 28;
const double kDominoGap = 3;

/// Отношение длинной стороны кости к короткой.
const double kDominoAspect = kDominoLong / kDominoShort;

const List<Offset> _pipGrid = [
  Offset(0.28, 0.28),
  Offset(0.72, 0.28),
  Offset(0.28, 0.50),
  Offset(0.72, 0.50),
  Offset(0.28, 0.72),
  Offset(0.72, 0.72),
  Offset(0.50, 0.50),
];

const List<List<int>> _pipIndex = [
  [],
  [6],
  [0, 5],
  [0, 6, 5],
  [0, 1, 4, 5],
  [0, 1, 6, 4, 5],
  [0, 2, 4, 1, 3, 5],
];

/// Лицо кости. [vertical] — половины сверху и снизу, иначе слева и справа;
/// [lo] рисуется первой (сверху или слева).
class DominoFacePainter extends CustomPainter {
  const DominoFacePainter({
    required this.lo,
    required this.hi,
    required this.vertical,
    this.shadow = true,
  });

  final int lo;
  final int hi;
  final bool vertical;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.2);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    if (shadow) {
      canvas.drawRRect(
        rrect.shift(Offset(0, size.shortestSide * 0.07)),
        Paint()..color = GamePalette.shadow,
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GamePalette.pieceFace, GamePalette.pieceFaceShade],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = GamePalette.pieceEdge,
    );
    final line = Paint()
      ..color = GamePalette.pieceEdge
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, size.shortestSide * 0.045);
    final inset = size.shortestSide * 0.18;
    if (vertical) {
      final mid = size.height / 2;
      canvas.drawLine(
        Offset(inset, mid),
        Offset(size.width - inset, mid),
        line,
      );
      _pips(canvas, Rect.fromLTWH(0, 0, size.width, mid), lo);
      _pips(canvas, Rect.fromLTWH(0, mid, size.width, mid), hi);
    } else {
      final mid = size.width / 2;
      canvas.drawLine(
        Offset(mid, inset),
        Offset(mid, size.height - inset),
        line,
      );
      _pips(canvas, Rect.fromLTWH(0, 0, mid, size.height), lo);
      _pips(canvas, Rect.fromLTWH(mid, 0, mid, size.height), hi);
    }
  }

  void _pips(Canvas canvas, Rect area, int count) {
    if (count <= 0 || count >= _pipIndex.length) return;
    final paint = Paint()..color = GamePalette.pieceInk;
    final radius = math.max(1.2, math.min(area.width, area.height) * 0.085);
    for (final index in _pipIndex[count]) {
      final spot = _pipGrid[index];
      canvas.drawCircle(
        Offset(
          area.left + area.width * spot.dx,
          area.top + area.height * spot.dy,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DominoFacePainter oldDelegate) =>
      oldDelegate.lo != lo ||
      oldDelegate.hi != hi ||
      oldDelegate.vertical != vertical ||
      oldDelegate.shadow != shadow;
}

/// Рубашка кости — акцент приложения, как у карт и фишек других игр.
class DominoBackPainter extends CustomPainter {
  const DominoBackPainter({this.shadow = true});

  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.2);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    if (shadow) {
      canvas.drawRRect(
        rrect.shift(Offset(0, size.shortestSide * 0.07)),
        Paint()..color = GamePalette.shadow,
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()..shader = GamePalette.pieceBackGradient.createShader(rect),
    );
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.shortestSide * 0.05)
      ..color = GamePalette.pieceBackInk.withValues(alpha: 0.75);
    canvas.drawRRect(rrect.deflate(size.shortestSide * 0.14), ink);
    canvas.drawCircle(
      rect.center,
      size.shortestSide * 0.12,
      Paint()..color = GamePalette.pieceBackInk.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant DominoBackPainter oldDelegate) =>
      oldDelegate.shadow != shadow;
}

/// Кость лицом вверх; занимает всё отведённое место.
class DominoTileFace extends StatelessWidget {
  const DominoTileFace({
    super.key,
    required this.tile,
    this.vertical = true,
  });

  /// Id кости, см. [dominoTileId].
  final int tile;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final pips = dominoPips(tile);
    return CustomPaint(
      painter: DominoFacePainter(
        lo: pips.$1,
        hi: pips.$2,
        vertical: vertical,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Кость рубашкой вверх.
class DominoTileBack extends StatelessWidget {
  const DominoTileBack({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: DominoBackPainter(),
      child: SizedBox.expand(),
    );
  }
}

/// Кость в полёте: первую половину пути рубашкой, вторую — лицом.
class DominoFlipTile extends StatelessWidget {
  const DominoFlipTile({super.key, required this.tile, required this.t});

  final int tile;

  /// Прогресс полёта 0..1.
  final double t;

  @override
  Widget build(BuildContext context) {
    final turn = math.cos(math.pi * t.clamp(0.0, 1.0)).abs();
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(math.max(turn, 0.04), 1, 1),
      child: t < 0.5 ? const DominoTileBack() : DominoTileFace(tile: tile),
    );
  }
}
