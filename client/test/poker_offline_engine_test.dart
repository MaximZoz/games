import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/poker/poker_offline_engine.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';

PlayingCard _c(int rank, Suit suit) => PlayingCard(Rank(rank), suit);

void main() {
  group('hand evaluation', () {
    test('royal flush is the top category', () {
      final v = evaluateBestHand([
        _c(14, Suit.spades),
        _c(13, Suit.spades),
        _c(12, Suit.spades),
        _c(11, Suit.spades),
        _c(10, Suit.spades),
      ]);
      expect(v.rank, PokerHandRank.royalFlush);
    });

    test('full house beats a flush', () {
      final fullHouse = evaluateBestHand([
        _c(10, Suit.clubs),
        _c(10, Suit.hearts),
        _c(10, Suit.spades),
        _c(4, Suit.diamonds),
        _c(4, Suit.clubs),
      ]);
      final flush = evaluateBestHand([
        _c(14, Suit.hearts),
        _c(10, Suit.hearts),
        _c(8, Suit.hearts),
        _c(5, Suit.hearts),
        _c(2, Suit.hearts),
      ]);
      expect(fullHouse.rank, PokerHandRank.fullHouse);
      expect(flush.rank, PokerHandRank.flush);
      expect(fullHouse.compare(flush), greaterThan(0));
    });

    test('wheel straight (A-2-3-4-5) is a straight with 5 high', () {
      final v = evaluateBestHand([
        _c(14, Suit.spades),
        _c(2, Suit.hearts),
        _c(3, Suit.clubs),
        _c(4, Suit.diamonds),
        _c(5, Suit.spades),
      ]);
      expect(v.rank, PokerHandRank.straight);
      expect(v.tie.first, 5);
    });

    test('best of 7 cards picks the flush', () {
      final v = evaluateBestHand([
        _c(14, Suit.hearts),
        _c(9, Suit.hearts),
        _c(7, Suit.hearts),
        _c(4, Suit.hearts),
        _c(2, Suit.hearts),
        _c(13, Suit.clubs),
        _c(13, Suit.spades),
      ]);
      expect(v.rank, PokerHandRank.flush);
    });
  });

  group('engine blinds and fold win (heads-up)', () {
    PokerEngine freshHeadsUp() => PokerEngine.newGame(
          playerIds: const ['p0', 'p1'],
          startingChips: 1000,
          smallBlind: 5,
          bigBlind: 10,
          dealerIndex: 0,
          rng: Random(42),
        );

    test('blinds posted and hole cards dealt', () {
      final g = freshHeadsUp();
      expect(g.pot, 15);
      expect(g.currentBet, 10);
      expect(g.players[0].hole.length, 2);
      expect(g.players[1].hole.length, 2);
      // Heads-up: dealer is small blind and acts first pre-flop.
      expect(g.actingIndex, 0);
      final legal = g.legalActions(0);
      expect(legal, contains(PokerActionType.fold));
      expect(legal, contains(PokerActionType.call));
      expect(legal, isNot(contains(PokerActionType.check)));
    });

    test('folding hands the pot to the other player and ends the game', () {
      final g = freshHeadsUp();
      g.apply(0, const PokerAction(PokerActionType.fold));
      expect(g.isOver, isTrue);
      expect(g.winners, [1]);
      // p1 posted the big blind (10) then took the whole pot (15).
      expect(g.players[1].chips, 1005);
      expect(g.players[0].chips, 995);
    });
  });

  group('offline session', () {
    test('deals a hand and resolves a fold win via toView', () async {
      final session = OfflinePokerSession.create(
        humanUserId: 'me',
        playerCount: 2,
      );
      addTearDown(session.dispose);

      final start = session.toView();
      expect(start.players.length, 2);
      expect(start.myIndex, 0);
      expect(start.pot, 15);
      expect(start.isMyTurn, isTrue);
      // Hero always sees own hole cards.
      expect(start.me?.holeCards?.length, 2);

      await session.applyMove(type: PokerActionType.fold);
      final end = session.toView();
      expect(end.isOver, isTrue);
      expect(end.winners.contains(0), isFalse);
    });

    test('registry recognizes offline ids', () {
      final session = OfflinePokerSession.create(
        humanUserId: 'me',
        playerCount: 3,
      );
      addTearDown(session.dispose);
      expect(
        OfflinePokerRegistry.instance.isOffline(session.gameId),
        isTrue,
      );
      expect(OfflinePokerRegistry.instance.isOffline('online:123'), isFalse);
      expect(
        identical(
          OfflinePokerRegistry.instance.get(session.gameId),
          session,
        ),
        isTrue,
      );
    });
  });
}
