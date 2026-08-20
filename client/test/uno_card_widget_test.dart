import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';

void main() {
  testWidgets('UNO number, action, wild and back cards paint', (tester) async {
    const cards = [
      UnoCard(
        id: 'red-7',
        color: UnoColor.red,
        kind: UnoCardKind.number,
        number: 7,
      ),
      UnoCard(
        id: 'green-reverse',
        color: UnoColor.green,
        kind: UnoCardKind.reverse,
      ),
      UnoCard(
        id: 'wild-four',
        color: UnoColor.wild,
        kind: UnoCardKind.wildDrawFour,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: Row(
            children: [
              UnoCardBackWidget(size: Size(60, 90)),
            ],
          ),
        ),
        builder: (context, child) => Column(
          children: [
            Row(
              children: [
                for (final card in cards)
                  UnoCardWidget(card: card, size: const Size(60, 90)),
              ],
            ),
            Expanded(child: child!),
          ],
        ),
      ),
    );

    expect(find.byType(UnoCardWidget), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
