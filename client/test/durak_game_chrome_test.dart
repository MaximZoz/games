import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/framework/game_chrome.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/durak_game_screen.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_locale.dart';

void main() {
  testWidgets('дурак стоит на общем каркасе: правила, флаг под ними',
      (tester) async {
    setUpTestLocaleRu();
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = OfflineDurakSession.create(humanUserId: 'local:player');
    addTearDown(OfflineDurakRegistry.instance.disposeAll);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DurakGameScreen(gameId: session.gameId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameScreenScaffold), findsOneWidget);
    final rules = find.byKey(const ValueKey('game-chrome-rules'));
    expect(rules, findsOneWidget);

    // Флаг «сдаться» — в общем столбике, ровно под кнопкой правил.
    final rail = find.byKey(const ValueKey('game-chrome-rail'));
    expect(rail, findsOneWidget);
    expect(find.byType(GameActionsOverlay), findsOneWidget);
    final rulesRect = tester.getRect(rules);
    final railRect = tester.getRect(rail);
    expect(railRect.top, greaterThanOrEqualTo(rulesRect.bottom - 4));
    expect((railRect.center.dx - rulesRect.center.dx).abs(), lessThan(6));

    // Офлайн без лимита времени: таймера в шапке нет, о ходе сообщает звук.
    expect(find.byType(GameTurnCountdown, skipOffstage: false), findsNothing);
    expect(find.byType(MyTurnAlert), findsOneWidget);

    // Дать раздаче долететь: её анимация не рассчитана на снятие экрана.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);

    // Над колодой нет пустого места от прежнего таймера: она стоит у
    // верхнего края стола.
    final deck = find.byType(DurakDeckPile);
    expect(deck, findsOneWidget);
    final board = find.ancestor(of: deck, matching: find.byType(Stack)).first;
    expect(
      tester.getRect(deck).top - tester.getRect(board).top,
      lessThanOrEqualTo(8),
    );
    // Бита (пока пустая — только якорь полёта) стоит на одной линии с колодой.
    expect(
      tester.getRect(find.byType(DurakBitoPile)).top,
      tester.getRect(deck).top,
    );

    OfflineDurakRegistry.instance.disposeAll();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
