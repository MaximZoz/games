// Диалог «нет связи с сервером»: когда появляется и что делают кнопки.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/server_unreachable_dialog.dart';
import 'package:multigames_client/widgets/server_unreachable_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервер «отвечает» так, как велит тест; сети и таймеров нет.
class _FakeOffline extends OfflineModeNotifier {
  _FakeOffline() : super(autostart: false);

  bool serverUp = false;
  int checks = 0;

  @override
  Future<bool> checkServerNow() async {
    checks++;
    setReachable(serverUp);
    return serverUp;
  }

  void setReachable(bool reachable) {
    state = state.copyWith(deviceOnline: true, serverReachable: reachable);
  }
}

class _Auth extends AuthStateNotifier {
  _Auth(super.ref, AuthUser? user) {
    state = AsyncValue.data(user);
  }

  @override
  Future<void> ensureSessionFresh() async {}
}

final _user = AuthUser(id: 'u-1', email: 'user@test.com', displayName: 'User');

Future<_FakeOffline> _pump(
  WidgetTester tester, {
  bool authorized = true,
  Size size = const Size(400, 800),
  Locale locale = const Locale('ru'),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final offline = _FakeOffline()..setReachable(true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineModeProvider.overrideWith((ref) => offline),
        authStateProvider.overrideWith(
          (ref) => _Auth(ref, authorized ? _user : null),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(
          body: ServerUnreachableGate(child: Text('content')),
        ),
      ),
    ),
  );
  await tester.pump();
  return offline;
}

void main() {
  setUp(ServerLink.instance.reset);
  tearDown(ServerLink.instance.reset);

  testWidgets('сбой API при недоступном сервере открывает диалог',
      (tester) async {
    final offline = await _pump(tester);
    expect(find.byType(ServerUnreachableDialog), findsNothing);

    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    expect(offline.checks, 1);
    expect(find.text('Нет связи с сервером'), findsOneWidget);
    expect(find.byKey(serverUnreachableRetryKey), findsOneWidget);
    expect(find.byKey(serverUnreachableOfflineKey), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Перейти в офлайн'), findsOneWidget);
  });

  testWidgets('одиночный сбой при живом сервере диалог не показывает',
      (tester) async {
    final offline = await _pump(tester);
    offline.serverUp = true;

    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    expect(offline.checks, 1);
    expect(find.byType(ServerUnreachableDialog), findsNothing);
  });

  testWidgets('несколько сбоев подряд дают один диалог', (tester) async {
    await _pump(tester);

    ServerLink.instance.reportFailure();
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    expect(find.byType(ServerUnreachableDialog), findsOneWidget);
  });

  testWidgets('фоновая проверка потеряла сервер — диалог без сбоя API',
      (tester) async {
    final offline = await _pump(tester);

    offline.setReachable(false);
    await tester.pumpAndSettle();

    expect(offline.checks, 0);
    expect(find.byType(ServerUnreachableDialog), findsOneWidget);
  });

  testWidgets('«Повторить»: связи нет — диалог остаётся с пометкой',
      (tester) async {
    final offline = await _pump(tester);
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(serverUnreachableRetryKey));
    await tester.pumpAndSettle();

    expect(offline.checks, 2);
    expect(find.byType(ServerUnreachableDialog), findsOneWidget);
    expect(find.byKey(serverUnreachableStillDownKey), findsOneWidget);
    expect(offline.state.isOffline, isFalse);
  });

  testWidgets('«Повторить»: сервер ответил — диалог закрыт, режим онлайн',
      (tester) async {
    final offline = await _pump(tester);
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    offline.serverUp = true;
    await tester.tap(find.byKey(serverUnreachableRetryKey));
    await tester.pumpAndSettle();

    expect(find.byType(ServerUnreachableDialog), findsNothing);
    expect(find.text('Связь с сервером восстановлена.'), findsOneWidget);
    expect(offline.state.isOffline, isFalse);
    // Тост живёт на таймере — даём ему уйти до конца теста.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('«Перейти в офлайн» включает офлайн и блокирует API',
      (tester) async {
    final offline = await _pump(tester);
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(serverUnreachableOfflineKey));
    await tester.pumpAndSettle();

    expect(find.byType(ServerUnreachableDialog), findsNothing);
    expect(offline.state.isOffline, isTrue);
    expect(ServerLink.instance.offline, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('offline_mode_preference'), 'offline');

    // В офлайне сбои API больше не поднимают диалог.
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();
    expect(find.byType(ServerUnreachableDialog), findsNothing);
  });

  testWidgets('закрыли без выбора — повторный сбой сразу не беспокоит',
      (tester) async {
    final offline = await _pump(tester);
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(ServerUnreachableDialog), findsNothing);

    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();
    expect(find.byType(ServerUnreachableDialog), findsNothing);
    expect(offline.checks, 1);
  });

  testWidgets('гостю диалог не показываем', (tester) async {
    final offline = await _pump(tester, authorized: false);

    ServerLink.instance.reportFailure();
    offline.setReachable(false);
    await tester.pumpAndSettle();

    expect(find.byType(ServerUnreachableDialog), findsNothing);
  });

  testWidgets('узкий экран и длинный перевод помещаются без переполнения',
      (tester) async {
    await _pump(
      tester,
      size: const Size(320, 480),
      locale: const Locale('de'),
    );
    ServerLink.instance.reportFailure();
    await tester.pumpAndSettle();

    expect(find.byType(ServerUnreachableDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    final dialog = tester.getSize(find.byType(Dialog).first);
    expect(dialog.height, lessThanOrEqualTo(480));
  });
}
