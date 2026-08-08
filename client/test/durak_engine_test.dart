import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_bot.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';

void main() {
  group('PlayingCard.beats', () {
    test('same suit — higher rank wins', () {
      expect(
        PlayingCard(Rank.jack, Suit.hearts)
            .beats(PlayingCard(Rank.ten, Suit.hearts), Suit.clubs),
        isTrue,
      );
      expect(
        PlayingCard(Rank.ten, Suit.hearts)
            .beats(PlayingCard(Rank.jack, Suit.hearts), Suit.clubs),
        isFalse,
      );
    });

    test('different non-trump suits — cannot beat', () {
      expect(
        PlayingCard(Rank.ace, Suit.hearts)
            .beats(PlayingCard(Rank.six, Suit.diamonds), Suit.clubs),
        isFalse,
      );
    });

    test('trump beats any non-trump', () {
      expect(
        PlayingCard(Rank.six, Suit.clubs)
            .beats(PlayingCard(Rank.ace, Suit.hearts), Suit.clubs),
        isTrue,
      );
      expect(
        PlayingCard(Rank.ace, Suit.hearts)
            .beats(PlayingCard(Rank.six, Suit.clubs), Suit.clubs),
        isFalse,
      );
    });

    test('trump vs trump — higher rank wins', () {
      expect(
        PlayingCard(Rank.queen, Suit.clubs)
            .beats(PlayingCard(Rank.jack, Suit.clubs), Suit.clubs),
        isTrue,
      );
      expect(
        PlayingCard(Rank.jack, Suit.clubs)
            .beats(PlayingCard(Rank.queen, Suit.clubs), Suit.clubs),
        isFalse,
      );
    });
  });

  group('Deck', () {
    test('36-card deck contains 6..A across 4 suits', () {
      final deck = Deck.standard(36, seed: 1);
      expect(deck.length, 36);
      final values = deck.cards.map((c) => c.rank.value).toSet();
      expect(values, equals({6, 7, 8, 9, 10, 11, 12, 13, 14}));
    });

    test('24-card deck contains 9..A', () {
      final deck = Deck.standard(24, seed: 2);
      expect(deck.length, 24);
      final values = deck.cards.map((c) => c.rank.value).toSet();
      expect(values, equals({9, 10, 11, 12, 13, 14}));
    });

    test('52-card deck contains 2..A', () {
      final deck = Deck.standard(52, seed: 3);
      expect(deck.length, 52);
      final values = deck.cards.map((c) => c.rank.value).toSet();
      expect(values, equals({2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}));
    });
  });

  group('DurakGame.startNew', () {
    test('deals 6 cards to each player and exposes trump', () {
      final game = DurakGame.startNew(playerCount: 2, seed: 42);
      expect(game.hands.length, 2);
      expect(game.hands[0].length, 6);
      expect(game.hands[1].length, 6);
      // 36 - 12 = 24 в колоде (включая открытый козырь снизу).
      expect(game.deck.length, 24);
      expect(game.openTrumpCard, isNotNull);
      expect(game.openTrumpCard!.suit, game.trump);
    });

    test('starting attacker has the lowest trump (if any)', () {
      final game = DurakGame.startNew(playerCount: 2, seed: 42);
      final trumps = <int, List<int>>{
        0: game.hands[0]
            .where((c) => c.suit == game.trump)
            .map((c) => c.rank.value)
            .toList(),
        1: game.hands[1]
            .where((c) => c.suit == game.trump)
            .map((c) => c.rank.value)
            .toList(),
      };
      final anyTrump = trumps.values.any((l) => l.isNotEmpty);
      if (!anyTrump) return;
      final minEach = trumps.map(
        (k, v) => MapEntry(k, v.isEmpty ? 100 : v.reduce((a, b) => a < b ? a : b)),
      );
      final expected =
          minEach.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
      expect(game.attackerIndex, expected);
    });
  });

  group('DurakGame moves', () {
    test('cannot attack with card not in hand', () {
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.six, Suit.hearts)],
          [PlayingCard(Rank.seven, Suit.clubs)],
        ],
        deck: Deck([]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      expect(
        game.canAttackWith(PlayingCard(Rank.eight, Suit.hearts), 0),
        isFalse,
      );
    });

    test('attack -> defend last card auto-bito clears table', () {
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.six, Suit.hearts)],
          [PlayingCard(Rank.seven, Suit.hearts)],
        ],
        deck: Deck([
          PlayingCard(Rank.eight, Suit.clubs),
          PlayingCard(Rank.nine, Suit.clubs),
          PlayingCard(Rank.ten, Suit.clubs),
          PlayingCard(Rank.jack, Suit.clubs),
          PlayingCard(Rank.queen, Suit.clubs),
          PlayingCard(Rank.king, Suit.clubs),
          PlayingCard(Rank.ace, Suit.clubs),
          PlayingCard(Rank.eight, Suit.diamonds),
          PlayingCard(Rank.nine, Suit.diamonds),
          PlayingCard(Rank.ten, Suit.diamonds),
          PlayingCard(Rank.jack, Suit.diamonds),
          PlayingCard(Rank.queen, Suit.diamonds),
        ]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      game.attack(PlayingCard(Rank.six, Suit.hearts), playerIndex: 0);
      expect(game.table.length, 1);
      expect(game.turn, DurakTurn.defender);

      // Последняя карта защитника — сразу бита, без кнопки.
      game.defend(PlayingCard(Rank.seven, Suit.hearts), playerIndex: 1);
      expect(game.table, isEmpty);
      expect(game.bito.length, 2);
      expect(game.attackerIndex, 1);
      expect(game.turn, DurakTurn.attacker);
    });

    test('both empty after last defend is draw', () {
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.nine, Suit.hearts)],
          [PlayingCard(Rank.ten, Suit.hearts)],
        ],
        deck: Deck([]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      game.attack(PlayingCard(Rank.nine, Suit.hearts), playerIndex: 0);
      game.defend(PlayingCard(Rank.ten, Suit.hearts), playerIndex: 1);
      expect(game.isOver, isTrue);
      expect(game.endedInDraw, isTrue);
      expect(game.loserIndex, isNull);
      expect(game.table, isEmpty);
    });

    test('empty hand returns unbeaten attack to attacker', () {
      final king = PlayingCard(Rank.king, Suit.spades);
      final ten = PlayingCard(Rank.ten, Suit.hearts);
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.eight, Suit.spades)],
          [ten],
        ],
        deck: Deck([
          PlayingCard(Rank.six, Suit.clubs),
          PlayingCard(Rank.seven, Suit.clubs),
          PlayingCard(Rank.eight, Suit.clubs),
          PlayingCard(Rank.nine, Suit.clubs),
          PlayingCard(Rank.ten, Suit.clubs),
          PlayingCard(Rank.jack, Suit.clubs),
          PlayingCard(Rank.queen, Suit.clubs),
          PlayingCard(Rank.ace, Suit.clubs),
          PlayingCard(Rank.six, Suit.diamonds),
          PlayingCard(Rank.seven, Suit.diamonds),
          PlayingCard(Rank.eight, Suit.diamonds),
          PlayingCard(Rank.nine, Suit.diamonds),
        ]),
        trump: Suit.clubs,
        attackerIndex: 0,
        turn: DurakTurn.defender,
        table: [
          TablePair(PlayingCard(Rank.nine, Suit.hearts)),
          TablePair(king),
        ],
      );
      game.defend(ten, playerIndex: 1, pairIndex: 0);
      expect(game.table, isEmpty);
      expect(game.bito.length, 2);
      expect(game.hands[0], contains(king));
      expect(game.attackerIndex, 1);
      expect(game.canDefenderTake, isFalse);
    });

    test('defend can beat any undefended pair, not only the first', () {
      final game = DurakGame(
        hands: [
          <PlayingCard>[],
          [
            PlayingCard(Rank.eight, Suit.clubs),
            PlayingCard(Rank.ten, Suit.hearts),
          ],
        ],
        deck: Deck([]),
        trump: Suit.hearts,
        attackerIndex: 0,
        turn: DurakTurn.defender,
        table: [
          TablePair(PlayingCard(Rank.six, Suit.diamonds)),
          TablePair(PlayingCard(Rank.six, Suit.clubs)),
        ],
      );
      final eight = PlayingCard(Rank.eight, Suit.clubs);
      expect(game.canDefendWith(eight, 1), isTrue);
      expect(game.canDefendWith(eight, 1, pairIndex: 0), isFalse);
      expect(game.canDefendWith(eight, 1, pairIndex: 1), isTrue);
      game.defend(eight, playerIndex: 1, pairIndex: 1);
      expect(game.table[1].defense, eight);
      expect(game.table[0].defense, isNull);
    });

    test('take: defender collects all cards and loses turn', () {
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.jack, Suit.hearts)],
          [PlayingCard(Rank.six, Suit.diamonds)],
        ],
        deck: Deck([]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      game.attack(PlayingCard(Rank.jack, Suit.hearts), playerIndex: 0);
      expect(game.canDefenderTake, isTrue);
      game.take();
      // Нечего подкинуть вдогонку → пауза take_reveal, затем забор стола.
      expect(game.turn, DurakTurn.takeReveal);
      game.completeReveal();
      expect(game.hands[1].length, 2);
      // Не осталось карт у атакующего → он победил, защитник — дурак.
      expect(game.loserIndex, 1);
    });

    test('take follow-up: can throw in then confirm', () {
      final game = DurakGame(
        hands: [
          [
            PlayingCard(Rank.nine, Suit.hearts),
            PlayingCard(Rank.nine, Suit.diamonds),
            PlayingCard(Rank.ten, Suit.clubs),
          ],
          [
            PlayingCard(Rank.six, Suit.spades),
            PlayingCard(Rank.seven, Suit.clubs),
          ],
        ],
        deck: Deck([]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      game.attack(PlayingCard(Rank.nine, Suit.hearts), playerIndex: 0);
      // Есть что подкинуть → throwIn; «Все» → ход защитнику.
      expect(game.turn, DurakTurn.throwIn);
      game.confirmThrowAll(playerIndex: 0);
      expect(game.turn, DurakTurn.defender);
      game.take();
      expect(game.turn, DurakTurn.takeFollowUp);
      expect(game.canAttackWith(PlayingCard(Rank.nine, Suit.diamonds), 0), isTrue);
      game.attack(PlayingCard(Rank.nine, Suit.diamonds), playerIndex: 0);
      expect(game.table.length, 2);
      expect(game.turn, DurakTurn.takeFollowUp);
      game.confirmTake(playerIndex: 0);
      expect(game.turn, DurakTurn.takeReveal);
      expect(game.table, isNotEmpty);
      game.completeReveal();
      expect(game.table, isEmpty);
      expect(game.hands[1].length, greaterThanOrEqualTo(4));
      expect(game.turn, DurakTurn.attacker);
    });

    test('perevodnoi: defender can transfer same rank', () {
      final game = DurakGame(
        hands: [
          [PlayingCard(Rank.six, Suit.hearts)],
          [
            PlayingCard(Rank.six, Suit.diamonds),
            PlayingCard(Rank.nine, Suit.clubs),
          ],
          [
            PlayingCard(Rank.ace, Suit.spades),
            PlayingCard(Rank.king, Suit.spades),
          ],
        ],
        deck: Deck([
          for (var i = 0; i < 12; i++)
            PlayingCard(Rank.ten, Suit.clubs),
        ]),
        trump: Suit.clubs,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
        mode: durakModePerevodnoi,
      );
      game.attack(PlayingCard(Rank.six, Suit.hearts), playerIndex: 0);
      expect(game.turn, DurakTurn.defender);
      expect(game.canTransferWith(PlayingCard(Rank.six, Suit.diamonds), 1), isTrue);
      game.transfer(PlayingCard(Rank.six, Suit.diamonds), playerIndex: 1);
      expect(game.attackerIndex, 1);
      expect(game.defenderIndex, 2);
      expect(game.table.length, 2);
      expect(game.turn, DurakTurn.defender);
    });

    test('bot defends with minimum higher card of same suit', () {
      final game = DurakGame(
        hands: [
          [
            PlayingCard(Rank.six, Suit.hearts),
            PlayingCard(Rank.nine, Suit.clubs),
          ],
          [
            PlayingCard(Rank.seven, Suit.hearts),
            PlayingCard(Rank.ace, Suit.hearts),
            PlayingCard(Rank.jack, Suit.spades), // trump
          ],
        ],
        deck: Deck([
          PlayingCard(Rank.eight, Suit.clubs),
          PlayingCard(Rank.nine, Suit.diamonds),
          PlayingCard(Rank.ten, Suit.diamonds),
          PlayingCard(Rank.jack, Suit.diamonds),
          PlayingCard(Rank.queen, Suit.diamonds),
          PlayingCard(Rank.king, Suit.diamonds),
          PlayingCard(Rank.ace, Suit.diamonds),
          PlayingCard(Rank.eight, Suit.spades),
          PlayingCard(Rank.nine, Suit.spades),
          PlayingCard(Rank.ten, Suit.spades),
          PlayingCard(Rank.queen, Suit.spades),
          PlayingCard(Rank.king, Suit.spades),
        ]),
        trump: Suit.spades,
        attackerIndex: 0,
        turn: DurakTurn.attacker,
      );
      game.attack(PlayingCard(Rank.six, Suit.hearts), playerIndex: 0);
      if (game.turn == DurakTurn.throwIn) {
        game.confirmThrowAll(playerIndex: 0);
      }
      const bot = DurakBot(index: 1);
      bot.step(game);
      // Нечего подкинуть → bito_reveal, затем стол в биту.
      if (game.turn == DurakTurn.bitoReveal) {
        game.completeReveal();
      }
      expect(game.table, isEmpty);
      expect(game.bito, contains(PlayingCard(Rank.seven, Suit.hearts)));
      expect(game.bito, contains(PlayingCard(Rank.six, Suit.hearts)));
    });
  });
}
