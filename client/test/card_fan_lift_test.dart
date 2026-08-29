import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fan_lift.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

void main() {
  const tenDiamonds = PlayingCard(Rank.ten, Suit.diamonds);
  const queenClubs = PlayingCard(Rank.queen, Suit.clubs);

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

  test('peek под overlay тоже без лица', () {
    expect(
      fanSlotHidesFace(
        card: tenDiamonds,
        peekCard: tenDiamonds,
        hidePeekUnderOverlay: true,
      ),
      isTrue,
    );
    expect(
      fanSlotHidesFace(
        card: tenDiamonds,
        peekCard: tenDiamonds,
      ),
      isFalse,
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
  });
}
