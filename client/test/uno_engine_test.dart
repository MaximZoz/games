import 'package:flutter_test/flutter_test.dart';
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
  });
}
