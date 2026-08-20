import 'dart:ui';

/// Векторные масти для мелких иконок (без unicode и ассетов).
Path heartSuitPath(Offset center, double size) {
  final s = size / 2;
  final path = Path()
    ..moveTo(center.dx, center.dy + s * 0.72)
    ..cubicTo(
      center.dx - s * 1.2,
      center.dy + s * 0.05,
      center.dx - s * 0.55,
      center.dy - s * 0.95,
      center.dx,
      center.dy - s * 0.22,
    )
    ..cubicTo(
      center.dx + s * 0.55,
      center.dy - s * 0.95,
      center.dx + s * 1.2,
      center.dy + s * 0.05,
      center.dx,
      center.dy + s * 0.72,
    )
    ..close();
  return path;
}

Path spadeSuitPath(Offset center, double size) {
  final s = size / 2;
  final path = Path()
    ..moveTo(center.dx, center.dy - s * 0.78)
    ..cubicTo(
      center.dx - s * 1.15,
      center.dy - s * 0.05,
      center.dx - s * 0.45,
      center.dy + s * 0.72,
      center.dx,
      center.dy + s * 0.12,
    )
    ..cubicTo(
      center.dx + s * 0.45,
      center.dy + s * 0.72,
      center.dx + s * 1.15,
      center.dy - s * 0.05,
      center.dx,
      center.dy - s * 0.78,
    )
    ..close();
  path.addRect(
    Rect.fromCenter(
      center: Offset(center.dx, center.dy + s * 0.52),
      width: s * 0.28,
      height: s * 0.55,
    ),
  );
  return path;
}

Path diamondSuitPath(Offset center, double size) {
  final s = size / 2;
  return Path()
    ..moveTo(center.dx, center.dy - s)
    ..lineTo(center.dx + s * 0.72, center.dy)
    ..lineTo(center.dx, center.dy + s)
    ..lineTo(center.dx - s * 0.72, center.dy)
    ..close();
}
