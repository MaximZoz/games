import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/profile/profile_photos.dart';
import 'package:multigames_client/screens/profile_screen.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthUser _user() => AuthUser(
      id: 'u-profile-pad',
      email: 'max@test.com',
      displayName: 'Zozzulyaa',
      about: 'Яделаюэтоэто',
      age: 33,
      gender: 'male',
    );

class _FixedAuth extends AuthStateNotifier {
  _FixedAuth(super.ref, AuthUser user) {
    state = AsyncValue.data(user);
  }
}

Future<void> _pumpProfile(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'user': jsonEncode(_user().toJson()),
  });
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentRoutePathProvider.overrideWith((ref) => '/profile'),
        authStateProvider.overrideWith((ref) => _FixedAuth(ref, _user())),
        inventoryListProvider.overrideWith((ref) async => const <InventoryItem>[]),
        inventoryCapabilitiesProvider.overrideWith(
          (ref) async => const InventoryCapabilities(
            allowedStakeBronze: [2, 10, 50],
          ),
        ),
        profilePhotosProvider.overrideWith((ref, id) async {
          return const <ProfilePhotoMeta>[];
        }),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ru'),
        home: GamepadHost(child: ProfileScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
    GamepadService.debugPollNative = false;
    GamepadKeyboardController.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
    GamepadKeyboardController.instance.reset();
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
  });

  testWidgets('тап по «о себе» не открывает редактирование', (tester) async {
    await _pumpProfile(tester);
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Яделаюэтоэто'), findsOneWidget);
    await tester.tap(find.text('Яделаюэтоэто'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Сохранить'), findsNothing);
  });

  testWidgets('редактировать открывает форму, обводка только на кнопке',
      (tester) async {
    await _pumpProfile(tester);
    expect(find.byType(GamepadFocusBlock), findsOneWidget);
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    final editCtx = tester.element(find.text('Редактировать'));
    expect(GamepadFocusBlock.maybeOf(editCtx)?.focusNode.hasFocus, isTrue);
    await tester.tap(find.text('Редактировать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Сохранить'), findsOneWidget);
    expect(
      tester.widgetList(find.byType(GamepadFocusBlock)).length,
      greaterThan(4),
    );
  });

  testWidgets('в редакторе геймпад ходит по полям', (tester) async {
    await _pumpProfile(tester);
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Сохранить'), findsOneWidget);
    dismissGamepadKeyboard();
    await tester.pump();
    expect(find.byKey(const ValueKey('compact_display_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact_age')), findsOneWidget);
    expect(find.text('Поменять аватар'), findsOneWidget);
    expect(
      GamepadFocusBlock.maybeOf(
        tester.element(find.byKey(const ValueKey('compact_age'))),
      ),
      isNotNull,
    );
    expect(
      GamepadFocusBlock.maybeOf(
        tester.element(find.text('Поменять аватар')),
      ),
      isNotNull,
    );
    expect(
      tester.widgetList(find.byType(GamepadFocusBlock)).length,
      greaterThan(8),
    );
    expect(GamepadKeyboardController.instance.visible, isFalse);
  });

  testWidgets(
      'в редакторе клавиатура только по A, B скрывает, назад выходит',
      (tester) async {
    await _pumpProfile(tester);
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Сохранить'), findsOneWidget);
    expect(GamepadKeyboardController.instance.visible, isFalse);
    expect(find.text('Клавиатура'), findsNothing);

    final nameScope = GamepadFocusBlock.maybeOf(
      tester.element(find.byKey(const ValueKey('compact_display_name'))),
    );
    expect(nameScope, isNotNull);
    nameScope!.focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(nameScope.focusNode.hasFocus, isTrue);

    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pump();
    expect(GamepadKeyboardController.instance.visible, isTrue);
    expect(find.text('Клавиатура'), findsOneWidget);

    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pump();
    expect(GamepadKeyboardController.instance.visible, isFalse);
    expect(find.text('Клавиатура'), findsNothing);
    expect(find.text('Сохранить'), findsOneWidget);

    final hostCtx = tester.element(find.byType(GamepadHost));
    handleGamepadUiAction(hostCtx, GamepadAction.down);
    await tester.pump();
    expect(GamepadKeyboardController.instance.visible, isFalse);
    final ageCtx = tester.element(find.byKey(const ValueKey('compact_age')));
    expect(GamepadFocusBlock.maybeOf(ageCtx)?.focusNode.hasFocus, isTrue);

    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Сохранить'), findsNothing);
  });
}
