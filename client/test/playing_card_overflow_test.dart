
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

void main() {
  testWidgets('PlayingCardWidget has no overflow at table/hand sizes', (tester) async {
    final cards = [
      for (final s in Suit.values)
        for (final r in [Rank.six, Rank.ten, Rank.jack, Rank.queen, Rank.king, Rank.ace])
          PlayingCard(r, s),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final c in cards) ...[
                PlayingCardWidget(card: c, size: const Size(66, 94), animate: false),
                PlayingCardWidget(card: c, size: const Size(92, 132), animate: false),
                PlayingCardWidget(card: c, size: const Size(40, 58), animate: false),
              ],
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final exceptions = tester.takeException();
    expect(exceptions, isNull);
  });
}
