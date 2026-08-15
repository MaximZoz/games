import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/poker/poker_seat_layout.dart';

void main() {
  group('pokerOppHolePlacement', () {
    test('6-max: bottom sides put cards above the seat', () {
      final anchors = pokerOpponentSeatAnchors(5);
      expect(pokerOppHolePlacement(anchors[0]), PokerOppHolePlacement.above);
      expect(pokerOppHolePlacement(anchors[4]), PokerOppHolePlacement.above);
    });

    test('6-max: upper sides put cards toward the table', () {
      final anchors = pokerOpponentSeatAnchors(5);
      expect(
        pokerOppHolePlacement(anchors[1]),
        PokerOppHolePlacement.inwardRight,
      );
      expect(
        pokerOppHolePlacement(anchors[3]),
        PokerOppHolePlacement.inwardLeft,
      );
    });

    test('top-center keeps cards on the inward/right side of the plate', () {
      expect(
        pokerOppHolePlacement(const Alignment(0, -1)),
        PokerOppHolePlacement.inwardRight,
      );
    });
  });

  group('showdown hole cards stay on a phone screen', () {
    const viewport = Size(360, 640);
    const plate = Size(78, 100);
    const cardsWidth = 44.0 * 1.55;
    const cardsHeight = 62.0;

    Rect holeRect(Alignment align) {
      final plateLeft = (viewport.width - plate.width) * (1 + align.x) / 2;
      final plateTop = (viewport.height - plate.height) * (1 + align.y) / 2;
      final off = pokerOppHoleOffset(
        align: align,
        plateWidth: plate.width,
        cardsWidth: cardsWidth,
        cardsHeight: cardsHeight,
      );
      return Rect.fromLTWH(
        plateLeft + off.dx,
        plateTop + off.dy,
        cardsWidth,
        cardsHeight,
      );
    }

    test('every 2–6-max opponent seat keeps both hole cards on screen', () {
      for (var n = 1; n <= 5; n++) {
        for (final align in pokerOpponentSeatAnchors(n)) {
          final rect = holeRect(align);
          expect(
            rect.left,
            greaterThanOrEqualTo(-0.5),
            reason: 'n=$n $align left ${rect.left}',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(viewport.width + 0.5),
            reason: 'n=$n $align right ${rect.right}',
          );
          expect(
            rect.top,
            greaterThanOrEqualTo(-0.5),
            reason: 'n=$n $align top ${rect.top}',
          );
          expect(
            rect.bottom,
            lessThanOrEqualTo(viewport.height + 0.5),
            reason: 'n=$n $align bottom ${rect.bottom}',
          );
        }
      }
    });

    test('old outward placement would clip 6-max side seats', () {
      const left = Alignment(-0.88, -0.78);
      final plateLeft = (viewport.width - plate.width) * (1 + left.x) / 2;
      final oldLeft = plateLeft - cardsWidth - 4;
      expect(oldLeft, lessThan(0));
      expect(holeRect(left).left, greaterThanOrEqualTo(0));
    });
  });
}
