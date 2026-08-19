import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_rules.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('rulesStakeLine embeds amount and bronze token', () {
    final line = rulesStakeLine(2);
    expect(line, contains('Ставка:'));
    expect(line, contains(rulesStakeAmountToken(2)));
    expect(line, isNot(contains('бр')));
  });

  test('durak / poker / battleship stake lines use the shared token', () {
    expect(
      durakRuleLines(
        mode: 'podkidnoi',
        players: 2,
        deckSize: 24,
        turnTimeSec: 60,
        stakeBronze: 2,
      ).any((l) => l.contains(kRulesStakeIconMarker)),
      isTrue,
    );
    expect(
      pokerRuleLines(
        players: 2,
        turnTimeSec: 60,
        stakeBronze: 100,
      ).any((l) => l.contains(rulesStakeAmountToken(100))),
      isTrue,
    );
    expect(
      battleshipRuleLines(
        turnTimeSec: 60,
        stakeBronze: 2,
      ).any((l) => l.contains(kRulesStakeIconMarker)),
      isTrue,
    );
  });

  testWidgets('rulesTextLines paints CoinIcon for stake line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: rulesTextLines([rulesStakeLine(2)]),
        ),
      ),
    );
    expect(find.byType(CoinIcon), findsOneWidget);
    expect(find.textContaining('Ставка:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
