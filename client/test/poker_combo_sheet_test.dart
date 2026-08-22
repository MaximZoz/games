import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/poker/poker_combo_sheet.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('pokerHandRankLabel maps server ranks', () {
    final l10n = lookupAppLocalizations(const Locale('ru'));
    expect(pokerHandRankLabel(l10n, 'OnePair'), 'Пара');
    expect(pokerHandRankLabel(l10n, 'RoyalFlush'), 'Роял-флеш');
    expect(pokerHandRankLabel(l10n, null), isNull);
  });

  testWidgets('sheet lists all ranks and highlights mine', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: PokerCombinationsSheet(currentRank: 'Flush'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Комбинации'), findsOneWidget);
    expect(find.text('Флеш'), findsOneWidget);
    expect(find.text('Роял-флеш'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Пара'), 120);
    expect(find.text('Пара'), findsOneWidget);
  });
}
