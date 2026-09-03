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

    test('поворот — ширина и высота поменялись местами', () {
      expect(
        overlaySpaceLooksRotated(const Size(390, 844), const Size(844, 390)),
        isTrue,
      );
      expect(
        overlaySpaceLooksRotated(const Size(800, 360), const Size(800, 240)),
        isFalse,
      );
    });

    test('во время хода джиттер рейла не snap, поворот — snap', () {
      expect(
        durakShouldSnapOverlaySpace(
          previous: const Size(800, 360),
          next: const Size(800, 240),
          playInFlight: true,
        ),
        isFalse,
      );
      expect(
        durakShouldSnapOverlaySpace(
          previous: const Size(390, 844),
          next: const Size(844, 390),
          playInFlight: true,
        ),
        isTrue,
      );
      expect(
        durakShouldSnapOverlaySpace(
          previous: const Size(800, 360),
          next: const Size(800, 240),
          playInFlight: false,
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
      expect(compact, 16 + 70 + 36);
      expect(portrait, 20 + 90 + 10);
      expect(compact, greaterThan(70 + 16));
    });

    test('в альбоме кнопка правее центра, не на картах стола', () {
      expect(durakActionButtonAlignX(compact: true), greaterThan(0.4));
      expect(durakActionButtonAlignX(compact: true), lessThan(0.9));
      expect(durakActionButtonAlignX(compact: false), 0);
    });

    test('колода в альбоме не выглядывает за край', () {
      expect(durakPilesPeekOffEdge(compact: true), isFalse);
      expect(durakPilesPeekOffEdge(compact: false), isTrue);
      expect(durakPileEdgeInset(compact: true), 10);
      expect(durakPileEdgeInset(compact: false), 2);
    });

    test('справа в альбоме хватает места на карту биты', () {
      const card = Size(43, 61);
      final right = durakBoardRightReserve(compact: true, cardSize: card);
      expect(right, greaterThan(card.width * 1.35 + 10));
      expect(
        durakBoardLeftReserve(compact: true, cardSize: card),
        closeTo(
          durakDeckPileWidth(cardSize: card, peekOffEdge: false) + 18,
          0.01,
        ),
      );
      expect(
        durakBoardRightReserve(compact: true, cardSize: card, bitoCount: 0),
        lessThan(24),
      );
      expect(
        durakBoardRightReserve(compact: false, cardSize: card, bitoCount: 0),
        lessThan(16),
      );
    });

    test('в альбоме козырь торчит из колоды, как в портрете', () {
      const card = Size(43, 61);
      final visibleIn = durakDeckTrumpVisibleWidth(
        cardSize: card,
        peekOffEdge: false,
      );
      final visiblePeek = durakDeckTrumpVisibleWidth(
        cardSize: card,
        peekOffEdge: true,
      );
      expect(visibleIn, greaterThan(card.height * 0.45));
      expect(visiblePeek, greaterThan(card.height * 0.45));
      expect(
        durakDeckTrumpLeft(cardSize: card, peekOffEdge: false),
        greaterThan(durakDeckTrumpLeft(cardSize: card, peekOffEdge: true)),
      );
    });

    test('веер соперника в альбоме читаемый, не 24 px', () {
      expect(durakOpponentFanTileMinH(compact: true), greaterThanOrEqualTo(48));
      expect(durakOpponentFanTileMinW(compact: true), greaterThanOrEqualTo(34));
      const card = Size(43, 61);
      final geo = durakOpponentFanGeometry(
        cardSize: card,
        shown: 6,
        maxWidth: 360,
        compact: true,
      );
      expect(geo.tile.height, greaterThanOrEqualTo(48));
      expect(geo.tile.width, greaterThanOrEqualTo(34));
      expect(geo.totalW, greaterThan(geo.tile.width));
      expect(geo.reserveH, greaterThan(geo.tile.height));
    });

    test('раздача не прячет весь веер — иначе FX зависает на пустом слоте', () {
      expect(
        durakOpponentFanShownCount(serverCount: 6, hidden: 6),
        6,
      );
      expect(
        durakOpponentFanShownCount(serverCount: 6, hidden: 1),
        5,
      );
      expect(
        durakOpponentFanShownCount(serverCount: 0, hidden: 0),
        0,
      );
      final pending = {1: 6};
      durakSnapRevealHiddenFx(pending);
      expect(pending, isEmpty);
    });

    test('полёт на веер в альбоме не мельче 36×50', () {
      final fly = durakOpponentFanFlightSize(
        const Size(43, 61),
        compact: true,
      );
      expect(fly.width, greaterThanOrEqualTo(36));
      expect(fly.height, greaterThanOrEqualTo(50));
      expect(durakDealFlyDuration(compact: true).inMilliseconds, 220);
      expect(durakDealFlyDuration(compact: false).inMilliseconds, 160);
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

  group('durakGameUiActive', () {
    test('чужая вкладка — не запускаем FX', () {
      expect(
        durakGameUiActive(
          tickerEnabled: true,
          visiblePath: '/profile',
          herePath: '/games/durak/offline',
        ),
        isFalse,
      );
      expect(
        durakGameUiActive(
          tickerEnabled: true,
          visiblePath: '/games/durak/offline',
          herePath: '/games/durak/offline',
        ),
        isTrue,
      );
      expect(
        durakGameUiActive(
          tickerEnabled: false,
          visiblePath: '/games/durak/offline',
          herePath: '/games/durak/offline',
        ),
        isFalse,
      );
    });
  });

  group('durak stuck snap', () {
    test('полёт без busy тоже застрявший кадр', () {
      expect(
        durakVisualLooksStuck(
          busy: false,
          fxScheduled: false,
          flightActive: true,
          hidingTable: false,
        ),
        isTrue,
      );
      expect(
        durakVisualLooksStuck(
          busy: false,
          fxScheduled: false,
          flightActive: false,
          hidingTable: false,
        ),
        isFalse,
      );
      expect(
        durakVisualLooksStuck(
          busy: false,
          fxScheduled: false,
          flightActive: false,
          hidingTable: false,
          remoteFlightActive: true,
        ),
        isTrue,
      );
      expect(durakStuckSnapTicks(compact: true), 1);
      expect(durakStuckSnapTicks(compact: false), 3);
    });

    test('добор не в веере, пока карта pending — даже во время полёта', () {
      expect(durakDealCardInFanLayout(pendingDeal: true), isFalse);
      expect(durakDealCardInFanLayout(pendingDeal: false), isTrue);
    });

    test('в биту — только после посадки отбоя', () {
      expect(kDurakBitoAfterDefensePause.inMilliseconds, greaterThanOrEqualTo(800));
      expect(
        durakTableReadyForBitoFlight(
          remoteFlying: true,
          localFlyingToTable: false,
          defendLock: false,
          flyingFromHand: false,
        ),
        isFalse,
      );
      expect(
        durakTableReadyForBitoFlight(
          remoteFlying: false,
          localFlyingToTable: true,
          defendLock: false,
          flyingFromHand: false,
        ),
        isFalse,
      );
      expect(
        durakTableReadyForBitoFlight(
          remoteFlying: false,
          localFlyingToTable: false,
          defendLock: false,
          flyingFromHand: false,
        ),
        isTrue,
      );
    });
  });
}
