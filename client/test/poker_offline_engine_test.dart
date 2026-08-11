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
      // The best hand also carries its 5 chosen cards (for UI highlighting).
      expect(v.cards.length, 5);
    });

    test('hand rank names match the server strings', () {
      expect(pokerHandRankName(PokerHandRank.highCard), 'HighCard');
      expect(pokerHandRankName(PokerHandRank.onePair), 'OnePair');
      expect(pokerHandRankName(PokerHandRank.twoPair), 'TwoPair');
      expect(pokerHandRankName(PokerHandRank.threeOfAKind), 'ThreeOfAKind');
      expect(pokerHandRankName(PokerHandRank.straight), 'Straight');
      expect(pokerHandRankName(PokerHandRank.flush), 'Flush');
      expect(pokerHandRankName(PokerHandRank.fullHouse), 'FullHouse');
      expect(pokerHandRankName(PokerHandRank.fourOfAKind), 'FourOfAKind');
      expect(pokerHandRankName(PokerHandRank.straightFlush), 'StraightFlush');
      expect(pokerHandRankName(PokerHandRank.royalFlush), 'RoyalFlush');
    });
  });

  group('cash table (multi-hand)', () {
    PokerEngine freshHeadsUp({int chips = 1000, int seed = 1}) =>
        PokerEngine.newGame(
          playerIds: const ['p0', 'p1'],
          startingChips: chips,
          smallBlind: 5,
          bigBlind: 10,
          dealerIndex: 0,
          rng: Random(seed),
        );

    test('folding ends the hand but not the table; next hand starts', () {
      final g = freshHeadsUp();
      g.apply(0, const PokerAction(PokerActionType.fold));
      expect(g.handOver, isTrue);
      expect(g.tableOver, isFalse);
      expect(g.handNumber, 1);

      g.startNextHand(Random(2));
      expect(g.handNumber, 2);
      expect(g.handOver, isFalse);
      expect(g.status, PokerStatus.active);
      expect(g.dealerIndex, 1); // dealer rotated
      expect(g.players[0].hole.length, 2);
      expect(g.players[1].hole.length, 2);
      expect(g.pot, 15); // blinds posted again
    });

    test('bestHandFor is null before the flop (not enough cards)', () {
      final g = freshHeadsUp();
      expect(g.bestHandFor(0), isNull);
    });

    test('forfeit hands the table to the opponent (table over)', () {
      final g = freshHeadsUp();
      g.forfeitPlayer(0);
      expect(g.tableOver, isTrue);
      expect(g.handOver, isTrue);
      expect(g.isOver, isTrue);
      expect(g.winnerUserIds, contains('p1'));
      expect(g.players[0].chips, 0);
    });

    test('blinds rise after handsPerLevel hands', () {
      final g = freshHeadsUp(chips: 1000000, seed: 9);
      expect(g.bigBlind, 10);
      expect(g.blindLevel, 0);
      final perLevel = g.handsPerLevel;
      for (var h = 0; h < perLevel; h++) {
        g.apply(g.actingIndex, const PokerAction(PokerActionType.fold));
        expect(g.tableOver, isFalse);
        g.startNextHand(Random(100 + h));
      }
      expect(g.blindLevel, greaterThanOrEqualTo(1));
      expect(g.bigBlind, greaterThan(10));
      expect(g.smallBlind, g.bigBlind ~/ 2);
    });

    test('cannot start next hand while a hand is in progress', () {
      final g = freshHeadsUp();
      expect(() => g.startNextHand(Random(3)), throwsStateError);
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
      // Folding ends the HAND, but the table continues (both keep chips).
      expect(end.isOver, isFalse);
      expect(end.isTableOver, isFalse);
      expect(end.isHandOver, isTrue);
      expect(end.winners.contains(0), isFalse);
      // Фолд-вина: карты победителя скрыты, кнопка «Показать» только у победителя.
      expect(end.canShowCards, isFalse);
      expect(end.players[1].holeCards, isNull);
    });

    test('uncontested winner can show cards before next hand', () {
      final g = PokerEngine.newGame(
        playerIds: const ['p0', 'p1', 'p2'],
        startingChips: 1000,
        smallBlind: 5,
        bigBlind: 10,
        dealerIndex: 0,
        rng: Random(1),
      );
      // UTG folds, SB folds → BB wins uncontested.
      g.apply(0, const PokerAction(PokerActionType.fold));
      g.apply(1, const PokerAction(PokerActionType.fold));
      expect(g.street, PokerStreet.over);
      expect(g.canShowCards(2), isTrue);
      expect(g.canShowCards(0), isFalse);
      g.showCards(2);
      expect(g.players[2].shown, isTrue);
      expect(g.canShowCards(2), isFalse);
    });

    test('view exposes cash-table fields on a fresh table', () {
      final session = OfflinePokerSession.create(
        humanUserId: 'me',
        playerCount: 2,
      );
      addTearDown(session.dispose);
      final v = session.toView();
      expect(v.handNumber, 1);
      expect(v.blindLevel, 0);
      expect(v.handsPerLevel, greaterThan(0));
      expect(v.isHandOver, isFalse);
      expect(v.isTableOver, isFalse);
      expect(v.isOver, isFalse);
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
