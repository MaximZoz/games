import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fan_lift.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

void main() {
  const tenDiamonds = PlayingCard(Rank.ten, Suit.diamonds);
  const queenClubs = PlayingCard(Rank.queen, Suit.clubs);

  test('parentHidden прячет лицо до посадки добора', () {
    expect(
      fanSlotHidesFace(
        card: tenDiamonds,
        parentHidden: {tenDiamonds},
      ),
      isTrue,
    );
    expect(
      fanSlotHidesFace(
        card: queenClubs,
        parentHidden: {tenDiamonds},
      ),
      isFalse,
    );
  });

  test('вытянутая карта скрыта в слоте, не удалена из веера', () {
    expect(
      fanSlotHidesFace(card: tenDiamonds, liftedCard: tenDiamonds),
      isTrue,
    );
    expect(
      fanSlotHidesFace(card: queenClubs, liftedCard: tenDiamonds),
      isFalse,
    );
  });

  test('peek тоже без лица в слоте — лицо рисует отдельный слой', () {
    expect(
      fanSlotHidesFace(
        card: tenDiamonds,
        peekCard: tenDiamonds,
      ),
      isTrue,
    );
    expect(
      fanSlotHidesFace(
        card: queenClubs,
        peekCard: tenDiamonds,
      ),
      isFalse,
    );
  });

  test('ключ слота меняется при hide — сброс слоя Impeller', () {
    final visible = fanSlotPaintKey(card: tenDiamonds, hidden: false);
    final hidden = fanSlotPaintKey(card: tenDiamonds, hidden: true);
    expect(visible, isNot(hidden));
    expect(fanSlotPaintKey(card: tenDiamonds, hidden: false), visible);
    expect(
      fanPeekOverlayKey(tenDiamonds),
      isNot(fanSlotPaintKey(card: tenDiamonds, hidden: true)),
    );
    expect(fanSlotMoveDuration(instant: true), Duration.zero);
    expect(
      fanSlotMoveDuration(instant: false),
      const Duration(milliseconds: 340),
    );
  });

  testWidgets('после lift в веере одно лицо — без двойника', (tester) async {
    final key = GlobalKey<CardFanState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardFan(
            key: key,
            cards: const [tenDiamonds, queenClubs],
            cardSize: const Size(72, 100),
            animateLayout: false,
          ),
        ),
      ),
    );
    expect(find.byType(PlayingCardWidget), findsNWidgets(2));

    key.currentState!.debugLiftCard(tenDiamonds);
    await tester.pump();

    expect(find.byType(PlayingCardWidget), findsOneWidget);
    final visible = tester.widget<PlayingCardWidget>(
      find.byType(PlayingCardWidget),
    );
    expect(visible.card, queenClubs);
    expect(find.byKey(fanSlotPaintKey(card: tenDiamonds, hidden: true)), findsOneWidget);
    expect(find.byKey(fanSlotPaintKey(card: tenDiamonds, hidden: false)), findsNothing);
  });

  testWidgets('подъём не вставляет overlay до кадра с дыркой', (tester) async {
    final key = GlobalKey<CardFanState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CardFan(
              key: key,
              cards: const [tenDiamonds, queenClubs],
              cardSize: const Size(72, 100),
              animateLayout: false,
            ),
          ),
        ),
      ),
    );
    key.currentState!.debugPromotePeekToFree(tenDiamonds);
    expect(key.currentState!.debugDeferLiftOverlay, isTrue);
    expect(find.byType(PlayingCardWidget), findsNWidgets(2));

    await tester.pump();
    expect(find.byType(PlayingCardWidget), findsOneWidget);
    expect(
      tester.widget<PlayingCardWidget>(find.byType(PlayingCardWidget)).card,
      queenClubs,
    );
    expect(find.byKey(fanSlotPaintKey(card: tenDiamonds, hidden: true)), findsOneWidget);
  });

  testWidgets('peek не меняет тип слота и не двоит лицо', (tester) async {
    final key = GlobalKey<CardFanState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardFan(
            key: key,
            cards: const [tenDiamonds, queenClubs],
            cardSize: const Size(72, 100),
            animateLayout: true,
          ),
        ),
      ),
    );
    expect(find.byType(PlayingCardWidget), findsNWidgets(2));
    expect(find.byType(AnimatedPositioned), findsNWidgets(2));

    key.currentState!.debugPeekCard(tenDiamonds);
    await tester.pump();

    expect(find.byType(PlayingCardWidget), findsNWidgets(2));
    expect(find.byType(AnimatedPositioned), findsNWidgets(2));
    expect(find.byKey(fanSlotPaintKey(card: tenDiamonds, hidden: true)), findsOneWidget);
    expect(find.byKey(fanSlotPaintKey(card: tenDiamonds, hidden: false)), findsNothing);
    final peeked = tester.widgetList<PlayingCardWidget>(
      find.byType(PlayingCardWidget),
    );
    expect(peeked.where((w) => w.card == tenDiamonds), hasLength(1));
    expect(peeked.where((w) => w.card == queenClubs), hasLength(1));
    expect(find.byKey(fanPeekOverlayKey(tenDiamonds)), findsOneWidget);
  });
}
