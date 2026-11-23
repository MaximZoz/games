import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_tile.dart';

class DominoLayoutSlot {
  const DominoLayoutSlot({
    required this.id,
    required this.rect,
    required this.leadingOnRight,
  });

  final int id;
  final Rect rect;

  /// true, пока ряд идёт вправо: открытый конец кости — справа.
  /// На обратном ряду открытый конец слева, и половины надо поменять местами.
  final bool leadingOnRight;
}

/// Какую половину рисовать слева и справа.
/// [leadingOnRight] — открытый конец (к следующей кости цепи) справа.
({int left, int right}) dominoHalfPips(
  DominoPlaced tile, {
  required bool leadingOnRight,
}) {
  if (tile.isDouble) return (left: tile.lo, right: tile.hi);
  final towardLower = tile.end == 'left' ? tile.outward : tile.inward;
  final towardHigher = tile.end == 'left' ? tile.inward : tile.outward;
  if (leadingOnRight) return (left: towardLower, right: towardHigher);
  return (left: towardHigher, right: towardLower);
}

/// Раскладка цепи: слева направо, с переносом, когда ряд не влезает.
/// Координаты относительно левого верхнего угла цепи, не холста.
List<DominoLayoutSlot> layoutDominoChain(
  List<DominoPlaced> chain,
  double maxWidth,
) {
  if (chain.isEmpty) return const [];
  final width = math.max(maxWidth, kDominoLong + 8);
  final slots = <DominoLayoutSlot>[];
  // Край, от которого ставится следующая кость: левый, пока ряд идёт вправо,
  // и правый на обратном ряду — кости бывают разной ширины (дубль уже).
  var cursor = 0.0;
  var y = 0.0;
  var dir = 1;
  for (final tile in chain) {
    final tileWidth = tile.isDouble ? kDominoShort : kDominoLong;
    final tileHeight = tile.isDouble ? kDominoLong : kDominoShort;
    if (slots.isNotEmpty && dir == 1 && cursor + tileWidth > width) {
      dir = -1;
      y += kDominoLong + 10;
      cursor = slots.last.rect.right;
    } else if (slots.isNotEmpty && dir == -1 && cursor - tileWidth < 0) {
      dir = 1;
      y += kDominoLong + 10;
      cursor = slots.last.rect.left;
    }
    final left = dir == 1 ? cursor : math.max(0.0, cursor - tileWidth);
    slots.add(DominoLayoutSlot(
      id: tile.id,
      rect: Rect.fromLTWH(
        left,
        y + (kDominoLong - tileHeight) / 2,
        tileWidth,
        tileHeight,
      ),
      leadingOnRight: dir == 1,
    ));
    cursor = dir == 1 ? left + tileWidth + kDominoGap : left - kDominoGap;
  }
  return slots;
}


/// Цепь, вписанная в область стола.
class DominoChainFit {
  const DominoChainFit({
    required this.slots,
    required this.scale,
    required this.size,
  });

  /// Слоты в пикселях стола, от левого верхнего угла цепи.
  final List<DominoLayoutSlot> slots;

  /// Во сколько раз кости крупнее [kDominoLong] × [kDominoShort].
  final double scale;
  final Size size;
}

/// Подбирает масштаб цепи: от [maxScale] вниз, пока змейка не влезет
/// в [area] по высоте. Меньше [minScale] кости не делаем — их не разглядеть.
DominoChainFit fitDominoChain(
  List<DominoPlaced> chain,
  Size area, {
  double maxScale = 1,
  double minScale = 0.5,
}) {
  if (chain.isEmpty || area.isEmpty) {
    return DominoChainFit(slots: const [], scale: maxScale, size: Size.zero);
  }
  var scale = maxScale;
  while (true) {
    final slots = layoutDominoChain(chain, area.width / scale);
    var bounds = slots.first.rect;
    for (final slot in slots.skip(1)) {
      bounds = bounds.expandToInclude(slot.rect);
    }
    if (bounds.height * scale <= area.height || scale <= minScale + 0.001) {
      return DominoChainFit(
        scale: scale,
        size: bounds.size * scale,
        slots: [
          for (final slot in slots)
            DominoLayoutSlot(
              id: slot.id,
              rect: Rect.fromLTWH(
                (slot.rect.left - bounds.left) * scale,
                (slot.rect.top - bounds.top) * scale,
                slot.rect.width * scale,
                slot.rect.height * scale,
              ),
              leadingOnRight: slot.leadingOnRight,
            ),
        ],
      );
    }
    scale = math.max(minScale, scale - 0.05);
  }
}
