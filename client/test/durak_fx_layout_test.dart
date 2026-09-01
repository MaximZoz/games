import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_fx_layout.dart';
import 'package:multigames_client/ui/durak/overlay_space.dart';

void main() {
  group('overlaySpaceChangedEnough', () {
    test('первый кадр — не сбрасываем', () {
      expect(
        overlaySpaceChangedEnough(previous: null, next: const Size(800, 360)),
        isFalse,
      );
    });

    test('поворот телефона — сбрасываем полёты', () {
      expect(
        overlaySpaceChangedEnough(
          previous: const Size(390, 844),
          next: const Size(844, 390),
        ),
        isTrue,
      );
    });

    test('мелкий джиттер — не трогаем', () {
      expect(
        overlaySpaceChangedEnough(
          previous: const Size(800, 360),
          next: const Size(802, 358),
        ),
        isFalse,
      );
    });

    test('сильное изменение высоты — сбрасываем', () {
      expect(
        overlaySpaceChangedEnough(
          previous: const Size(800, 360),
          next: const Size(800, 240),
        ),
        isTrue,
      );
    });
  });

  group('durakFinishedChrome', () {
    test('партия — обычный стол', () {
      expect(
        durakFinishedChrome(isOver: false, phoneLandscape: true),
        DurakFinishedChrome.playing,
      );
    });

    test('итог в альбоме — ряд, без веера', () {
      expect(
        durakFinishedChrome(isOver: true, phoneLandscape: true),
        DurakFinishedChrome.landscapeRow,
      );
    });

    test('итог в портрете — колонка', () {
      expect(
        durakFinishedChrome(isOver: true, phoneLandscape: false),
        DurakFinishedChrome.stacked,
      );
    });
  });

  group('durakLayoutTweenDuration', () {
    test('в альбоме твины мгновенные', () {
      expect(durakLayoutTweenDuration(compact: true), Duration.zero);
      expect(
        durakLayoutTweenDuration(compact: false),
        const Duration(milliseconds: 380),
      );
    });
  });
}
