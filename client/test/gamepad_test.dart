import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_repeat.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_chrome.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_text.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
    GamepadPagerRegistry.reset();
    GamepadChromeRegistry.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
    GamepadService.debugPollNative = false;
  });

  tearDown(() {
    GamepadService.instance.reset();
  });

  test('стандартные кнопки Xbox совпадают с W3C mapping', () {
    expect(gamepadActionFromStandardButton(0), GamepadAction.confirm);
    expect(gamepadActionFromStandardButton(1), GamepadAction.cancel);
    expect(gamepadActionFromStandardButton(2), GamepadAction.actionX);
    expect(gamepadActionFromStandardButton(3), GamepadAction.actionY);
    expect(gamepadActionFromStandardButton(4), GamepadAction.shoulderL);
    expect(gamepadActionFromStandardButton(5), GamepadAction.shoulderR);
    expect(gamepadActionFromStandardButton(12), GamepadAction.up);
    expect(gamepadActionFromStandardButton(13), GamepadAction.down);
    expect(gamepadActionFromStandardButton(14), GamepadAction.left);
    expect(gamepadActionFromStandardButton(15), GamepadAction.right);
    expect(gamepadActionFromStandardButton(9), GamepadAction.menu);
    expect(gamepadActionFromStandardButton(6), GamepadAction.triggerL);
    expect(gamepadActionFromStandardButton(7), GamepadAction.triggerR);
  });

  test('стик выбирает большую ось и игнорирует мёртвую зону', () {
    expect(gamepadActionFromStick(x: 0.1, y: -0.1), isNull);
    expect(gamepadActionFromStick(x: 0.9, y: 0.2), GamepadAction.right);
    expect(gamepadActionFromStick(x: -0.8, y: 0.1), GamepadAction.left);
    expect(gamepadActionFromStick(x: 0.1, y: -0.9), GamepadAction.up);
    expect(gamepadActionFromStick(x: 0.2, y: 0.95), GamepadAction.down);
  });

  test('клавиши и game-button ключи мапятся', () {
    expect(gamepadActionFromKey(LogicalKeyboardKey.arrowLeft), GamepadAction.left);
    expect(gamepadActionFromKey(LogicalKeyboardKey.enter), GamepadAction.confirm);
    expect(gamepadActionFromKey(LogicalKeyboardKey.escape), GamepadAction.cancel);
    expect(gamepadActionFromKey(LogicalKeyboardKey.gameButtonA), GamepadAction.confirm);
    expect(gamepadActionFromKey(LogicalKeyboardKey.gameButtonB), GamepadAction.cancel);
    expect(gamepadActionFromKey(LogicalKeyboardKey.pageDown), GamepadAction.shoulderR);
    expect(gamepadActionFromKey(LogicalKeyboardKey.keyA), isNull);
  });

  test('курсор сетки не выходит за край', () {
    final cursor = GamepadGridCursor(columns: 3, count: 9, index: 4);
    expect(cursor.move(GamepadAction.up), isTrue);
    expect(cursor.index, 1);
    expect(cursor.move(GamepadAction.up), isFalse);
    expect(cursor.index, 1);
    expect(cursor.move(GamepadAction.left), isTrue);
    expect(cursor.index, 0);
    expect(cursor.move(GamepadAction.left), isFalse);
    expect(cursor.move(GamepadAction.right), isTrue);
    expect(cursor.index, 1);
    cursor.configure(columns: 10, count: 100);
    cursor.index = 99;
    expect(cursor.move(GamepadAction.right), isFalse);
    expect(cursor.move(GamepadAction.left), isTrue);
    expect(cursor.index, 98);
  });

  test('переворот сетки меняет визуальные стороны', () {
    final cursor = GamepadGridCursor(columns: 8, count: 64, index: 0);
    expect(cursor.move(GamepadAction.down, flip: true), isFalse);
    expect(cursor.move(GamepadAction.up, flip: true), isTrue);
    expect(cursor.index, 8);
  });

  test('repeat: первое нажатие сразу, потом пауза и повтор', () {
    final t = GamepadRepeatTracker(
      initialDelay: const Duration(milliseconds: 200),
      repeatEvery: const Duration(milliseconds: 50),
    );
    final t0 = DateTime.utc(2026, 1, 1);
    expect(
      t.tick(
        heldDirections: {GamepadAction.right},
        pressedNow: const {},
        now: t0,
      ),
      [GamepadAction.right],
    );
    expect(
      t.tick(
        heldDirections: {GamepadAction.right},
        pressedNow: const {},
        now: t0.add(const Duration(milliseconds: 100)),
      ),
      isEmpty,
    );
    expect(
      t.tick(
        heldDirections: {GamepadAction.right},
        pressedNow: const {},
        now: t0.add(const Duration(milliseconds: 200)),
      ),
      [GamepadAction.right],
    );
    expect(
      t.tick(
        heldDirections: {GamepadAction.right},
        pressedNow: {GamepadAction.confirm},
        now: t0.add(const Duration(milliseconds: 210)),
      ),
      [GamepadAction.confirm],
    );
  });

  test('gamepadEnabledProvider по умолчанию включён и сохраняется', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(gamepadEnabledProvider), isTrue);
    await container.read(gamepadEnabledProvider.notifier).set(false);
    expect(container.read(gamepadEnabledProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gamepad_enabled'), isFalse);
  });

  testWidgets('GamepadScope перехватывает действие раньше оболочки',
      (tester) async {
    final handled = <GamepadAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GamepadScope(
          onAction: (action) {
            handled.add(action);
            return true;
          },
          child: const SizedBox(),
        ),
      ),
    );
    expect(GamepadDispatcher.dispatch(GamepadAction.confirm), isTrue);
    expect(handled, [GamepadAction.confirm]);
    await tester.pumpWidget(const SizedBox());
    expect(GamepadDispatcher.dispatch(GamepadAction.confirm), isFalse);
  });

  test('семейство геймпада по имени устройства', () {
    expect(gamepadFamilyFromName('Xbox Wireless Controller'), GamepadFamily.xbox);
    expect(gamepadFamilyFromName('DualSense Wireless Controller'), GamepadFamily.playstation);
    expect(gamepadFamilyFromName('Nintendo Switch Pro Controller'), GamepadFamily.nintendo);
    expect(
      gamepadButtonLook(GamepadAction.confirm, family: GamepadFamily.xbox).label,
      'A',
    );
    expect(
      gamepadButtonLook(GamepadAction.confirm, family: GamepadFamily.playstation)
          .label,
      '✕',
    );
    expect(
      gamepadButtonLook(GamepadAction.confirm, family: GamepadFamily.nintendo)
          .label,
      'B',
    );
  });

  test('cycleIndex ходит по кругу', () {
    expect(cycleIndex(0, 3, GamepadAction.left), 2);
    expect(cycleIndex(2, 3, GamepadAction.right), 0);
    expect(cycleIndex(1, 3, GamepadAction.up), 0);
    expect(cycleIndex(1, 3, GamepadAction.down), 2);
    expect(cycleIndex(0, 0, GamepadAction.right), 0);
  });

  test('GamepadTextEditing вставляет и стирает в выделении', () {
    const value = TextEditingValue(
      text: 'abc',
      selection: TextSelection(baseOffset: 1, extentOffset: 2),
    );
    final inserted = GamepadTextEditing.applyInsert(value, 'X');
    expect(inserted!.text, 'aXc');
    expect(inserted.selection.baseOffset, 2);
    final erased = GamepadTextEditing.applyBackspace(value);
    expect(erased.text, 'ac');
    expect(erased.selection.baseOffset, 1);
    final one = GamepadTextEditing.applyBackspace(
      const TextEditingValue(
        text: 'hi',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(one.text, 'h');
  });

  test('раскладки клавиатуры геймпада содержат буквы и служебные клавиши', () {
    final latin = gamepadKeyboardRows(
      layout: GamepadKeyboardLayout.latin,
      shift: false,
    );
    expect(latin.first.map((k) => k.id).join(), 'qwertyuiop');
    expect(latin.last.any((k) => k.id == 'space'), isTrue);
    final cyr = gamepadKeyboardRows(
      layout: GamepadKeyboardLayout.cyrillic,
      shift: true,
    );
    expect(cyr.first.first.label, 'Й');
    final digits = gamepadKeyboardRows(
      layout: GamepadKeyboardLayout.digits,
      shift: false,
    );
    expect(digits.first.first.id, '1');
  });

  testWidgets('GamepadHost по A активирует сфокусированную кнопку',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tapped = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: Center(
                child: FilledButton(
                  autofocus: true,
                  onPressed: () => tapped++,
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(tapped, 1);
  });

  test('подсказки только при подключённом геймпаде', () {
    final service = GamepadService.instance;
    service.start();
    service.markActive();
    expect(gamepadConnected(), isFalse);
    expect(gamepadHintsWanted(), isFalse);
    service.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    expect(gamepadConnected(), isTrue);
    expect(gamepadHintsWanted(), isTrue);
    expect(currentGamepadFamily(), GamepadFamily.xbox);
  });

  test('кнопка геймпада считает контроллер найденным, стрелки — нет', () {
    expect(isDedicatedGamepadKey(LogicalKeyboardKey.arrowDown), isFalse);
    expect(isDedicatedGamepadKey(LogicalKeyboardKey.enter), isFalse);
    expect(isDedicatedGamepadKey(LogicalKeyboardKey.escape), isFalse);
    expect(isDedicatedGamepadKey(LogicalKeyboardKey.gameButtonA), isTrue);
    expect(isDedicatedGamepadKey(LogicalKeyboardKey.gameButtonLeft1), isTrue);
    final service = GamepadService.instance;
    service.start();
    expect(gamepadConnected(), isFalse);
    service.noteDedicatedGamepadKey();
    expect(gamepadConnected(), isTrue);
    expect(service.devices.value.single.id, GamepadService.keyPadId);
  });

  testWidgets('B закрывает диалог из GamepadHost над навигатором',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => GamepadHost(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    autofocus: true,
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          content: Text('dlg'),
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pumpAndSettle();
    expect(find.text('dlg'), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pumpAndSettle();
    expect(find.text('dlg'), findsNothing);
  });

  testWidgets('оверлей не показывает легенду над вкладками', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Scaffold(
              body: Center(
                child: FilledButton(
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Вкладки'), findsNothing);
    expect(find.text('Сменить'), findsNothing);
  });

  testWidgets('GamepadHost по A переключает сфокусированный Switch',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var value = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Switch(
                      autofocus: true,
                      value: value,
                      onChanged: (v) => setState(() => value = v),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('настройки без геймпада не показывают клавиши', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GamepadService.instance.start();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Геймпад не найден'), findsOneWidget);
    expect(find.text('Меню'), findsNothing);
    expect(find.text('Карты'), findsNothing);
    expect(find.text('Клавиатура'), findsNothing);
  });

  testWidgets('настройки с геймпадом показывают короткое управление',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'DualSense Wireless Controller', index: 0),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Геймпад не найден'), findsNothing);
    expect(find.textContaining('DualSense'), findsOneWidget);
    expect(find.text('Меню'), findsOneWidget);
    expect(find.text('Выбрать'), findsOneWidget);
    expect(find.text('Назад'), findsOneWidget);
    expect(find.text('Вкладки'), findsOneWidget);
    expect(find.text('Карты'), findsOneWidget);
    expect(find.text('Клавиатура'), findsWidgets);
  });

  testWidgets('настройки после кнопки геймпада больше не пишут «не найден»',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    GamepadService.instance.start();
    GamepadService.instance.noteDedicatedGamepadKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Геймпад не найден'), findsNothing);
    expect(find.textContaining('Подключён'), findsOneWidget);
    expect(find.text('Выбрать'), findsOneWidget);
  });

  testWidgets('скрытая ветка IndexedStack не видима для геймпада',
      (tester) async {
    final hidden = FocusNode();
    addTearDown(hidden.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: 0,
            children: [
              const SizedBox(width: 200, height: 200),
              Focus(
                focusNode: hidden,
                child: ListTile(
                  title: const Text('player2'),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    hidden.requestFocus();
    await tester.pump();
    expect(hidden.hasFocus, isTrue);
    expect(isGamepadFocusVisible(hidden), isFalse);
  });

  testWidgets('A не открывает скрытый чат IndexedStack', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var chat = 0;
    final chatFocus = FocusNode();
    addTearDown(chatFocus.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: IndexedStack(
                index: 0,
                children: [
                  const SizedBox.expand(),
                  ListTile(
                    focusNode: chatFocus,
                    title: const Text('player2'),
                    onTap: () => chat++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    chatFocus.requestFocus();
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(chat, 0);
  });

  testWidgets('A на карточке главной вызывает только её onTap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var shop = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: HomeActionCard(
                  icon: Icons.storefront_rounded,
                  title: 'Магазин',
                  subtitle: 'Смайлы, ставки, коллекции',
                  onTap: () => shop++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(shop, 1);
  });

  testWidgets('крест вниз ходит по карточкам и A жмёт текущую', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var first = 0;
    var second = 0;
    var third = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: FocusScope(
                child: ListView(
                  children: [
                    HomeActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Достижения',
                      subtitle: 'Ваши результаты',
                      onTap: () => first++,
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.monetization_on_rounded,
                      title: 'Монеты',
                      subtitle: 'Баланс',
                      onTap: () => second++,
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.storefront_rounded,
                      title: 'Магазин',
                      subtitle: 'Смайлы',
                      onTap: () => third++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(first, 0);
    expect(second, 1);
    expect(third, 0);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(third, 1);
  });

  testWidgets('крест в сетке ходит вправо и вниз по блокам', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final taps = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: FocusScope(
                child: SizedBox(
                  width: 400,
                  child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < 4; i++)
                      SizedBox(
                        width: 180,
                        child: HomeActionCard(
                          icon: Icons.storefront_rounded,
                          title: 'Карточка $i',
                          subtitle: 'блок',
                          onTap: () => taps.add(i),
                        ),
                      ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(taps, [1]);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(taps, [1, 3]);
  });

  testWidgets('Offstage+TickerMode чат не видим для геймпада', (tester) async {
    final hidden = FocusNode();
    addTearDown(hidden.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: 0,
            children: [
              const SizedBox.expand(),
              Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: ExcludeFocus(
                    child: ListTile(
                      focusNode: hidden,
                      title: const Text('player2'),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    hidden.requestFocus();
    await tester.pump();
    expect(isGamepadFocusVisible(hidden), isFalse);
  });

  testWidgets('A на магазине не открывает скрытый чат той же ячейки',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var shop = 0;
    var chat = 0;
    final chatFocus = FocusNode();
    addTearDown(chatFocus.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: IndexedStack(
                index: 0,
                children: [
                  ExcludeFocus(
                    excluding: false,
                    child: TickerMode(
                      enabled: true,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: HomeActionCard(
                            icon: Icons.storefront_rounded,
                            title: 'Магазин',
                            subtitle: 'Смайлы, ставки, коллекции',
                            onTap: () => shop++,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ExcludeFocus(
                    child: TickerMode(
                      enabled: false,
                      child: Offstage(
                        offstage: true,
                        child: ListTile(
                          focusNode: chatFocus,
                          title: const Text('player2'),
                          onTap: () => chat++,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    chatFocus.requestFocus();
    await tester.pump();
    expect(isGamepadFocusVisible(chatFocus), isFalse);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(chat, 0);
    expect(shop, 1);
  });

  testWidgets('скрытый GamepadScope не перехватывает A', (tester) async {
    var hidden = 0;
    var visible = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: IndexedStack(
          index: 0,
          children: [
            GamepadScope(
              onAction: (action) {
                if (action == GamepadAction.confirm) {
                  visible++;
                  return true;
                }
                return false;
              },
              child: const SizedBox(width: 40, height: 40),
            ),
            ExcludeFocus(
              child: TickerMode(
                enabled: false,
                child: Offstage(
                  offstage: true,
                  child: GamepadScope(
                    onAction: (action) {
                      if (action == GamepadAction.confirm) {
                        hidden++;
                        return true;
                      }
                      return false;
                    },
                    child: const SizedBox(width: 40, height: 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(GamepadDispatcher.dispatch(GamepadAction.confirm), isTrue);
    expect(hidden, 0);
    expect(visible, 1);
  });

  testWidgets('скрытый GamepadScope чата не открывает диалог с главной',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var shop = 0;
    var chat = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: IndexedStack(
                index: 0,
                children: [
                  ExcludeFocus(
                    excluding: false,
                    child: TickerMode(
                      enabled: true,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: HomeActionCard(
                            icon: Icons.storefront_rounded,
                            title: 'Магазин',
                            subtitle: 'Смайлы, ставки, коллекции',
                            onTap: () => shop++,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ExcludeFocus(
                    child: TickerMode(
                      enabled: false,
                      child: Offstage(
                        offstage: true,
                        child: GamepadScope(
                          onAction: (action) {
                            if (action == GamepadAction.confirm) {
                              chat++;
                              return true;
                            }
                            return false;
                          },
                          child: const SizedBox(width: 80, height: 40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(chat, 0);
    expect(shop, 1);
  });

  testWidgets('первый вниз без фокуса берёт первую карточку, второй — следующую',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var first = 0;
    var second = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'Ваши результаты',
                    onTap: () => first++,
                  ),
                  const SizedBox(height: 12),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: 'Баланс',
                    onTap: () => second++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(first, 1);
    expect(second, 0);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(second, 1);
  });

  testWidgets('LB/RB листают вкладки даже если GamepadScope всё перехватывает',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: GamepadScope(
              onAction: (_) => true,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.shoulderL);
    await tester.pump();
    expect(tabs, 2);
  });

  testWidgets('скрытое поле чата не глотает LB/RB и крест по карточкам',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    var first = 0;
    var second = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    final hidden = FocusNode();
    addTearDown(hidden.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: IndexedStack(
                index: 0,
                children: [
                  ListView(
                    children: [
                      HomeActionCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Достижения',
                        subtitle: 'Ваши результаты',
                        onTap: () => first++,
                      ),
                      const SizedBox(height: 12),
                      HomeActionCard(
                        icon: Icons.monetization_on_rounded,
                        title: 'Монеты',
                        subtitle: 'Баланс',
                        onTap: () => second++,
                      ),
                    ],
                  ),
                  Offstage(
                    offstage: true,
                    child: TickerMode(
                      enabled: false,
                      child: TextField(focusNode: hidden),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    hidden.requestFocus();
    await tester.pump();
    expect(isEditableTextFocused(), isFalse);
    expect(isGamepadContextOnstage(hidden.context!), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
    await tester.pump();
    expect(tabs, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(first, 1);
    expect(second, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(second, 1);
  });

  testWidgets('стрелка D-pad сразу считает геймпад подключённым',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GamepadHost(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();
    expect(gamepadConnected(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(gamepadConnected(), isTrue);
  });

  test('Android L1/R1 и D-pad мапятся в плечи и крест', () {
    expect(gamepadActionFromAndroidKeyCode(102), GamepadAction.shoulderL);
    expect(gamepadActionFromAndroidKeyCode(103), GamepadAction.shoulderR);
    expect(gamepadActionFromAndroidKeyCode(104), GamepadAction.triggerL);
    expect(gamepadActionFromAndroidKeyCode(105), GamepadAction.triggerR);
    expect(
      gamepadActionFromKey(LogicalKeyboardKey.gameButtonLeft2),
      GamepadAction.triggerL,
    );
    expect(
      gamepadActionFromKey(LogicalKeyboardKey.gameButtonRight2),
      GamepadAction.triggerR,
    );
    expect(gamepadActionFromAndroidKeyCode(19), GamepadAction.up);
    expect(gamepadActionFromAndroidKeyCode(22), GamepadAction.right);
    expect(gamepadActionFromKey(LogicalKeyboardKey.gameButton5), GamepadAction.shoulderL);
    expect(gamepadActionFromKey(LogicalKeyboardKey.gameButton6), GamepadAction.shoulderR);
  });

  testWidgets('стики и стрелки не листают вкладки, только LB/RB',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (delta) => tabs += delta;
    addTearDown(() => GamepadNav.switchTab = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'x',
                    onTap: () {},
                  ),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: 'x',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.left);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    expect(tabs, 0);
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    expect(tabs, 1);
  });

  test('правый стик листает зарегистрированную страницу', () {
    final pager = _TestGamepadPager();
    GamepadPagerRegistry.register(pager);
    addTearDown(() => GamepadPagerRegistry.unregister(pager));
    expect(scrollGamepadByPage(1), isTrue);
    expect(pager.delta, 1);
    expect(scrollGamepadByPage(-1), isTrue);
    expect(pager.delta, 0);
  });

  testWidgets('вниз с последней карточки листает страницу, не вкладку',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    final pager = _TestGamepadPager();
    GamepadPagerRegistry.register(pager);
    addTearDown(() => GamepadPagerRegistry.unregister(pager));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: HomeActionCard(
                icon: Icons.emoji_emotions_outlined,
                title: 'Смайл',
                subtitle: 'один',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    expect(pager.delta, 1);
    expect(tabs, 0);
    GamepadService.instance.emit(GamepadAction.scrollDown);
    await tester.pump();
    expect(pager.delta, 2);
  });

  testWidgets('в превью A покупает, B закрывает', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var bought = 0;
    var closed = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: GamepadScope(
              onAction: (action) {
                if (action == GamepadAction.confirm) {
                  bought++;
                  return true;
                }
                if (action.isDirection || action.isScroll) return true;
                if (action == GamepadAction.shoulderL ||
                    action == GamepadAction.shoulderR) {
                  return false;
                }
                closed++;
                return true;
              },
              child: Scaffold(
                body: Center(
                  child: GamepadBuyButton(
                    onPressed: () => bought++,
                    label: 'Купить',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(bought, 1);
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pump();
    expect(closed, 1);
    GamepadService.instance.emit(GamepadAction.actionX);
    await tester.pump();
    expect(closed, 2);
    final outline = tester.getSize(find.byType(GamepadFocusBlock));
    final button = tester.getSize(find.byType(FilledButton));
    expect(outline.width, closeTo(button.width, 1));
    expect(outline.height, closeTo(button.height, 1));
  });

  testWidgets('кнопка назад — квадрат 40 с круглой обводкой', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var back = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              appBar: AppBar(
                leading: GamepadBackButton(onPressed: () => back++),
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final box = tester.getSize(find.byType(GamepadFocusBlock));
    expect(box.width, 40);
    expect(box.height, 40);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(back, 1);
  });

  testWidgets('эксклюзивный диалог: A подтверждает, B и LB не трогают фон',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    var confirmed = 0;
    var dismissed = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: GamepadScope(
              exclusive: true,
              onAction: (action) {
                if (action == GamepadAction.confirm) {
                  confirmed++;
                } else {
                  dismissed++;
                }
                return true;
              },
              child: const Scaffold(body: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pump();
    expect(dismissed, 1);
    expect(tabs, 0);
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    expect(dismissed, 2);
    expect(tabs, 0);
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(confirmed, 1);
  });

  testWidgets('диалог покупки: A покупает, B закрывает только диалог',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var bought = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        bought = await showGamepadConfirmDialog(
                          context: context,
                          title: 'Купить',
                          message: 'Товар',
                          confirmLabel: 'Купить',
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Товар'), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pumpAndSettle();
    expect(find.text('Товар'), findsNothing);
    expect(bought, isFalse);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pumpAndSettle();
    expect(bought, isTrue);
    expect(find.text('Товар'), findsNothing);
  });

  testWidgets('LT фокусирует баланс, вниз — карточки; RT — выход',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var cards = 0;
    var logout = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Scaffold(
              appBar: AppBar(
                title: const ToolbarBalanceChip(bronze: 12),
                actions: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: GamepadFocusBlock(
                      chrome: GamepadChromeSlot.logout,
                      shape: GamepadHighlightShape.circle,
                      radius: 20,
                      onActivate: () => logout++,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              body: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'x',
                    onTap: () => cards++,
                  ),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: 'x',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.triggerL);
    await tester.pump();
    expect(
      GamepadFocusBlock.maybeOf(FocusManager.instance.primaryFocus!.context!),
      isNotNull,
    );
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(cards, 1);
    GamepadService.instance.emit(GamepadAction.triggerR);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(logout, 1);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.up);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(cards, 2);
    expect(logout, 1);
  });

  testWidgets('крест не заходит на баланс и выход, только LT/RT',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var logout = 0;
    var cards = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Scaffold(
              appBar: AppBar(
                title: const ToolbarBalanceChip(bronze: 12),
                actions: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: GamepadFocusBlock(
                      chrome: GamepadChromeSlot.logout,
                      shape: GamepadHighlightShape.circle,
                      radius: 20,
                      onActivate: () => logout++,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              body: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'x',
                    onTap: () => cards++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.up);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(cards, 1);
    expect(logout, 0);
    GamepadService.instance.emit(GamepadAction.triggerR);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(logout, 1);
  });

  testWidgets('вниз с последней карточки не прыгает на первую',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var first = 0;
    var last = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'x',
                    onTap: () => first++,
                  ),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: 'x',
                    onTap: () => last++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(first, 0, reason: 'после одного вниз должны быть на второй');
    expect(last, 1);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(first, 0);
    expect(last, 2);
  });

  testWidgets('кнопка «Получено» совпадает с рамкой FilledButton',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GamepadHost(
            child: Scaffold(
              body: Center(
                child: GamepadFocusBlock(
                  autofocus: true,
                  outlined: false,
                  radius: AppRadius.button,
                  borderWidth: 2.2,
                  child: Builder(
                    builder: (context) {
                      return FilledButton(
                        onPressed: () {},
                        style: AppButtonStyles.of(
                          minimumSize: const Size(180, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          radius: AppRadius.button,
                        ).copyWith(
                          side: WidgetStatePropertyAll(
                            GamepadFocusBlock.buttonSide(context),
                          ),
                        ),
                        child: const Text('Получено'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    final outline = tester.getSize(find.byType(GamepadFocusBlock));
    final button = tester.getSize(find.byType(FilledButton));
    expect(outline.width, closeTo(button.width, 1));
    expect(outline.height, closeTo(button.height, 1));
    final style = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .style;
    expect(
      style?.side?.resolve({}),
      const BorderSide(color: AppColors.accentStart, width: 2.2),
    );
  });

  testWidgets('кнопка «Уже получено» совпадает с рамкой FilledButton.icon',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GamepadHost(
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: GamepadFocusBlock(
                    autofocus: true,
                    outlined: false,
                    radius: AppRadius.button,
                    borderWidth: 2.2,
                    child: Builder(
                      builder: (context) {
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.card_giftcard, size: 18),
                            label: const Text('Уже получено'),
                            style: AppButtonStyles.of(
                              minimumSize: const Size(44, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              radius: AppRadius.button,
                            ).copyWith(
                              side: WidgetStatePropertyAll(
                                GamepadFocusBlock.buttonSide(context),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Уже получено'), findsOneWidget);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    final outline = tester.getSize(find.byType(GamepadFocusBlock));
    final buttonFinder = find.ancestor(
      of: find.text('Уже получено'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final button = tester.getSize(buttonFinder.first);
    expect(outline.width, closeTo(button.width, 1));
    expect(outline.height, closeTo(button.height, 1));
    expect(outline.width, closeTo(400, 1));
    final style =
        tester.widget<ButtonStyleButton>(buttonFinder.first).style;
    expect(
      style?.side?.resolve({}),
      const BorderSide(color: AppColors.accentStart, width: 2.2),
    );
  });

  test('токен exclusive снимается и не глушит ввод', () {
    var hits = 0;
    bool handler(GamepadAction action) {
      hits++;
      return true;
    }

    final id = GamepadDispatcher.push(handler, exclusive: true);
    expect(GamepadDispatcher.hasExclusive, isTrue);
    expect(GamepadDispatcher.dispatch(GamepadAction.confirm), isTrue);
    expect(hits, 1);
    GamepadDispatcher.remove(id);
    expect(GamepadDispatcher.hasExclusive, isFalse);
    expect(GamepadDispatcher.dispatch(GamepadAction.confirm), isFalse);
  });

  testWidgets('после закрытия диалога геймпад снова листает вкладки',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () {
                        unawaited(
                          showGamepadConfirmDialog(
                            context: context,
                            title: 'Купить',
                            message: 'Товар',
                            confirmLabel: 'Купить',
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Товар'), findsOneWidget);
    expect(GamepadDispatcher.hasExclusive, isTrue);
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pumpAndSettle();
    expect(find.text('Товар'), findsNothing);
    expect(GamepadDispatcher.hasExclusive, isFalse);
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    expect(tabs, 1);
  });

  testWidgets('стик закрывает обычный диалог и не глушит вкладки',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => const AlertDialog(
                            title: Text('Баланс'),
                            content: Text('монеты'),
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('монеты'), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pumpAndSettle();
    expect(find.text('монеты'), findsNothing);
    expect(GamepadDispatcher.hasExclusive, isFalse);
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    expect(tabs, 1);
  });

  testWidgets('exclusive без обработки не глушит вкладки', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var tabs = 0;
    GamepadNav.switchTab = (_) => tabs++;
    addTearDown(() => GamepadNav.switchTab = null);
    final leaked = GamepadDispatcher.push((_) => false, exclusive: true);
    addTearDown(() => GamepadDispatcher.remove(leaked));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(GamepadDispatcher.hasExclusive, isTrue);
    GamepadService.instance.emit(GamepadAction.shoulderR);
    await tester.pump();
    expect(tabs, 1);
  });
}

class _TestGamepadPager implements GamepadPager {
  int delta = 0;

  @override
  bool page(int value) {
    delta += value;
    return true;
  }
}
