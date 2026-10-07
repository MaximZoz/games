import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('режимы шахмат нормализуются и подписываются', () {
    final t = l10n();
    expect(chessNormalizeMode(null), chessModeClassic);
    expect(chessNormalizeMode('chess960'), chessMode960);
    expect(chessNormalizeMode('antichess'), chessModeAntichess);
    expect(chessNextMode(chessModeClassic), chessMode960);
    expect(chessNextMode(chessMode960), chessModeAntichess);
    expect(chessNextMode(chessModeAntichess), chessModeClassic);
    expect(chessModeLabel(chessModeClassic, t), t.gamesChessModeClassic);
    expect(chessModeLabel(chessMode960, t), t.gamesChessMode960);
    expect(chessModeLabel(chessModeAntichess, t), t.gamesChessModeAntichess);
    expect(t.gamesChess, 'Шахматы');
    expect(t.gamesChessMode960, 'Шахматы-960');
    expect(t.gamesChessModeAntichess, 'Антишахматы');
  });

  test('правила каждого режима не смешивают чужие ходы и ничью', () {
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
      expect(lines, contains(chessPlayLine(mode, t)));
      expect(lines, contains(chessDrawLine(mode, t)));
      for (final other in chessAllModes.where((m) => m != mode)) {
        expect(lines, isNot(contains(chessPlayLine(other, t))),
            reason: '$mode не должен содержать игру $other');
        expect(lines, isNot(contains(chessDrawLine(other, t))),
            reason: '$mode не должен содержать ничью $other');
      }
    }
  });

  testWidgets('диалог правил классики без 960 и антишахмат', (tester) async {
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
                      gameMode: chessModeClassic,
                      turnTimeSec: 60,
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
    expect(find.textContaining('Режим: Классика.'), findsOneWidget);
    expect(find.textContaining('Шахматы-960:'), findsNothing);
    expect(find.textContaining('Антишахматы:'), findsNothing);
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
