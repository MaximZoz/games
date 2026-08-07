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
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayingCardWidget under Transform.scale (fan drag) has no overflow',
      (tester) async {
    const card = PlayingCard(Rank.queen, Suit.spades);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Transform.scale(
              scale: 1.09,
              child: const PlayingCardWidget(
                card: card,
                size: Size(92, 132),
                elevated: true,
                highlighted: true,
                animate: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayingCardWidget size change has no overflow', (tester) async {
    const card = PlayingCard(Rank.queen, Suit.spades);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayingCardWidget(
              card: card,
              size: Size(66, 94),
              animate: true,
              elevated: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayingCardWidget(
              card: card,
              size: Size(92, 132),
              animate: true,
              elevated: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
