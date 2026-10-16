import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/app_update_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:multigames_client/ui/widgets/app_update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notes = '- шашки возвращаются в свою партию\n- текст обновления в окне';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('окно показывает текст, «Обновить» и «Закрыть»', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _app(
        onOpen: (context) async {
          result = await showAppUpdatePromptDialog(
            context,
            whatsNew: _notes,
            allowClose: true,
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Доступно обновление'), findsOneWidget);
    expect(find.text('Что нового'), findsOneWidget);
    expect(find.text(_notes), findsOneWidget);
    expect(find.byKey(appUpdateConfirmKey), findsOneWidget);
    expect(find.byKey(appUpdateCloseKey), findsOneWidget);

    final update = tester.getTopLeft(find.byKey(appUpdateConfirmKey));
    final close = tester.getTopLeft(find.byKey(appUpdateCloseKey));
    expect(close.dx, lessThan(update.dx));
    expect((close.dy - update.dy).abs(), lessThan(8));

    await tester.tap(find.byKey(appUpdateCloseKey));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text(_notes), findsNothing);
  });

  testWidgets('«Обновить» в окне возвращает подтверждение', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _app(
        onOpen: (context) async {
          result = await showAppUpdatePromptDialog(
            context,
            whatsNew: _notes,
            allowClose: true,
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(appUpdateConfirmKey));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('принудительное окно без кнопки закрытия', (tester) async {
    await tester.pumpWidget(
      _app(
        onOpen: (context) {
          showAppUpdatePromptDialog(
            context,
            whatsNew: _notes,
            allowClose: false,
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(appUpdateCloseKey), findsNothing);
    expect(find.byKey(appUpdateConfirmKey), findsOneWidget);
    expect(find.text(_notes), findsOneWidget);
  });

  testWidgets('узкий экран ставит «Закрыть» под «Обновить»', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        onOpen: (context) {
          showAppUpdatePromptDialog(
            context,
            whatsNew: _notes,
            allowClose: true,
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final update = tester.getTopLeft(find.byKey(appUpdateConfirmKey));
    final close = tester.getTopLeft(find.byKey(appUpdateCloseKey));
    expect(close.dy, greaterThan(update.dy + 20));
  });

  testWidgets('длинный список прокручивается, кнопки остаются на экране',
      (tester) async {
    final long = List.filled(40, '- пункт списка обновления').join('\n');
    await tester.pumpWidget(
      _app(
        onOpen: (context) {
          showAppUpdatePromptDialog(
            context,
            whatsNew: long,
            allowClose: true,
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final close = tester.getRect(find.byKey(appUpdateCloseKey));
    final update = tester.getRect(find.byKey(appUpdateConfirmKey));
    expect(close.top, greaterThan(0));
    expect(update.bottom, lessThan(screen.height));
    expect(close.bottom, lessThan(screen.height));
    expect(tester.hitTestOnBinding(close.center).path, isNotEmpty);
    expect(tester.hitTestOnBinding(update.center).path, isNotEmpty);
  });

  testWidgets('в настройках текст спрятан, кнопка открывает окно',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final updates = <_SeededAppUpdate>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateProvider.overrideWith((ref) {
            final notifier = _SeededAppUpdate(ref, notes: _notes);
            updates.add(notifier);
            return notifier;
          }),
        ],
        child: _localized(home: const SettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(_notes), findsNothing);
    final button = find.byKey(const ValueKey('settings-app-update'));
    await tester.ensureVisible(button);
    await tester.pump();
    expect(find.text(_notes), findsNothing);

    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(appUpdateNotesKey), findsOneWidget);
    expect(find.text(_notes), findsOneWidget);
    expect(find.byKey(appUpdateCloseKey), findsOneWidget);
    expect(find.byKey(appUpdateConfirmKey), findsOneWidget);

    await tester.tap(find.byKey(appUpdateCloseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_notes), findsNothing);
    expect(updates.single.applyCount, 0);

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(appUpdateConfirmKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_notes), findsNothing);
    expect(updates.single.applyCount, 1);
  });
}

class _SeededAppUpdate extends AppUpdateNotifier {
  _SeededAppUpdate(super.ref, {required String notes}) {
    state = AppUpdateState(updateAvailable: true, whatsNew: notes);
  }

  int applyCount = 0;

  @override
  Future<void> check({String? latestBuild, String? whatsNew}) async {}

  @override
  Future<void> applyUpdate() async {
    applyCount++;
  }
}

Widget _app({required void Function(BuildContext context) onOpen}) {
  return _localized(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => onOpen(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Widget _localized({required Widget home}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
