import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/screen_load_error.dart';

import 'test_locale.dart';

class _Offline extends OfflineModeNotifier {
  _Offline() : super(autostart: false);
}

class _Guest extends AuthStateNotifier {
  _Guest(super.ref) {
    state = const AsyncValue<AuthUser?>.data(null);
  }

  @override
  Future<void> ensureSessionFresh() async {}
}

/// Экран ошибки читает режим сети и сессию — в тесте без сети и таймеров.
Widget _scoped(Widget child) {
  return ProviderScope(
    overrides: [
      offlineModeProvider.overrideWith((ref) => _Offline()),
      authStateProvider.overrideWith((ref) => _Guest(ref)),
    ],
    child: child,
  );
}

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('timeout explains the wait and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _scoped(
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
      _scoped(
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
      ),
    );

    expect(find.text('Не удалось загрузить чаты'), findsOneWidget);
    expect(find.textContaining('Нет связи'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}

void _noop() {}
