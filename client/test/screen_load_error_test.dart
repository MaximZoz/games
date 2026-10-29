import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/screen_load_error.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('timeout explains the wait and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScreenLoadError(
            title: 'Не удалось загрузить друзей',
            error: TimeoutException(
              'Future not completed',
              const Duration(seconds: 12),
            ),
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Не удалось загрузить друзей'), findsOneWidget);
    expect(find.textContaining('12 с'), findsOneWidget);
    expect(find.textContaining('Future not completed'), findsNothing);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('screen-load-retry')));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('narrow width keeps the retry button', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ScreenLoadError(
            title: 'Не удалось загрузить чаты',
            error: 'socket exception',
            onRetry: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Не удалось загрузить чаты'), findsOneWidget);
    expect(find.textContaining('Нет связи'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}

void _noop() {}
