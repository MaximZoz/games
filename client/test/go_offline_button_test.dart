// «Перейти в офлайн» рядом с «Повторить» на экране ошибки загрузки.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/go_offline_button.dart';
import 'package:multigames_client/ui/widgets/screen_load_error.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_locale.dart';

class _Offline extends OfflineModeNotifier {
  _Offline() : super(autostart: false);
}

class _Auth extends AuthStateNotifier {
  _Auth(super.ref, AuthUser? user) {
    state = AsyncValue.data(user);
  }

  @override
  Future<void> ensureSessionFresh() async {}
}

final _user = AuthUser(id: 'u-1', email: 'user@test.com', displayName: 'User');

Future<_Offline> _pump(
  WidgetTester tester, {
  required Object error,
  bool authorized = true,
  bool offlineMode = false,
  Size size = const Size(400, 800),
  Locale locale = const Locale('ru'),
  VoidCallback? onRetry,
}) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final offline = _Offline();
  if (offlineMode) {
    await offline.setPreference(OfflinePreference.offline);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineModeProvider.overrideWith((ref) => offline),
        authStateProvider.overrideWith(
          (ref) => _Auth(ref, authorized ? _user : null),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScreenLoadError(
            title: 'Не удалось загрузить друзей',
            error: error,
            onRetry: onRetry ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return offline;
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    ServerLink.instance.reset();
  });
  tearDown(ServerLink.instance.reset);

  test('связь с сервером отличаем от ответа сервера', () {
    expect(isNoConnectionError(http.ClientException('Failed to fetch')), isTrue);
    expect(isNoConnectionError(TimeoutException('t')), isTrue);
    expect(isNoConnectionError('SocketException: connection refused'), isTrue);
    expect(isNoConnectionError(FriendsException(500, 'boom')), isFalse);
    expect(isNoConnectionError(FriendsException(503, 'unavailable')), isFalse);
    expect(isNoConnectionError(OfflineModeException()), isFalse);
    expect(isNoConnectionError(null), isFalse);
  });

  testWidgets('нет связи: рядом с «Повторить» есть «Перейти в офлайн»',
      (tester) async {
    var retries = 0;
    final offline = await _pump(
      tester,
      error: http.ClientException('Failed to fetch'),
      onRetry: () => retries++,
    );

    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Перейти в офлайн'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('screen-load-retry')));
    await tester.pump();
    expect(retries, 1);
    expect(offline.state.isOffline, isFalse);

    await tester.tap(find.byKey(goOfflineButtonKey));
    await tester.pumpAndSettle();

    expect(offline.state.isOffline, isTrue);
    expect(ServerLink.instance.offline, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('offline_mode_preference'), 'offline');
    // В офлайне кнопка уже не нужна.
    expect(find.byKey(goOfflineButtonKey), findsNothing);
  });

  testWidgets('таймаут сервера тоже предлагает офлайн', (tester) async {
    await _pump(
      tester,
      error: TimeoutException('Future not completed', const Duration(seconds: 12)),
    );
    expect(find.byKey(goOfflineButtonKey), findsOneWidget);
  });

  testWidgets('сервер ответил ошибкой — офлайн не предлагаем', (tester) async {
    await _pump(tester, error: FriendsException(500, 'Internal error'));
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.byKey(goOfflineButtonKey), findsNothing);
  });

  testWidgets('гостю офлайн не предлагаем', (tester) async {
    await _pump(
      tester,
      error: http.ClientException('Failed to fetch'),
      authorized: false,
    );
    expect(find.byKey(goOfflineButtonKey), findsNothing);
  });

  testWidgets('в офлайн режиме кнопки нет', (tester) async {
    await _pump(
      tester,
      error: http.ClientException('Failed to fetch'),
      offlineMode: true,
    );
    expect(find.byKey(goOfflineButtonKey), findsNothing);
  });

  testWidgets('узкий экран и длинный перевод помещаются без переполнения',
      (tester) async {
    await _pump(
      tester,
      error: http.ClientException('Failed to fetch'),
      size: const Size(320, 480),
      locale: const Locale('de'),
    );
    expect(find.byKey(goOfflineButtonKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
