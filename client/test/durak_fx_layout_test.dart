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

  group('durak landscape piles and action', () {
    test('кнопка в альбоме выше веера', () {
      final compact = durakActionButtonBottom(
        compact: true,
        seatLift: 16,
        fanCardH: 70,
      );
      final portrait = durakActionButtonBottom(
        compact: false,
        seatLift: -20,
        fanCardH: 90,
      );
      expect(compact, 16 + 70 + 16);
      expect(portrait, 20 + 90 + 10);
      expect(compact, greaterThan(70));
    });

    test('колода в альбоме не выглядывает за край', () {
      expect(durakPilesPeekOffEdge(compact: true), isFalse);
      expect(durakPilesPeekOffEdge(compact: false), isTrue);
      expect(durakPileEdgeInset(compact: true), 10);
      expect(durakPileEdgeInset(compact: false), 2);
    });

    test('запас стола под кнопку в альбоме', () {
      expect(
        durakBoardBottomReserve(
          compact: true,
          actionBtnBottom: 100,
          actionSlotH: 52,
          fanZoneH: 80,
        ),
        82,
      );
      expect(
        durakBoardBottomReserve(
          compact: false,
          actionBtnBottom: 100,
          actionSlotH: 52,
          fanZoneH: 80,
        ),
        0,
      );
    });
  });

  group('shouldSnapDurakVisualOnResume', () {
    test('с профиля на стол — сбрасываем FX', () {
      expect(
        shouldSnapDurakVisualOnResume(
          previousPath: '/profile',
          nextPath: '/games/durak/offline',
        ),
        isTrue,
      );
      expect(
        shouldSnapDurakVisualOnResume(
          previousPath: '/chats',
          nextPath: '/games/durak/game/g1',
        ),
        isTrue,
      );
    });

    test('первый заход и переход стол→стол — не трогаем', () {
      expect(
        shouldSnapDurakVisualOnResume(
          previousPath: '',
          nextPath: '/games/durak/offline',
        ),
        isFalse,
      );
      expect(
        shouldSnapDurakVisualOnResume(
          previousPath: '/games/durak/offline',
          nextPath: '/games/durak/offline',
        ),
        isFalse,
      );
    });
  });
}
