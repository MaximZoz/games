import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('unoRuleLines includes players and win line without turn time', () {
    final lines = unoRuleLines(players: 3, turnTimeSec: 60);
    expect(lines.first, 'Без ставки.');
    expect(lines[1], 'Игроки: 3.');
    expect(lines.any((l) => l.contains('1 мин')), isFalse);
    expect(lines.any((l) => l.contains('Время на ход')), isFalse);
    expect(lines.any((l) => l.contains('Уно')), isTrue);
    expect(lines.any((l) => l.contains('7 карт')), isTrue);
    expect(lines.any((l) => l.contains('+4')), isTrue);
    expect(lines.any((l) => l.contains('200')), isTrue);
    expect(lines.last, contains('200'));
  });

  test('кнопка взять выключена пока запрос в полёте', () {
    expect(unoDrawControlEnabled(busy: false, canTake: true), isTrue);
    expect(unoDrawControlEnabled(busy: true, canTake: true), isFalse);
    expect(unoDrawControlEnabled(busy: false, canTake: false), isFalse);
  });

  test('второй взять не показывает «не ваш ход»', () {
    expect(
      isStaleUnoDrawError(
          GamesException(400, 'Сейчас не ваш ход', errorKey: 'not your turn')),
      isTrue,
    );
    expect(isStaleUnoDrawError(GamesException(400, 'lobby full')), isFalse);
  });

  test('unoRuleLines offline bot: без лимита, заметка про бота в правилах', () {
    final lines = unoRuleLines(
      players: 2,
      turnTimeSec: 60,
      offlineBot: true,
    );
    expect(lines[1], 'Игроки: 2.');
    expect(
      lines.any((line) => line.contains('Без ограничения по времени')),
      isFalse,
    );
    expect(lines.last, 'Офлайн: партия против бота.');
    expect(lines.any((l) => l.contains('1 мин')), isFalse);
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
    expect(find.textContaining('одинаковые цифровые'), findsOneWidget);
    expect(find.textContaining('парой не кидаются'), findsOneWidget);
    expect(find.textContaining('оспорить'), findsNothing);
    expect(find.textContaining('кладёт свою +4'), findsOneWidget);
    expect(find.textContaining('даже если есть подходящая'), findsOneWidget);
    expect(find.textContaining('одну карту из колоды'), findsOneWidget);
    expect(find.textContaining('до 100'), findsOneWidget);
    expect(find.textContaining('до 200'), findsOneWidget);
    expect(find.textContaining('Не забудьте сказать'), findsNothing);
  });
}
