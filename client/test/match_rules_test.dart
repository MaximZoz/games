import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/match_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('шахматы показывают пулю, а не крестики-нолики', (tester) async {
    await tester.pumpWidget(_rulesApp(chess: true));
    await tester.pump();

    expect(find.textContaining('Пуля'), findsOneWidget);
    expect(find.textContaining('3+2'), findsOneWidget);
    expect(find.textContaining('ферзь'), findsOneWidget);
    expect(find.textContaining('Крестики-нолики'), findsNothing);
  });

  testWidgets('крестики-нолики не подменяются шахматами', (tester) async {
    await tester.pumpWidget(_rulesApp(chess: false));
    await tester.pump();

    expect(find.textContaining('Крестики-нолики'), findsOneWidget);
    expect(find.textContaining('ферзь'), findsNothing);
    expect(find.textContaining('Пуля'), findsNothing);
  });
}

Widget _rulesApp({required bool chess}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 380,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.gamesRulesTitle),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: buildMatchRulesBody(
                        l10n: l10n,
                        isDurak: false,
                        isBattleship: false,
                        isPoker: false,
                        isUno: false,
                        isDomino: false,
                        isNardy: false,
                        isCheckers: false,
                        isChess: chess,
                        gameMode: chess ? chessModeBullet : 'podkidnoi',
                        variant: 'classic',
                        maxPlayers: 2,
                        deckSize: 36,
                        turnTimeSec: 0,
                        stakeBronze: 2,
                        gridSize: 3,
                        swapRule: false,
                        firstMoveRestriction: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
