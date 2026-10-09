import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

// Повторяет структуру экрана: доска в Expanded, панель перемотки под ней.
// Проверяем, что панель остаётся в пределах вьюпорта (не уезжает за экран).
Widget _screen({required bool landscape}) {
  final bar = GameReviewBar(
    onFlip: () {},
    onFirst: () {},
    onPrev: () {},
    onNext: () {},
    onLast: () {},
  );
  final boardColumn = Column(
    children: [
      Expanded(child: Container(color: const Color(0xFF223344))),
      const SizedBox(height: 6),
      bar,
    ],
  );
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
          child: landscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: boardColumn),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: Container(color: const Color(0xFF112233)),
                    ),
                  ],
                )
              : boardColumn,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('панель перемотки видна под доской (портрет)', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen(landscape: false));
    final barRect = tester.getRect(find.byType(GameReviewBar));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(barRect.bottom, lessThanOrEqualTo(screen.bottom + 0.5));
    expect(barRect.top, greaterThanOrEqualTo(screen.top - 0.5));
    expect(find.byIcon(Icons.cached_rounded), findsOneWidget);
    expect(find.byIcon(Icons.first_page_rounded), findsOneWidget);
  });

  testWidgets('панель перемотки видна под доской (ландшафт)', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen(landscape: true));
    final barRect = tester.getRect(find.byType(GameReviewBar));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(barRect.bottom, lessThanOrEqualTo(screen.bottom + 0.5));
    // Панель — под доской, в левой (игровой) части, а не в боковой панели.
    expect(barRect.center.dx, lessThan(screen.width * 0.75));
    expect(find.byIcon(Icons.last_page_rounded), findsOneWidget);
  });
}
