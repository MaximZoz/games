import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('режимы шашек нормализуются и подписываются правильно', () {
    final t = l10n();
    expect(checkersNormalizeMode(null), checkersModeRussian);
    expect(checkersNormalizeMode('english'), checkersModeEnglish);
    expect(checkersNormalizeMode('giveaway'), checkersModeGiveaway);
    expect(checkersNormalizeMode('corners'), checkersModeCorners);
    expect(checkersNormalizeMode('poddavki'), checkersModeRussian);
    expect(checkersModeLabel(checkersModeRussian, t), t.gamesCheckersModeRussian);
    expect(checkersModeLabel(checkersModeEnglish, t), t.gamesCheckersModeEnglish);
    expect(
        checkersModeLabel(checkersModeGiveaway, t), t.gamesCheckersModeGiveaway);
    expect(checkersModeLabel(checkersModeCorners, t), t.gamesCheckersModeCorners);
    expect(t.gamesCheckersModeGiveaway, 'Поддавки');
    expect(t.gamesCheckersModeEnglish, 'Английские');
  });

  test('цикл режимов идёт русские → английские → поддавки → уголки', () {
    expect(checkersNextMode(checkersModeRussian), checkersModeEnglish);
    expect(checkersNextMode(checkersModeEnglish), checkersModeGiveaway);
    expect(checkersNextMode(checkersModeGiveaway), checkersModeCorners);
    expect(checkersNextMode(checkersModeCorners), checkersModeRussian);
  });

  test('правила содержат игроков, режим, время и ставку', () {
    final t = l10n();
    final russian = checkersRuleLines(
      gameMode: checkersModeRussian,
      turnTimeSec: 60,
      stakeBronze: 10,
      l10n: t,
    );
    expect(russian, contains(t.rulesCheckersPlayers));
    expect(russian, contains(t.rulesCheckersMode(t.gamesCheckersModeRussian)));
    expect(russian, contains(t.rulesCheckersPlayRussian));
    expect(russian, isNot(contains(t.rulesCheckersPlayEnglish)));

    final giveaway = checkersRuleLines(
      gameMode: checkersModeGiveaway,
      turnTimeSec: 0,
      stakeBronze: 0,
      l10n: t,
    );
    expect(giveaway, contains(t.rulesCheckersPlayGiveaway));
    expect(giveaway, contains(t.rulesNoTimeLimit));

    final corners = checkersRuleLines(
      gameMode: checkersModeCorners,
      turnTimeSec: 20,
      stakeBronze: 2,
      l10n: t,
    );
    expect(corners, contains(t.rulesCheckersPlayCorners));
  });

  testWidgets('диалог правил шашек использует общий заголовок', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showGameRulesDialog(
                  context: context,
                  content: rulesTextLines(
                    checkersRuleLines(
                      gameMode: checkersModeEnglish,
                      turnTimeSec: 600,
                      stakeBronze: 2,
                      l10n: context.l10n,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Правила игры'), findsOneWidget);
    expect(find.textContaining('Игроки: 2.'), findsOneWidget);
    expect(find.textContaining('Английские шашки'), findsOneWidget);
  });
}
