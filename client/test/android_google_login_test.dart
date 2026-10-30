import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/login_screen.dart';
import 'package:multigames_client/widgets/oauth_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    required TargetPlatform platform,
    required Future<List<String>> Function() providers,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(path: '/register', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(path: '/games', builder: (_, __) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          oauthProvidersProvider.overrideWith((ref) => providers()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Android login shows Google while providers are still loading',
      (tester) async {
    try {
      await pumpLogin(
        tester,
        platform: TargetPlatform.android,
        providers: () => Completer<List<String>>().future,
      );

      expect(find.text('Вход'), findsOneWidget);
      expect(find.text('или войти через'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android login shows Google when the provider list is empty',
      (tester) async {
    try {
      await pumpLogin(
        tester,
        platform: TargetPlatform.android,
        providers: () async => const <String>[],
      );
      await tester.pump();

      expect(find.text('или войти через'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Desktop login hides OAuth until the server list arrives',
      (tester) async {
    try {
      await pumpLogin(
        tester,
        platform: TargetPlatform.linux,
        providers: () => Completer<List<String>>().future,
      );

      expect(find.text('Вход'), findsOneWidget);
      expect(find.text('или войти через'), findsNothing);
      expect(find.text('Google'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS login shows Apple while providers are still loading',
      (tester) async {
    try {
      await pumpLogin(
        tester,
        platform: TargetPlatform.iOS,
        providers: () => Completer<List<String>>().future,
      );

      expect(find.text('или войти через'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Google'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
