import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

void main() {
  testWidgets('пустая бита не рисует карту', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DurakBitoPile(
              count: 0,
              cardSize: Size(50, 72),
              peek: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CardBackWidget), findsNothing);
    expect(tester.getSize(find.byType(DurakBitoPile)), Size.zero);
  });

  testWidgets('в альбоме колода показывает козырь лицом', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DurakDeckPile(
              deckCount: 12,
              trumpCard: PlayingCard(Rank.six, Suit.diamonds),
              cardSize: Size(50, 72),
              peekOffEdge: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PlayingCardWidget), findsOneWidget);
    expect(find.byType(CardBackWidget), findsWidgets);
  });

  testWidgets('бита с картами рисует рубашки', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DurakBitoPile(
              count: 4,
              cardSize: Size(50, 72),
              peek: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CardBackWidget), findsWidgets);
  });
}
