import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/games/durak/durak_hand_sort.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';

void main() {
  group('sortDurakHand', () {
    test('non-trump by suit then rank, trumps last', () {
      const trump = Suit.hearts;
      final hand = [
        PlayingCard(Rank.ace, Suit.hearts),
        PlayingCard(Rank.six, Suit.spades),
        PlayingCard(Rank.king, Suit.clubs),
        PlayingCard(Rank.seven, Suit.hearts),
        PlayingCard(Rank.ten, Suit.clubs),
      ];
      sortDurakHand(hand, trump);
      expect(hand.map((c) => '${c.rank.value}${c.suit.name}').toList(), [
        '10clubs',
        '13clubs',
        '6spades',
        '7hearts',
        '14hearts',
      ]);
    });
  });

  group('lowestTrumpInHand', () {
    test('picks lowest trump and ignores off-suit', () {
      expect(
        lowestTrumpInHand(
          const [
            PlayingCard(Rank.ace, Suit.hearts),
            PlayingCard(Rank.six, Suit.spades),
            PlayingCard(Rank.nine, Suit.hearts),
            PlayingCard(Rank.king, Suit.clubs),
          ],
          Suit.hearts,
        ),
        const PlayingCard(Rank.nine, Suit.hearts),
      );
    });

    test('null when no trump in hand', () {
      expect(
        lowestTrumpInHand(
          const [
            PlayingCard(Rank.six, Suit.spades),
            PlayingCard(Rank.ace, Suit.clubs),
          ],
          Suit.hearts,
        ),
        isNull,
      );
    });
  });

  group('drawUntilTrumpAppears', () {
    test('does nothing when someone already has a trump', () {
      final hands = [
        [const PlayingCard(Rank.nine, Suit.hearts)],
        [const PlayingCard(Rank.six, Suit.spades)],
      ];
      final deck = [
        const PlayingCard(Rank.ace, Suit.clubs),
        const PlayingCard(Rank.six, Suit.hearts),
      ];
      expect(
        drawUntilTrumpAppears(hands: hands, deck: deck, trump: Suit.hearts),
        0,
      );
      expect(hands[0], hasLength(1));
      expect(deck, hasLength(2));
    });

    test('players draw one each until a trump appears', () {
      final hands = [
        [
          const PlayingCard(Rank.six, Suit.spades),
          const PlayingCard(Rank.seven, Suit.spades),
          const PlayingCard(Rank.eight, Suit.spades),
          const PlayingCard(Rank.nine, Suit.clubs),
          const PlayingCard(Rank.ten, Suit.clubs),
          const PlayingCard(Rank.jack, Suit.clubs),
        ],
        [
          const PlayingCard(Rank.six, Suit.diamonds),
          const PlayingCard(Rank.seven, Suit.diamonds),
          const PlayingCard(Rank.eight, Suit.diamonds),
          const PlayingCard(Rank.nine, Suit.spades),
          const PlayingCard(Rank.ten, Suit.spades),
          const PlayingCard(Rank.jack, Suit.diamonds),
        ],
      ];
      final deck = [
        const PlayingCard(Rank.queen, Suit.clubs),
        const PlayingCard(Rank.six, Suit.hearts),
        const PlayingCard(Rank.ace, Suit.hearts),
      ];
      expect(
        drawUntilTrumpAppears(hands: hands, deck: deck, trump: Suit.hearts),
        1,
      );
      expect(hands[0], hasLength(7));
      expect(hands[1], hasLength(7));
      expect(hands[1].last, const PlayingCard(Rank.six, Suit.hearts));
      expect(deck, hasLength(1));
    });
  });

  group('durakOpeningDealConcealsFan', () {
    test('первый кадр свежей партии прячет веер', () {
      expect(
        durakOpeningDealConcealsFan(
          prevDeckUninitialized: true,
          shouldAnimateOpening: true,
        ),
        isTrue,
      );
    });

    test('добор: слот в веере до полёта, сортировка на месте', () {
      const seated = PlayingCard(Rank.six, Suit.clubs);
      const incoming = PlayingCard(Rank.seven, Suit.hearts);
      expect(
        durakReserveDealFanSlot(
          seated: const [seated],
          incoming: incoming,
          compare: (a, b) => compareDurakHandCards(a, b, Suit.hearts),
        ),
        const [seated, incoming],
      );
      expect(
        durakKeepFanFreezeAfterDealBatch(
          openingDeal: true,
          manageBusy: false,
        ),
        isTrue,
      );
      expect(
        durakKeepFanFreezeAfterDealBatch(
          openingDeal: false,
          manageBusy: true,
        ),
        isFalse,
      );
    });

    test('после базы колоды веер не прячем этим флагом', () {
      expect(
        durakOpeningDealConcealsFan(
          prevDeckUninitialized: false,
          shouldAnimateOpening: true,
        ),
        isFalse,
      );
    });

    test('во время раздачи посаженные карты остаются при пустом pending', () {
      const six = PlayingCard(Rank.six, Suit.clubs);
      const seven = PlayingCard(Rank.seven, Suit.diamonds);
      const eight = PlayingCard(Rank.eight, Suit.hearts);
      expect(
        durakOpeningDealPendingSet(
          concealOpeningHand: true,
          pendingDealCards: const {},
          handOrder: const [six, seven],
          incomingFanCards: const [],
          serverHand: const [six, seven, eight],
        ),
        {eight},
      );
      expect(
        durakOrderedHandSlots(
          prevOrder: const [six, seven],
          serverHand: const [six, seven, eight],
          pendingDeal: durakOpeningDealPendingSet(
            concealOpeningHand: true,
            pendingDealCards: const {},
            handOrder: const [six, seven],
            incomingFanCards: const [],
            serverHand: const [six, seven, eight],
          ),
          leavingHand: const {},
          holeCards: const {},
        ),
        const [six, seven],
      );
    });

    test('первый кадр раздачи прячет всю руку', () {
      const six = PlayingCard(Rank.six, Suit.clubs);
      const ace = PlayingCard(Rank.ace, Suit.spades);
      expect(
        durakOpeningDealPendingSet(
          concealOpeningHand: true,
          pendingDealCards: const {},
          handOrder: const [],
          incomingFanCards: const [],
          serverHand: const [six, ace],
        ),
        {six, ace},
      );
    });

    test('pending раздачи не даёт дописать руку в пустой order', () {
      const six = PlayingCard(Rank.six, Suit.clubs);
      const ace = PlayingCard(Rank.ace, Suit.spades);
      expect(
        durakOrderedHandSlots(
          prevOrder: const [],
          serverHand: const [six, ace],
          pendingDeal: {six, ace},
          leavingHand: const {},
          holeCards: const {},
        ),
        isEmpty,
      );
      expect(
        durakOrderedHandSlots(
          prevOrder: null,
          serverHand: const [six, ace],
          pendingDeal: {six, ace},
          leavingHand: const {},
          holeCards: const {},
        ),
        isEmpty,
      );
    });
  });

  group('shouldAnimateDurakOpeningDeal', () {
    test('fresh 36-card heads-up qualifies', () {
      expect(
        shouldAnimateDurakOpeningDeal(
          isOver: false,
          tableIsEmpty: true,
          bitoCount: 0,
          myIndex: 0,
          myHandLen: 6,
          handCounts: const [6, 6],
          deckSize: 36,
          deckCount: 24,
        ),
        isTrue,
      );
    });

    test('fresh deal with extra trump-hunt cards qualifies', () {
      expect(
        shouldAnimateDurakOpeningDeal(
          isOver: false,
          tableIsEmpty: true,
          bitoCount: 0,
          myIndex: 0,
          myHandLen: 7,
          handCounts: const [7, 7],
          deckSize: 36,
          deckCount: 22,
        ),
        isTrue,
      );
    });

    test('rejects mid-hand or after bito', () {
      expect(
        shouldAnimateDurakOpeningDeal(
          isOver: false,
          tableIsEmpty: true,
          bitoCount: 2,
          myIndex: 0,
          myHandLen: 6,
          handCounts: const [6, 6],
          deckSize: 36,
          deckCount: 24,
        ),
        isFalse,
      );
    });
  });

  group('OfflineDurakSession FX hold', () {
    test('fresh view matches opening-deal predicate', () {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:sort-fx',
      );
      addTearDown(session.dispose);
      final v = session.view;
      expect(
        shouldAnimateDurakOpeningDeal(
          isOver: v.isOver,
          tableIsEmpty: v.table.isEmpty,
          bitoCount: v.bitoCount,
          myIndex: v.myIndex,
          myHandLen: v.hands[v.myIndex].count,
          handCounts: [for (final h in v.hands) h.count],
          deckSize: v.deckSize,
          deckCount: v.deckCount,
        ),
        isTrue,
      );
      final hand = v.hands[0].cards!.map((c) => c.toPlayingCard()).toList();
      final sorted = List.of(hand)
        ..sort(
          (a, b) =>
              compareDurakHandCards(a, b, v.trumpCard.toPlayingCard().suit),
        );
      expect(v.isOver, isFalse);
      expect(v.firstRound, isTrue);
      expect(v.hasBotOpponent, isTrue);
      expect(hand, sorted);
      final expectedLead = lowestTrumpInHand(
        session.engine.hands[v.attackerIndex],
        v.trumpCard.toPlayingCard().suit,
      );
      if (expectedLead == null) {
        expect(v.leadTrump, isNull);
      } else {
        expect(v.leadTrump?.toPlayingCard(), expectedLead);
      }
    });

    test('fxHold keeps retry timer but bot does not attack', () {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:fx-hold',
      );
      addTearDown(session.dispose);
      final g = session.engine;
      g.attackerIndex = 1;
      g.throwerIndex = 1;
      g.turn = DurakTurn.attacker;
      g.table.clear();
      if (g.hands[1].isEmpty) {
        g.hands[1].add(const PlayingCard(Rank.seven, Suit.spades));
      }
      session.setFxHold(true);
      session.markDealReady();
      expect(session.debugDealGraceDone, isTrue);
      expect(session.debugFxHold, isTrue);
      expect(session.debugBotTimerActive, isTrue);
      session.setFxHold(false);
      expect(session.debugFxHold, isFalse);
    });

    test('bot says bito after full defense even if fxHold stuck', () async {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:bot-bito',
      );
      addTearDown(session.dispose);
      session.setFxHold(true);
      session.markDealReady();

      final g = session.engine;
      final attackSuit = g.trump == Suit.clubs ? Suit.spades : Suit.clubs;
      final attack = PlayingCard(Rank.six, attackSuit);
      final defense = PlayingCard(Rank.ace, attackSuit);
      g.attackerIndex = 1;
      g.throwerIndex = 1;
      g.turn = DurakTurn.defender;
      g.table
        ..clear()
        ..add(TablePair(attack));
      g.hands[0]
        ..clear()
        ..add(defense)
        ..add(PlayingCard(Rank.king,
            attackSuit == Suit.diamonds ? Suit.spades : Suit.diamonds));
      g.hands[1]
        ..clear()
        ..add(PlayingCard(Rank.six, g.trump));

      await session.applyMove(type: 'defend', card: defense);
      expect(g.turn, DurakTurn.attackerFollowUp);
      expect(g.canAttackerSayBito, isTrue);
      expect(session.debugFxHold, isTrue);
      expect(session.debugBotTimerActive, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(session.view.phase, 'bito_reveal');
      expect(session.view.table, isNotEmpty);

      final after = await session.waitUntilRevealDone();
      expect(after.table, isEmpty);
      expect(after.bitoCount, greaterThan(0));
    });

    test('последний отбой остаётся на столе около двух секунд', () async {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:last-trick',
      );
      addTearDown(session.dispose);
      final g = session.engine;
      g.deck.cards.clear();
      const attack = PlayingCard(Rank.nine, Suit.hearts);
      const defense = PlayingCard(Rank.ten, Suit.hearts);
      g.attackerIndex = 1;
      g.throwerIndex = 1;
      g.turn = DurakTurn.defender;
      g.table
        ..clear()
        ..add(const TablePair(attack));
      g.hands[0]
        ..clear()
        ..add(defense);
      g.hands[1].clear();
      g.bito.clear();
      g.finishedIndices.clear();
      g.loserIndex = null;
      g.endedInDraw = false;

      final started = DateTime.now();
      await session.applyMove(type: 'defend', card: defense);
      expect(session.view.phase, 'bito_reveal');
      expect(session.view.table, isNotEmpty);
      expect(g.completingRevealEndsMatch(), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(session.view.phase, 'bito_reveal');
      expect(session.view.table, isNotEmpty);

      final after = await session.waitUntilRevealDone();
      final elapsed = DateTime.now().difference(started);
      expect(after.table, isEmpty);
      expect(after.isOver, isTrue);
      expect(after.isDraw, isTrue);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(1900));
      expect(elapsed.inMilliseconds, lessThan(3500));
    });

    test('restart yields a fresh opening-deal view', () {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:rematch-fx',
      );
      addTearDown(session.dispose);
      session.engine.loserIndex = 0;
      expect(session.view.isOver, isTrue);
      session.restart();
      final v = session.view;
      expect(v.isOver, isFalse);
      expect(v.firstRound, isTrue);
      expect(session.debugDealGraceDone, isFalse);
      expect(
        shouldAnimateDurakOpeningDeal(
          isOver: v.isOver,
          tableIsEmpty: v.table.isEmpty,
          bitoCount: v.bitoCount,
          myIndex: v.myIndex,
          myHandLen: v.hands[v.myIndex].count,
          handCounts: [for (final h in v.hands) h.count],
          deckSize: v.deckSize,
          deckCount: v.deckCount,
        ),
        isTrue,
      );
    });

    test('waitUntilRevealDone: стол уходит только после паузы take', () async {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:reveal-wait',
      );
      addTearDown(session.dispose);
      session.setFxHold(true);
      session.markDealReady();

      final g = session.engine;
      g.attackerIndex = 1;
      g.throwerIndex = 1;
      g.turn = DurakTurn.defender;
      g.table
        ..clear()
        ..add(const TablePair(PlayingCard(Rank.six, Suit.clubs)));
      g.hands[1]
        ..clear()
        ..add(const PlayingCard(Rank.ace, Suit.spades));

      await session.applyMove(type: 'take');
      expect(session.view.phase, 'take_reveal');
      expect(session.view.table, isNotEmpty);

      final after = await session.waitUntilRevealDone();
      expect(after.phase, isNot(equals('take_reveal')));
      expect(after.table, isEmpty);
      expect(after.lastWasTake, isTrue);
    });

    test('переводной: после перевода бот ходит без снятия вкладки', () async {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        mode: durakModePerevodnoi,
        gameId: 'offline:durak:transfer-bot',
      );
      addTearDown(session.dispose);
      session.markDealReady();

      final g = session.engine;
      final attackSuit = g.trump == Suit.hearts ? Suit.spades : Suit.hearts;
      g.attackerIndex = 1;
      g.throwerIndex = 1;
      g.turn = DurakTurn.defender;
      g.table
        ..clear()
        ..add(TablePair(PlayingCard(Rank.ten, attackSuit)));
      g.hands[0]
        ..clear()
        ..add(PlayingCard(
            Rank.ten, g.trump == Suit.clubs ? Suit.diamonds : Suit.clubs))
        ..add(PlayingCard(Rank.king, attackSuit));
      g.hands[1]
        ..clear()
        ..add(PlayingCard(Rank.ace, attackSuit))
        ..add(PlayingCard(Rank.six, g.trump));

      expect(session.debugFxHold, isFalse);
      await session.applyMove(
        type: 'transfer',
        card: PlayingCard(
          Rank.ten,
          g.trump == Suit.clubs ? Suit.diamonds : Suit.clubs,
        ),
      );
      expect(g.turn, DurakTurn.defender);
      expect(g.defenderIndex, 1);
      expect(session.debugBotTimerActive, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(g.table.any((p) => p.defense != null), isTrue);
    });

    test('waitUntilRevealDone: бито нотифаит пустой стол до UI-hold', () async {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:bito-empty-notify',
      );
      addTearDown(session.dispose);
      session.markDealReady();

      final g = session.engine;
      final attackSuit = g.trump == Suit.clubs ? Suit.spades : Suit.clubs;
      g.attackerIndex = 0;
      g.throwerIndex = 0;
      g.turn = DurakTurn.attackerFollowUp;
      g.table
        ..clear()
        ..add(TablePair(
          PlayingCard(Rank.six, attackSuit),
          PlayingCard(Rank.ace, attackSuit),
        ));
      g.hands[0]
        ..clear()
        ..add(PlayingCard(Rank.king, g.trump));
      g.hands[1]
        ..clear()
        ..add(PlayingCard(Rank.seven,
            attackSuit == Suit.diamonds ? Suit.spades : Suit.diamonds));

      expect(session.view.table, isNotEmpty);
      await session.applyMove(type: 'bito');
      expect(session.view.phase, 'bito_reveal');
      expect(session.view.table, isNotEmpty);

      var notifiedEmpty = false;
      void onChanged() {
        if (session.view.table.isEmpty) notifiedEmpty = true;
      }

      session.addListener(onChanged);
      addTearDown(() => session.removeListener(onChanged));
      final after = await session.waitUntilRevealDone();
      expect(after.table, isEmpty);
      expect(notifiedEmpty, isTrue);
    });
  });

  group('durak played-away fan', () {
    const sixClubs = PlayingCard(Rank.six, Suit.clubs);
    const aceSpades = PlayingCard(Rank.ace, Suit.spades);
    const kingHearts = PlayingCard(Rank.king, Suit.hearts);

    test('ход убирает карту из веера, взятие — нет', () {
      expect(
        durakCardLeftHandForPlay(
          markedPlayedAway: true,
          optimisticAttack: false,
          flyingToTable: false,
          flyingFromHand: true,
          incomingToFan: false,
          inHandOrder: false,
        ),
        isTrue,
      );
      expect(
        durakCardLeftHandForPlay(
          markedPlayedAway: false,
          optimisticAttack: false,
          flyingToTable: false,
          flyingFromHand: true,
          incomingToFan: false,
          inHandOrder: true,
        ),
        isFalse,
      );
      expect(
        durakCardLeftHandForPlay(
          markedPlayedAway: true,
          optimisticAttack: false,
          flyingToTable: false,
          flyingFromHand: false,
          incomingToFan: true,
          inHandOrder: true,
        ),
        isFalse,
      );
    });

    test('устаревшая рука сервера не возвращает сыгранную карту в order', () {
      final next = durakMergeHandOrderAfterMove(
        prevOrder: const [aceSpades, kingHearts],
        serverHand: const [sixClubs, aceSpades, kingHearts],
        pendingDeal: const {},
        leavingHand: {sixClubs},
      );
      expect(next, const [aceSpades, kingHearts]);
    });

    test('после отпускания ход сразу схлопывает слот веера', () {
      expect(
        durakFanKeepsHoleSlot(
          inLocalOrder: true,
          incomingToFan: false,
          markedPlayedAway: true,
          flyingFromHand: true,
        ),
        isFalse,
      );
      expect(
        durakFanHoleCards(
          playedAway: const [sixClubs],
          flyingFromHand: const [sixClubs],
          incomingFanCards: const [],
        ),
        isEmpty,
      );
      final holes = durakOrderedHandSlots(
        prevOrder: const [aceSpades, kingHearts],
        serverHand: const [aceSpades, kingHearts],
        pendingDeal: const {},
        leavingHand: {sixClubs},
        holeCards: durakFanHoleCards(
          playedAway: const [sixClubs],
          flyingFromHand: const [sixClubs],
          incomingFanCards: const [],
        ),
      );
      expect(holes, const [aceSpades, kingHearts]);
    });

    test('взятие держит дырку, пока карта садится в веер', () {
      expect(
        durakFanKeepsHoleSlot(
          inLocalOrder: true,
          incomingToFan: true,
          markedPlayedAway: false,
          flyingFromHand: true,
        ),
        isTrue,
      );
      expect(
        durakFanHoleCards(
          playedAway: const [],
          flyingFromHand: const [sixClubs],
          incomingFanCards: const [sixClubs],
        ),
        contains(sixClubs),
      );
    });

    test('после посадки устаревший снимок не возвращает карту в слоты', () {
      final slots = durakOrderedHandSlots(
        prevOrder: const [aceSpades, kingHearts],
        serverHand: const [sixClubs, aceSpades, kingHearts],
        pendingDeal: const {},
        leavingHand: {sixClubs},
        holeCards: {sixClubs},
      );
      expect(slots, const [aceSpades, kingHearts]);
    });

    test('после хода карта gone, даже если снова попала в order', () {
      final gone = durakCardsGoneFromFan(
        playedAway: const [sixClubs],
        optimisticAttacks: const [],
        flyingToTable: const [],
        flyingFromHand: const [],
        incomingFanCards: const [],
        handOrder: const [sixClubs, aceSpades],
      );
      expect(gone, contains(sixClubs));
      expect(gone, isNot(contains(aceSpades)));
    });

    test('взятие: полёт из руки при слоте в order — не gone', () {
      final gone = durakCardsGoneFromFan(
        playedAway: const [],
        optimisticAttacks: const [],
        flyingToTable: const [],
        flyingFromHand: const [sixClubs],
        incomingFanCards: const [sixClubs],
        handOrder: const [sixClubs, aceSpades],
      );
      expect(gone, isEmpty);
    });

    test('сыгранную не забываем, пока не сядет обратно в веер', () {
      expect(
        durakRetainPlayedAway(
          playedAway: const [sixClubs, aceSpades],
          incomingFanCards: const [],
          pendingDealCards: const [],
        ),
        {sixClubs, aceSpades},
      );
      expect(
        durakRetainPlayedAway(
          playedAway: const [sixClubs, aceSpades],
          incomingFanCards: const [sixClubs],
          pendingDealCards: const [],
        ),
        {aceSpades},
      );
    });
  });
}
