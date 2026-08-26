import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/poker_game_screen.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  tearDown(() {
    // Сессии из теста не должны течь в следующие.
  });

  testWidgets('офлайн-покер рисует стол, не пустой фон', (tester) async {
    final session = OfflinePokerSession.create(
      humanUserId: 'user-1',
      humanDisplayName: 'player1',
    );
    addTearDown(() {
      OfflinePokerRegistry.instance.get(session.gameId)?.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PokerGameScreen(gameId: session.gameId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Покер'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      findsWidgets,
    );
  });
}
