import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('unoRuleLines includes players, turn time and win line', () {
    final lines = unoRuleLines(players: 3, turnTimeSec: 60);
    expect(lines.first, 'Игроки: 3.');
    expect(lines.any((l) => l.contains('1 мин')), isTrue);
    expect(lines.any((l) => l.contains('Уно')), isTrue);
    expect(lines.any((l) => l.contains('7 карт')), isTrue);
    expect(lines.any((l) => l.contains('+4')), isTrue);
    expect(lines.any((l) => l.contains('200')), isTrue);
    expect(lines.last, contains('200'));
  });

  test('unoRuleLines offline bot hides turn time', () {
    final lines = unoRuleLines(
      players: 2,
      turnTimeSec: 60,
      offlineBot: true,
    );
    expect(lines.first, 'Игроки: 2.');
    expect(lines, contains('Игра против бота, без лимита времени на ход.'));
    expect(lines, isNot(contains('1 мин')));
  });

  testWidgets('диалог правил Уно показывает актуальные строки движка', (
    tester,
  ) async {
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
                  title: context.l10n.gamesRulesTitle,
                  content: rulesTextLines(
                    unoRuleLines(
                      players: 2,
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
    expect(find.textContaining('7 карт'), findsWidgets);
    expect(find.textContaining('штраф суммируется'), findsOneWidget);
    expect(find.textContaining('+2 на +4 класть нельзя'), findsOneWidget);
    expect(find.textContaining('одинаковые недикие'), findsOneWidget);
    expect(find.textContaining('оспорить'), findsOneWidget);
    expect(find.textContaining('одну из колоды'), findsOneWidget);
    expect(find.textContaining('до 100'), findsOneWidget);
    expect(find.textContaining('до 200'), findsOneWidget);
    expect(find.textContaining('Не забудьте сказать'), findsNothing);
  });
}
