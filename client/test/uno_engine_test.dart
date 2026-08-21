import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_bot.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_engine.dart';

UnoCard number(String id, UnoColor color, int value) => UnoCard(
      id: id,
      color: color,
      kind: UnoCardKind.number,
      number: value,
    );

UnoCard action(String id, UnoColor color, UnoCardKind kind) => UnoCard(
      id: id,
      color: color,
      kind: kind,
    );

UnoEngine controlled({
  required List<UnoCard> firstHand,
  List<UnoCard>? secondHand,
  int targetScore = 100,
}) {
  return UnoEngine.controlled(
    players: [
      UnoPlayer(userId: 'p0', seat: 0, hand: firstHand),
      UnoPlayer(
        userId: 'p1',
        seat: 1,
        hand: secondHand ?? [number('p1-blue-1', UnoColor.blue, 1)],
      ),
    ],
    drawPile: [
      for (var i = 0; i < 20; i++) number('draw-$i', UnoColor.yellow, i % 10),
    ],
    topDiscard: number('top-red-5', UnoColor.red, 5),
    targetScore: targetScore,
  );
}

void main() {
  test('standard UNO deck has 108 unique cards', () {
    final deck = buildUnoDeck(seed: 42);
    expect(deck, hasLength(108));
    expect(deck.map((card) => card.id).toSet(), hasLength(108));
    expect(
      deck.where((card) => card.kind == UnoCardKind.number),
      hasLength(76),
    );
    expect(
      deck.where((card) => card.kind == UnoCardKind.wildDrawFour),
      hasLength(4),
    );
  });

  test('cards match by color, number, action or wild', () {
    final top = number('top', UnoColor.red, 5);
    expect(number('red-2', UnoColor.red, 2).matches(top, UnoColor.red), isTrue);
    expect(
        number('blue-5', UnoColor.blue, 5).matches(top, UnoColor.red), isTrue);
    expect(
        number('blue-2', UnoColor.blue, 2).matches(top, UnoColor.red), isFalse);
    expect(
      action('wild', UnoColor.wild, UnoCardKind.wild)
          .matches(top, UnoColor.red),
      isTrue,
    );
    final skip = action('skip-red', UnoColor.red, UnoCardKind.skip);
    expect(
      action('skip-blue', UnoColor.blue, UnoCardKind.skip)
          .matches(skip, UnoColor.yellow),
      isTrue,
    );
  });

  test('reverse acts as skip in a two-player game', () {
    final reverse = action('reverse', UnoColor.red, UnoCardKind.reverse);
    final engine = controlled(
      firstHand: [reverse, number('remain', UnoColor.blue, 1)],
    );

    engine.apply(UnoAction(UnoActionType.play, cardId: reverse.id));

    expect(engine.direction, 1);
    expect(engine.currentIndex, 0);
  });

  test('Wild Draw Four can be played illegally and challenged', () {
    final wildDrawFour = action(
      'wild-draw-four',
      UnoColor.wild,
      UnoCardKind.wildDrawFour,
    );
    final engine = controlled(
      firstHand: [
        wildDrawFour,
        number('matching-red', UnoColor.red, 2),
      ],
    );

    expect(engine.canPlay(0, wildDrawFour), isTrue);
    engine.apply(UnoAction(
      UnoActionType.play,
      cardId: wildDrawFour.id,
      color: UnoColor.blue,
    ));

    expect(engine.status, UnoStatus.awaitingWd4Challenge);
    expect(engine.wild4WasLegal, isFalse);
    engine.apply(const UnoAction(UnoActionType.challengeWd4));

    expect(engine.players[0].hand, hasLength(5));
    expect(engine.currentIndex, 1);
    expect(engine.status, UnoStatus.active);
    expect(engine.lastEventType, 'wd4_reveal');
    expect(engine.lastEventCard?.color, UnoColor.red);
  });

  test('round scoring uses card values and ends match at 100', () {
    final winning = number('winning', UnoColor.red, 9);
    final engine = controlled(
      firstHand: [winning],
      secondHand: [
        action('skip', UnoColor.blue, UnoCardKind.skip),
        number('five', UnoColor.yellow, 5),
      ],
      targetScore: 100,
    );
    engine.players[0].score = 75;

    engine.apply(UnoAction(UnoActionType.play, cardId: winning.id));

    expect(engine.players[0].score, 100);
    expect(engine.status, UnoStatus.over);
    expect(engine.winnerUserIds, ['p0']);
    expect(engine.lastRoundPoints, 25);
    expect(engine.lastRoundWinnerUserId, 'p0');
  });

  test('heads-up target is 100 and 3+ players target is 300', () {
    final two = UnoEngine.newGame(playerIds: ['a', 'b'], seed: 1);
    final three = UnoEngine.newGame(playerIds: ['a', 'b', 'c'], seed: 1);
    expect(two.targetScore, 100);
    expect(three.targetScore, 300);
  });

  test('round below target pauses so scores stay visible', () {
    final winning = number('winning', UnoColor.red, 9);
    final engine = controlled(
      firstHand: [winning],
      secondHand: [number('five', UnoColor.yellow, 5)],
    );

    engine.apply(UnoAction(UnoActionType.play, cardId: winning.id));

    expect(engine.status, UnoStatus.betweenRounds);
    expect(engine.players[0].score, 5);
    expect(engine.lastRoundPoints, 5);
    expect(engine.lastRoundWinnerUserId, 'p0');
    expect(engine.roundNumber, 1);

    engine.apply(const UnoAction(UnoActionType.nextRound));

    expect(engine.status, UnoStatus.active);
    expect(engine.roundNumber, 2);
    expect(engine.players[0].score, 5);
    expect(engine.players[0].hand, hasLength(7));
    expect(engine.players[1].hand, hasLength(7));
  });

  test('+2 stacks on +2 and +4 cannot answer +2', () {
    final first = action('plus-two-a', UnoColor.red, UnoCardKind.drawTwo);
    final second = action('plus-two-b', UnoColor.blue, UnoCardKind.drawTwo);
    final wd4 = action('plus-four', UnoColor.wild, UnoCardKind.wildDrawFour);
    final engine = UnoEngine.controlled(
      players: [
        UnoPlayer(userId: 'p0', seat: 0, hand: [first, number('r0', UnoColor.blue, 1)]),
        UnoPlayer(userId: 'p1', seat: 1, hand: [second, number('r1', UnoColor.yellow, 3)]),
        UnoPlayer(
          userId: 'p2',
          seat: 2,
          hand: [wd4, number('r2', UnoColor.green, 8)],
        ),
      ],
      drawPile: [
        for (var i = 0; i < 20; i++) number('draw-$i', UnoColor.yellow, i % 10),
      ],
      topDiscard: number('top-red-5', UnoColor.red, 5),
    );

    engine.apply(UnoAction(UnoActionType.play, cardId: first.id));
    expect(engine.pendingDraw, 2);
    expect(engine.canPlay(1, wd4), isFalse);
    expect(engine.canPlay(1, second), isTrue);

    engine.apply(UnoAction(UnoActionType.play, cardId: second.id));
    expect(engine.pendingDraw, 4);
    expect(engine.currentIndex, 2);
    expect(engine.canPlay(2, wd4), isFalse);

    expect(
      () => engine.apply(UnoAction(
        UnoActionType.play,
        cardId: wd4.id,
        color: UnoColor.green,
      )),
      throwsStateError,
    );

    final before = engine.players[2].hand.length;
    engine.apply(const UnoAction(UnoActionType.draw));
    expect(engine.players[2].hand, hasLength(before + 4));
    expect(engine.pendingDraw, 0);
    expect(engine.lastDrawCount, 4);
  });

  test('+4 stacks only on +4', () {
    final first = action('wd4-a', UnoColor.wild, UnoCardKind.wildDrawFour);
    final second = action('wd4-b', UnoColor.wild, UnoCardKind.wildDrawFour);
    final plusTwo = action('plus-two', UnoColor.red, UnoCardKind.drawTwo);
    final engine = UnoEngine.controlled(
      players: [
        UnoPlayer(
          userId: 'p0',
          seat: 0,
          hand: [first, number('r0', UnoColor.yellow, 1)],
        ),
        UnoPlayer(userId: 'p1', seat: 1, hand: [second, plusTwo]),
      ],
      drawPile: [
        for (var i = 0; i < 20; i++) number('draw-$i', UnoColor.yellow, i % 10),
      ],
      topDiscard: number('top-red-5', UnoColor.red, 5),
    );

    engine.apply(UnoAction(
      UnoActionType.play,
      cardId: first.id,
      color: UnoColor.blue,
    ));
    expect(engine.canPlay(1, plusTwo), isFalse);
    expect(engine.canPlay(1, second), isTrue);

    engine.apply(UnoAction(
      UnoActionType.play,
      cardId: second.id,
      color: UnoColor.green,
    ));
    expect(engine.pendingDraw, 8);
    expect(engine.status, UnoStatus.awaitingWd4Challenge);
  });

  test('bot draws on Wild Draw Four instead of stalling', () {
    final wildDrawFour = action(
      'wild-draw-four',
      UnoColor.wild,
      UnoCardKind.wildDrawFour,
    );
    final engine = controlled(
      firstHand: [wildDrawFour, number('remain', UnoColor.yellow, 2)],
    );
    engine.apply(UnoAction(
      UnoActionType.play,
      cardId: wildDrawFour.id,
      color: UnoColor.blue,
    ));
    expect(engine.status, UnoStatus.awaitingWd4Challenge);
    expect(engine.currentIndex, 1);

    engine.apply(pickUnoBotAction(engine));

    expect(engine.status, UnoStatus.active);
    expect(engine.players[1].hand.length, greaterThanOrEqualTo(5));
    expect(engine.currentIndex, 0);
  });
}
