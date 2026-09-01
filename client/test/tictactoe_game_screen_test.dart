import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';

import 'test_locale.dart';

class _PendingGameState extends GameStateNotifier {
  @override
  Future<GameStateItem> build(String arg) => Completer<GameStateItem>().future;
}

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('opens under ProviderScope without lifecycle errors',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameStateProvider.overrideWith(_PendingGameState.new),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TicTacToeGameScreen(gameId: 'game-1'),
        ),
      ),
    );

    expect(find.byType(TicTacToeGameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
