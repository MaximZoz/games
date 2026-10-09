import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('режимы шахмат — контроль времени, старые варианты в классику', () {
    final t = l10n();
    expect(chessNormalizeMode(null), chessModeClassic);
    expect(chessNormalizeMode('chess960'), chessModeClassic);
    expect(chessNormalizeMode('antichess'), chessModeClassic);
    expect(chessNormalizeMode('unknown'), chessModeClassic);
    expect(chessNextMode(chessModeClassic), chessModeRapid);
    expect(chessNextMode(chessModeRapid), chessModeBlitz);
    expect(chessNextMode(chessModeBlitz), chessModeBullet);
    expect(chessNextMode(chessModeBullet), chessModeClassic);
    expect(chessModeLabel(chessModeClassic, t), t.gamesChessModeClassic);
    expect(chessModeLabel(chessModeRapid, t), t.gamesChessModeRapid);
    expect(chessModeLabel(chessModeBlitz, t), t.gamesChessModeBlitz);
    expect(chessModeLabel(chessModeBullet, t), t.gamesChessModeBullet);
    expect(chessClockNotation(chessModeClassic), '60+0');
    expect(chessClockNotation(chessModeRapid), '10+0');
    expect(chessClockNotation(chessModeBlitz), '5+0');
    expect(chessClockNotation(chessModeBullet), '3+2');
    expect(t.gamesChess, 'Шахматы');
    expect(t.gamesChessModeRapid, 'Рапид');
    expect(t.gamesChessModeBlitz, 'Блиц');
    expect(t.gamesChessModeBullet, 'Пуля');
  });

  test('офлайн с ботом использует тот же контроль, что и онлайн', () {
    final t = l10n();
    final lines = chessRuleLines(
      gameMode: chessModeBullet,
      turnTimeSec: 0,
      stakeBronze: 0,
      offline: true,
      l10n: t,
    );
    expect(lines, contains(chessClockLine(chessModeBullet, t)));
    expect(lines, isNot(contains(t.rulesNoTimeLimit)));
    expect(chessClockBudgetMs(chessModeClassic), (60 * 60 * 1000, 0));
    expect(chessClockBudgetMs(chessModeRapid), (10 * 60 * 1000, 0));
    expect(chessClockBudgetMs(chessModeBlitz), (5 * 60 * 1000, 0));
    expect(chessClockBudgetMs(chessModeBullet), (3 * 60 * 1000, 2000));
  });

  test('лимит хода: 20 с, 1 мин, без лимита', () {
    expect(chessTurnTimeOptions, [20, 60, 0]);
    expect(chessNormalizeTurnTime(20), 20);
    expect(chessNormalizeTurnTime(60), 60);
    expect(chessNormalizeTurnTime(0), 0);
    expect(chessNormalizeTurnTime(600), 60);
    expect(chessNormalizeTurnTime(null), 60);
    expect(chessNextTurnTime(20), 60);
    expect(chessNextTurnTime(60), 0);
    expect(chessNextTurnTime(0), 20);
    expect(chessNextTurnTime(600), 0);
  });

  test('правила каждого режима показывают свой контроль и общие ходы', () {
    final t = l10n();
    for (final mode in chessAllModes) {
      final lines = chessRuleLines(
        gameMode: mode,
        turnTimeSec: 60,
        stakeBronze: 0,
        l10n: t,
      );
      expect(lines, contains(t.rulesChessPlayers));
      expect(lines, contains(t.rulesChessMode(chessModeLabel(mode, t))));
      expect(lines, contains(chessClockLine(mode, t)));
      expect(lines, contains(chessPlayLine(mode, t)));
      expect(lines, contains(chessDrawLine(mode, t)));
      expect(lines, contains(t.rulesTurnTime('1 мин')));
      expect(lines.join('\n'), contains(chessClockNotation(mode)));
      for (final other in chessAllModes.where((m) => m != mode)) {
        expect(lines, isNot(contains(chessClockLine(other, t))),
            reason: '$mode не должен содержать контроль $other');
      }
      expect(lines.join('\n'), isNot(contains('Шахматы-960')));
      expect(lines.join('\n'), isNot(contains('Антишахматы')));
    }
  });

  testWidgets('диалог правил блица показывает 5+0 и без 960', (tester) async {
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
                    chessRuleLines(
                      gameMode: chessModeBlitz,
                      turnTimeSec: 20,
                      stakeBronze: 0,
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
    expect(find.textContaining('Режим: Блиц.'), findsOneWidget);
    expect(find.textContaining('5+0'), findsOneWidget);
    expect(find.textContaining('20 с'), findsOneWidget);
    expect(find.textContaining('Шахматы-960:'), findsNothing);
    expect(find.textContaining('Антишахматы:'), findsNothing);
  });

  testWidgets('диалог пули показывает 3+2 и без лимита хода', (tester) async {
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
                    chessRuleLines(
                      gameMode: chessModeBullet,
                      turnTimeSec: 0,
                      stakeBronze: 0,
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

    expect(find.textContaining('Режим: Пуля.'), findsOneWidget);
    expect(find.textContaining('3+2'), findsOneWidget);
    expect(find.textContaining('Без ограничения по времени на ход.'),
        findsOneWidget);
  });

  testWidgets('карточка шахмат показывает плашку «В разработке»',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: GameCardActionsRow(
            createLabel: 'Создать игру',
            creatingLabel: 'Создание…',
            onCreate: null,
            findLabel: 'Поиск игроков',
            findingLabel: 'Поиск…',
            onFind: null,
            inDevelopment: true,
          ),
        ),
      ),
    );
    expect(find.text('В разработке'), findsOneWidget);
    expect(find.text('Создать игру'), findsNothing);
    expect(find.text('Поиск игроков'), findsNothing);
  });
}
