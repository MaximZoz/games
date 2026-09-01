import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

void main() {
  testWidgets('пустая бита всё равно показывает рубашку', (tester) async {
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

    expect(find.byType(CardBackWidget), findsOneWidget);
    final back = tester.widget<CardBackWidget>(find.byType(CardBackWidget));
    expect(back.size.width, closeTo(50 * 0.92, 0.01));
    expect(back.size.height, closeTo(72 * 0.92, 0.01));
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
