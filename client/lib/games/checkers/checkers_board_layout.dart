import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';

/// Клетка доски в координатах виджета: без зазоров, без накопления округления.
Rect checkersCellRect(double side, int row, int col) {
  return Rect.fromLTRB(
    side * col / CheckersEngine.size,
    side * row / CheckersEngine.size,
    side * (col + 1) / CheckersEngine.size,
    side * (row + 1) / CheckersEngine.size,
  );
}

/// Заливка клетки чуть перекрывает соседа, чтобы растр не оставлял белых щелей.
Rect checkersCellPaintRect(double side, int row, int col) {
  final cell = checkersCellRect(side, row, col);
  return Rect.fromLTRB(
    cell.left,
    cell.top,
    cell.right + 0.5,
    cell.bottom + 0.5,
  );
}

/// Экранная клетка → логическая, если доска повёрнута за чёрных.
CheckersSquare checkersBoardSquare({
  required int visR,
  required int visC,
  required bool flip,
}) {
  if (flip) {
    return CheckersSquare(
      CheckersEngine.size - 1 - visR,
      CheckersEngine.size - 1 - visC,
    );
  }
  return CheckersSquare(visR, visC);
}

/// Точка внутри доски → логическая клетка.
CheckersSquare? checkersSquareAtLocal({
  required double side,
  required double dx,
  required double dy,
  required bool flip,
}) {
  if (side <= 0) return null;
  final visC = (dx * CheckersEngine.size / side)
      .floor()
      .clamp(0, CheckersEngine.size - 1);
  final visR = (dy * CheckersEngine.size / side)
      .floor()
      .clamp(0, CheckersEngine.size - 1);
  return checkersBoardSquare(visR: visR, visC: visC, flip: flip);
}

/// Диаметр точки хода — внутри клетки, не ломает границы.
double checkersTargetDotSize(double cellSide) => cellSide * 0.28;

/// Длительность переезда: короткая для шага, длиннее для полёта дамки.
Duration checkersMoveDuration({
  required int fromR,
  required int fromC,
  required int toR,
  required int toC,
}) {
  if (fromR < 0 || toR < 0) {
    return const Duration(milliseconds: 420);
  }
  final dist = math.max((toR - fromR).abs(), (toC - fromC).abs());
  return Duration(milliseconds: (280 + 80 * dist).clamp(360, 640));
}

/// Соседние клетки стыкуются без щели и не наезжают друг на друга.
bool checkersCellsTileWithoutGaps(double side) {
  const n = CheckersEngine.size;
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      final cell = checkersCellRect(side, r, c);
      if (c + 1 < n) {
        final right = checkersCellRect(side, r, c + 1);
        if (cell.right != right.left) return false;
      }
      if (r + 1 < n) {
        final below = checkersCellRect(side, r + 1, c);
        if (cell.bottom != below.top) return false;
      }
    }
  }
  final last = checkersCellRect(side, n - 1, n - 1);
  return checkersCellRect(side, 0, 0).left == 0 &&
      checkersCellRect(side, 0, 0).top == 0 &&
      last.right == side &&
      last.bottom == side;
}

@visibleForTesting
bool checkersHighlightFitsCell(Rect cell, double highlightSize) {
  return highlightSize > 0 &&
      highlightSize <= cell.shortestSide &&
      highlightSize <= cell.width &&
      highlightSize <= cell.height;
}
