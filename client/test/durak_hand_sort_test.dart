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
      final sorted = List.of(hand)..sort(
        (a, b) => compareDurakHandCards(a, b, v.trumpCard.toPlayingCard().suit),
      );
      expect(hand, sorted);
    });

    test('fxHold blocks bots until deal/FX finish', () {
      final session = OfflineDurakSession.create(
        humanUserId: 'user-1',
        deckSize: 36,
        playerCount: 2,
        gameId: 'offline:durak:fx-hold',
      );
      addTearDown(session.dispose);
      session.setFxHold(true);
      session.markDealReady();
      expect(session.debugDealGraceDone, isTrue);
      expect(session.debugFxHold, isTrue);
      expect(session.debugBotTimerActive, isFalse);
      session.setFxHold(false);
      expect(session.debugFxHold, isFalse);
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
  });
}
