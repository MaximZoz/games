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

    test('6-max: upper seats put cards below the plate', () {
      final anchors = pokerOpponentSeatAnchors(5);
      expect(pokerOppHolePlacement(anchors[1]), PokerOppHolePlacement.below);
      expect(pokerOppHolePlacement(anchors[2]), PokerOppHolePlacement.below);
      expect(pokerOppHolePlacement(anchors[3]), PokerOppHolePlacement.below);
    });

    test('top-center mirrors the bottom: cards under the plate', () {
      expect(
        pokerOppHolePlacement(const Alignment(0, -1)),
        PokerOppHolePlacement.below,
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
        plateHeight: plate.height,
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

    test('top-center cards sit centered under the plate', () {
      const align = Alignment(0, -1);
      final off = pokerOppHoleOffset(
        align: align,
        plateWidth: plate.width,
        plateHeight: plate.height,
        cardsWidth: cardsWidth,
        cardsHeight: cardsHeight,
      );
      expect(off.dx, (plate.width - cardsWidth) / 2);
      expect(off.dy, plate.height + 4);
    });

    test('old outward placement would clip 6-max side seats', () {
      const left = Alignment(-0.88, -0.78);
      final plateLeft = (viewport.width - plate.width) * (1 + left.x) / 2;
      final oldLeft = plateLeft - cardsWidth - 4;
      expect(oldLeft, lessThan(0));
      expect(holeRect(left).left, greaterThanOrEqualTo(0));
    });
  });

  group('альбом на телефоне: соперники на боковых кромках', () {
    test('ни одно место не встаёт в центр по горизонтали', () {
      for (var n = 1; n <= 5; n++) {
        for (final align in pokerOpponentSeatAnchors(n, landscape: true)) {
          expect(
            align.x.abs(),
            greaterThanOrEqualTo(1.0),
            reason: 'n=$n $align занимает центр, где стоят борд и свои карты',
          );
        }
      }
    });

    test('портретные якоря не изменились', () {
      for (var n = 0; n <= 5; n++) {
        expect(
          pokerOpponentSeatAnchors(n, landscape: false),
          pokerOpponentSeatAnchors(n),
        );
      }
    });

    test('карты боковых мест уходят внутрь стола, а не вверх/вниз', () {
      for (var n = 1; n <= 5; n++) {
        final anchors = pokerOpponentSeatAnchors(n, landscape: true);
        for (final align in anchors) {
          final placement = pokerOppHolePlacement(align, sideways: true);
          expect(
            placement,
            align.x < 0
                ? PokerOppHolePlacement.inwardRight
                : PokerOppHolePlacement.inwardLeft,
            reason: 'n=$n $align',
          );
        }
      }
    });

    test('колонка профиля с картами вбок не выше самой колонки', () {
      const plateH = 74.0;
      const cardsHeight = 50.0;
      final off = pokerOppHoleOffset(
        align: const Alignment(-1, 0.7),
        plateWidth: 72,
        plateHeight: plateH,
        cardsWidth: 56,
        cardsHeight: cardsHeight,
        sideways: true,
      );
      expect(off.dy, 0);
      expect(off.dy + cardsHeight, lessThanOrEqualTo(plateH));
    });

    // Фетр телефона в альбоме: ~341 px по высоте, колонка профиля 74 px.
    const feltH = 341.0;
    const seatH = 74.0;
    // Полоса под соперниками отдана ряду кнопок: комбинация 30 + зазор 6 +
    // кнопки 42 + отступ от бортика 10.
    const actionBand = 88.0;

    List<double> topsOnSide(int n, double side, double bandH) =>
        pokerOpponentSeatAnchors(n, landscape: true)
            .where((a) => a.x == side)
            .map((a) => (bandH - seatH) * (1 + a.y) / 2)
            .toList()
          ..sort();

    test('места на одной кромке не наезжают друг на друга', () {
      for (var n = 1; n <= 5; n++) {
        for (final side in [-1.0, 1.0]) {
          final tops = topsOnSide(n, side, feltH);
          for (var i = 1; i < tops.length; i++) {
            expect(
              tops[i] - tops[i - 1],
              greaterThanOrEqualTo(seatH),
              reason: 'n=$n сторона $side: места $i-1 и $i перекрываются',
            );
          }
        }
      }
    });

    test('в полосе над кнопками места тоже не наезжают и не лезут под них',
        () {
      const bandH = feltH - actionBand;
      for (var n = 1; n <= 5; n++) {
        for (final side in [-1.0, 1.0]) {
          final tops = topsOnSide(n, side, bandH);
          for (var i = 0; i < tops.length; i++) {
            expect(
              tops[i] + seatH,
              lessThanOrEqualTo(bandH + 0.5),
              reason: 'n=$n сторона $side: место $i заходит под кнопки',
            );
            if (i > 0) {
              expect(
                tops[i] - tops[i - 1],
                greaterThanOrEqualTo(seatH),
                reason: 'n=$n сторона $side: места $i-1 и $i перекрываются',
              );
            }
          }
        }
      }
    });
  });
}
