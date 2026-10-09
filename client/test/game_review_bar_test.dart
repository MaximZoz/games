import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('кнопка переворота вызывает onFlip', (tester) async {
    var flips = 0;
    await tester.pumpWidget(_wrap(GameReviewBar(
      onFlip: () => flips++,
      flipTooltip: 'flip',
      showNavigation: false,
    )));
    await tester.tap(find.byIcon(Icons.cached_rounded));
    expect(flips, 1);
  });

  testWidgets('стрелки «вперёд» неактивны, пока не идёт просмотр',
      (tester) async {
    var next = 0;
    await tester.pumpWidget(_wrap(GameReviewBar(
      onFlip: () {},
      onFirst: () {},
      onPrev: () {},
      onNext: null,
      onLast: null,
      reviewing: false,
    )));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.tap(find.byIcon(Icons.last_page_rounded));
    expect(next, 0);

    final nextBtn = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(nextBtn.onPressed, isNull);
  });

  testWidgets('навигация назад/вперёд вызывает колбэки', (tester) async {
    var first = 0, prev = 0, next = 0, last = 0;
    await tester.pumpWidget(_wrap(GameReviewBar(
      onFlip: () {},
      onFirst: () => first++,
      onPrev: () => prev++,
      onNext: () => next++,
      onLast: () => last++,
      reviewing: true,
    )));
    await tester.tap(find.byIcon(Icons.first_page_rounded));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.tap(find.byIcon(Icons.last_page_rounded));
    expect([first, prev, next, last], [1, 1, 1, 1]);
  });

  testWidgets('перемотка не красит кнопку вида, переворот — только её',
      (tester) async {
    await tester.pumpWidget(_wrap(GameReviewBar(
      onFlip: () {},
      onFirst: () {},
      onPrev: () {},
      onNext: () {},
      onLast: () {},
      reviewing: true,
      flipped: false,
    )));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cached_rounded)).color,
      AppColors.textPrimary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_left_rounded)).color,
      AppColors.accentStart,
    );

    await tester.pumpWidget(_wrap(GameReviewBar(
      onFlip: () {},
      onFirst: () {},
      onPrev: () {},
      onNext: null,
      onLast: null,
      reviewing: false,
      flipped: true,
    )));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cached_rounded)).color,
      AppColors.accentStart,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded)).color,
      Colors.black38,
    );
  });

  testWidgets('без стрелок рисуется только кнопка переворота', (tester) async {
    await tester.pumpWidget(_wrap(const GameReviewBar(
      onFlip: _noop,
      showNavigation: false,
    )));
    expect(find.byIcon(Icons.cached_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(find.byIcon(Icons.first_page_rounded), findsNothing);
  });
}

void _noop() {}
