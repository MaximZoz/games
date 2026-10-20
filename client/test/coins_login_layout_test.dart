import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/coins_login_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoggedOut extends AuthStateNotifier {
  _LoggedOut(super.ref) {
    state = const AsyncData<AuthUser?>(null);
  }
}

DailyRewardStatus _sampleStatus({bool available = true}) {
  return DailyRewardStatus(
    available: available,
    streak: 3,
    nextStreak: 4,
    nextRewardBronze: 10,
    milestonesBronze: const {
      1: 10,
      3: 50,
      7: 1000,
      30: 3000,
    },
  );
}

Future<void> _pumpCoinsLogin(
  WidgetTester tester, {
  required Size size,
  DailyRewardStatus? status,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final reward = status ?? _sampleStatus();
  final router = GoRouter(
    initialLocation: '/coins/login',
    routes: [
      GoRoute(
        path: '/coins/login',
        builder: (_, __) => const RepaintBoundary(
          key: ValueKey('coins-login-shot'),
          child: ColoredBox(
            color: AppColors.surfaceUnified,
            child: CoinsLoginScreen(),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => _LoggedOut(ref)),
        dailyRewardStatusProvider.overrideWith((ref) async => reward),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _saveShot(WidgetTester tester, String name) async {
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('coins-login-shot')),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  if (image == null) return;
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) return;
  File('${dir.path}/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    LocaleService.setLocale(const Locale('ru'));
    GamepadDispatcher.reset();
  });

  testWidgets('портрет телефона: карточки по содержимому без пустых дыр',
      (tester) async {
    await _pumpCoinsLogin(tester, size: const Size(390, 844));

    expect(find.byKey(const ValueKey('login-streak-hero')), findsOneWidget);
    expect(find.text('Забрать награду'), findsOneWidget);
    expect(find.text('1/1 · Получено'), findsOneWidget);
    expect(find.text('3/3 · Получено'), findsOneWidget);
    expect(find.text('3/7 · ещё 4'), findsOneWidget);

    for (final d in const [1, 3, 7, 30]) {
      final size = tester.getSize(find.byKey(ValueKey('login-milestone-$d')));
      expect(size.height, lessThan(110));
    }

    await _saveShot(tester, 'coins-login-phone.png');
  });

  testWidgets('альбом телефона: сетка 2×2 и кнопка помещаются без переполнения',
      (tester) async {
    await _pumpCoinsLogin(tester, size: const Size(844, 390));

    expect(find.byKey(const ValueKey('login-streak-hero')), findsOneWidget);
    expect(find.text('Забрать награду'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final c1 = tester.getTopLeft(find.byKey(const ValueKey('login-milestone-1')));
    final c3 = tester.getTopLeft(find.byKey(const ValueKey('login-milestone-3')));
    expect((c1.dy - c3.dy).abs(), lessThan(2));
    expect(c3.dx, greaterThan(c1.dx));

    await _saveShot(tester, 'coins-login-landscape.png');

    await _pumpCoinsLogin(tester, size: const Size(568, 320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('десктоп/веб: аккуратная сетка 2×2 с шапкой серии',
      (tester) async {
    await _pumpCoinsLogin(
      tester,
      size: const Size(1280, 800),
      status: _sampleStatus(available: false),
    );

    expect(find.text('Уже получено'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await _saveShot(tester, 'coins-login-desktop.png');
  });
}
