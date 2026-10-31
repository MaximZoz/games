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

  group('durakFirstLeadShowsBannerCard', () {
    test('в альбоме мини-карта не нужна — достаточно надписи и анимации', () {
      expect(durakFirstLeadShowsBannerCard(compact: true), isFalse);
    });

    test('в портрете мини-карта тоже не рисуется', () {
      expect(durakFirstLeadShowsBannerCard(compact: false), isFalse);
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
    test('в альбоме твин короче портретного, но не нулевой', () {
      final compact = durakLayoutTweenDuration(compact: true);
      // Нулевой твин схлопывал веер рывком — теперь короткий, но живой.
      expect(compact, greaterThan(Duration.zero));
      expect(
        durakLayoutTweenDuration(compact: false).inMilliseconds,
        greaterThan(compact.inMilliseconds),
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

    test('добор прячет новые рубашки, пока они летят из колоды', () {
      expect(
        durakOpponentFanShownCount(serverCount: 6, hidden: 6),
        0,
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
      expect(durakDealFlyDuration(compact: true).inMilliseconds, 260);
      expect(durakDealFlyDuration(compact: false).inMilliseconds, 240);
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
      expect(durakStuckSnapTicks(compact: true), 2);
      expect(durakStuckSnapTicks(compact: false), 3);
      expect(durakStuckSnapTicks(compact: true, openingDeal: true), 5);
      expect(
        durakActionChromeVisible(
          liveCanShow: true,
          holdingFanCard: false,
        ),
        isTrue,
      );
      expect(
        durakActionChromeVisible(
          liveCanShow: true,
          holdingFanCard: true,
        ),
        isFalse,
      );
      expect(kDurakMyTurnIdleHintDelay, const Duration(seconds: 10));
      expect(
        durakMyTurnIdleHintVisible(
          isMyTurn: true,
          holdingFanCard: false,
          idleElapsed: true,
          gameOver: false,
        ),
        isTrue,
      );
      expect(
        durakMyTurnIdleHintVisible(
          isMyTurn: true,
          holdingFanCard: false,
          idleElapsed: false,
          gameOver: false,
        ),
        isFalse,
      );
      expect(
        durakMyTurnIdleHintVisible(
          isMyTurn: true,
          holdingFanCard: true,
          idleElapsed: true,
          gameOver: false,
        ),
        isFalse,
      );
      expect(
        durakMyTurnIdleClockActive(
          isMyTurn: true,
          gameOver: false,
          localPlayActive: false,
        ),
        isTrue,
      );
      expect(
        durakMyTurnIdleClockActive(
          isMyTurn: true,
          gameOver: false,
          localPlayActive: true,
        ),
        isFalse,
      );
      expect(
        durakFirstLeadBannerVisible(
          firstRound: true,
          tableEmpty: true,
          firstLeadArmed: true,
          holdingFanCard: false,
          gameOver: false,
        ),
        isTrue,
      );
      expect(
        durakFirstLeadBannerVisible(
          firstRound: true,
          tableEmpty: true,
          firstLeadArmed: true,
          holdingFanCard: true,
          gameOver: false,
        ),
        isFalse,
      );
      expect(
          durakRevealTableBeforeDismissOverlay(tableCardVisible: true), isTrue);
      expect(
        durakRevealTableBeforeDismissOverlay(tableCardVisible: false),
        isFalse,
      );
    });

    test('добор не в веере, пока карта pending — даже во время полёта', () {
      expect(durakDealCardInFanLayout(pendingDeal: true), isFalse);
      expect(durakDealCardInFanLayout(pendingDeal: false), isTrue);
    });

    test('победа и реванш — после паузы на последний отбой', () {
      expect(
        kDurakFinishAfterLastTrickPause.inMilliseconds,
        greaterThanOrEqualTo(800),
      );
      expect(
        durakFinishChromeVisible(isOver: true, finishReady: false),
        isFalse,
      );
      expect(
        durakFinishChromeVisible(isOver: true, finishReady: true),
        isTrue,
      );
      expect(
        durakFinishHoldNeeded(
          isOver: true,
          finishReady: false,
          alreadyScheduled: false,
        ),
        isTrue,
      );
      expect(
        durakFinishHoldNeeded(
          isOver: true,
          finishReady: true,
          alreadyScheduled: false,
        ),
        isFalse,
      );
      expect(
        durakRevealFinishImmediately(
          openedAsObserver: true,
          firstSnapshotAlreadyOver: false,
          flightActive: true,
        ),
        isTrue,
      );
      expect(
        durakRevealFinishImmediately(
          openedAsObserver: false,
          firstSnapshotAlreadyOver: true,
          flightActive: false,
        ),
        isTrue,
      );
      expect(
        durakRevealFinishImmediately(
          openedAsObserver: false,
          firstSnapshotAlreadyOver: false,
          flightActive: false,
        ),
        isFalse,
      );
    });

    test('в биту — только после посадки отбоя', () {
      expect(kDurakBitoAfterDefensePause.inMilliseconds,
          greaterThanOrEqualTo(800));
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

    test('после «Беру» соперника сначала подпись, потом Готово', () {
      expect(kDurakOpponentTakeHold, const Duration(seconds: 1));
      expect(
        durakShowOpponentTakeLabel(
          takeFollow: true,
          opponentIsDefender: true,
          holdActive: true,
        ),
        isTrue,
      );
      expect(
        durakShowOpponentTakeLabel(
          takeFollow: true,
          opponentIsDefender: true,
          holdActive: false,
        ),
        isFalse,
      );
      expect(
        durakShowOpponentTakeLabel(
          takeFollow: true,
          opponentIsDefender: false,
          holdActive: true,
        ),
        isFalse,
      );
      expect(
        durakShowDoneAfterOpponentTake(
          canDone: true,
          takeLabelActive: true,
        ),
        isFalse,
      );
      expect(
        durakShowDoneAfterOpponentTake(
          canDone: true,
          takeLabelActive: false,
        ),
        isTrue,
      );
      expect(kDurakFanPlayCloseDuration.inMilliseconds, 180);
      expect(kDurakFanIncomingDuration, kDurakFanPlayCloseDuration);
      expect(
        durakFanLayoutTweenDuration(compact: true, fastClose: true),
        kDurakFanPlayCloseDuration,
      );
      expect(
        durakFanLayoutTweenDuration(compact: true, fastClose: false),
        durakLayoutTweenDuration(compact: true),
      );
    });
  });

  group('мгновенная бита и память стола', () {
    test('пас закрывает раунд, только если больше некому подкинуть', () {
      expect(
        durakRoundEndsOnPass(
          actorIndex: 0,
          playerCount: 2,
          handCounts: const [3, 4],
          canStillThrow: (seat) => seat != 1,
        ),
        isTrue,
      );
      expect(
        durakRoundEndsOnPass(
          actorIndex: 0,
          playerCount: 3,
          handCounts: const [2, 0, 3],
          canStillThrow: (seat) => seat != 1,
        ),
        isFalse,
      );
      expect(
        durakRoundEndsOnPass(
          actorIndex: 0,
          playerCount: 3,
          handCounts: const [2, 0, 0],
          canStillThrow: (seat) => seat != 1,
        ),
        isTrue,
      );
    });

    test('добор идёт по порядку и не больше колоды', () {
      final dealt = durakPredictRefillCounts(
        order: const [0, 2, 1],
        handCounts: const [4, 5, 6],
        deckCount: 3,
        alive: (_) => true,
      );
      expect(dealt[0], 2);
      expect(dealt[2], isNull);
      expect(dealt[1], 1);
    });

    test('невидимый отбой не записывается в prev', () {
      expect(
        durakKeepDefenseInPrevTable(
          hasDefense: true,
          alreadyVisible: false,
          wasInPrevious: false,
        ),
        isFalse,
      );
      expect(
        durakKeepDefenseInPrevTable(
          hasDefense: true,
          alreadyVisible: true,
          wasInPrevious: false,
        ),
        isTrue,
      );
      expect(
        durakKeepDefenseInPrevTable(
          hasDefense: false,
          alreadyVisible: true,
          wasInPrevious: true,
        ),
        isFalse,
      );
    });

    test('пустой кадр без биты не стирает стол', () {
      expect(
        durakRetainTableAcrossEmptyFrame(
          bitoGrew: false,
          lastWasTake: false,
          tableReveal: false,
          hidingTable: false,
        ),
        isTrue,
      );
      expect(
        durakRetainTableAcrossEmptyFrame(
          bitoGrew: true,
          lastWasTake: false,
          tableReveal: false,
          hidingTable: false,
        ),
        isFalse,
      );
      expect(
        durakRetainTableAcrossEmptyFrame(
          bitoGrew: false,
          lastWasTake: true,
          tableReveal: false,
          hidingTable: false,
        ),
        isFalse,
      );
      expect(kDurakActionPressFeedback.inMilliseconds, greaterThan(0));
    });

    test('старый кадр не переигрывает локальную биту', () {
      expect(
        durakServerSnapshotBehindLocalRound(
          tableReveal: true,
          serverBito: 6,
          lockedBito: 2,
          serverDeck: 10,
          lockedDeck: 20,
          serverHand: 6,
          lockedHand: 4,
          serverTable: 0,
          lockedTable: 2,
        ),
        isTrue,
      );
      expect(
        durakServerSnapshotBehindLocalRound(
          tableReveal: false,
          serverBito: 2,
          lockedBito: 2,
          serverDeck: 20,
          lockedDeck: 20,
          serverHand: 4,
          lockedHand: 4,
          serverTable: 2,
          lockedTable: 2,
        ),
        isTrue,
      );
      expect(
        durakServerSnapshotBehindLocalRound(
          tableReveal: false,
          serverBito: 6,
          lockedBito: 2,
          serverDeck: 16,
          lockedDeck: 20,
          serverHand: 6,
          lockedHand: 4,
          serverTable: 0,
          lockedTable: 2,
        ),
        isFalse,
      );
    });

    test('оптимистичный отбой остаётся, пока атака не закрыта', () {
      expect(
        durakOptimisticDefenseRetires(
          serverHasDefense: false,
          attackStillOpen: true,
        ),
        isFalse,
      );
      expect(
        durakOptimisticDefenseRetires(
          serverHasDefense: true,
          attackStillOpen: true,
        ),
        isTrue,
      );
      expect(
        durakOptimisticDefenseRetires(
          serverHasDefense: false,
          attackStillOpen: false,
        ),
        isTrue,
      );
    });

    test('локальный добор соперника не прячется за старым счётчиком', () {
      expect(
        durakOpponentFanShownCount(serverCount: 4, hidden: 0, atLeast: 6),
        6,
      );
      expect(
        durakOpponentFanShownCount(serverCount: 6, hidden: 0, atLeast: 6),
        6,
      );
    });
  });
}
