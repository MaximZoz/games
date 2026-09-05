import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('режимы шашек нормализуются и подписываются правильно', () {
    final t = l10n();
    expect(CheckersEngine.normalizeMode(null), CheckersEngine.modeRussian);
    expect(CheckersEngine.normalizeMode('english'), CheckersEngine.modeEnglish);
    expect(
        CheckersEngine.normalizeMode('giveaway'), CheckersEngine.modeGiveaway);
    expect(CheckersEngine.normalizeMode('corners'), CheckersEngine.modeCorners);
    expect(CheckersEngine.nextMode(CheckersEngine.modeRussian),
        CheckersEngine.modeEnglish);
    expect(CheckersEngine.nextMode(CheckersEngine.modeEnglish),
        CheckersEngine.modeGiveaway);
    expect(CheckersEngine.nextMode(CheckersEngine.modeGiveaway),
        CheckersEngine.modeCorners);
    expect(CheckersEngine.nextMode(CheckersEngine.modeCorners),
        CheckersEngine.modeRussian);
    expect(
        checkersModeLabel(CheckersEngine.modeRussian, t),
        t.gamesCheckersModeRussian);
    expect(
        checkersModeLabel(CheckersEngine.modeEnglish, t),
        t.gamesCheckersModeEnglish);
    expect(
        checkersModeLabel(CheckersEngine.modeGiveaway, t),
        t.gamesCheckersModeGiveaway);
    expect(
        checkersModeLabel(CheckersEngine.modeCorners, t),
        t.gamesCheckersModeCorners);
    expect(t.gamesCheckersModeGiveaway, 'Поддавки');
    expect(t.gamesCheckersModeCorners, 'Уголки');
  });

  test('правила содержат игроков, режим, время и ставку', () {
    final t = l10n();
    final russian = checkersRuleLines(
      gameMode: CheckersEngine.modeRussian,
      turnTimeSec: 60,
      stakeBronze: 10,
      l10n: t,
    );
    expect(russian, contains(t.rulesCheckersPlayers));
    expect(russian, contains(t.rulesCheckersMode(t.gamesCheckersModeRussian)));
    expect(russian, contains(t.rulesCheckersPlay));
    expect(t.rulesCheckersPlay, contains('продолжать бой'));
    expect(t.rulesCheckersPlay, contains('любое'));
    expect(t.rulesCheckersPlayRussian, contains('не обязательно самое длинное'));
    expect(russian, contains(t.rulesCheckersWin));

    final giveaway = checkersRuleLines(
      gameMode: CheckersEngine.modeGiveaway,
      turnTimeSec: 0,
      stakeBronze: 0,
      l10n: t,
    );
    expect(giveaway, contains(t.rulesCheckersMode(t.gamesCheckersModeGiveaway)));
    expect(giveaway, contains(t.rulesCheckersPlayGiveaway));
    expect(giveaway, contains(t.rulesCheckersWin));

    final english = checkersRuleLines(
      gameMode: CheckersEngine.modeEnglish,
      turnTimeSec: 60,
      stakeBronze: 0,
      l10n: t,
    );
    expect(english, contains(t.rulesCheckersPlayEnglish));

    final corners = checkersRuleLines(
      gameMode: CheckersEngine.modeCorners,
      turnTimeSec: 60,
      stakeBronze: 0,
      l10n: t,
    );
    expect(corners, contains(t.rulesCheckersPlayCorners));
    expect(corners, contains(t.rulesCheckersMode(t.gamesCheckersModeCorners)));

    final offline = checkersRuleLines(
      gameMode: CheckersEngine.modeRussian,
      turnTimeSec: 20,
      stakeBronze: 2,
      l10n: t,
      offline: true,
    );
    expect(offline, contains(t.rulesCheckersOfflineBot));
    expect(
      offline.any((line) => line.contains(t.rulesCheckersTime(''))),
      isFalse,
    );
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
                      gameMode: CheckersEngine.modeRussian,
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
    expect(find.textContaining('Русские'), findsOneWidget);
  });
}
