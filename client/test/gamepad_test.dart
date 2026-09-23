import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_repeat.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_text.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
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
    expect(gamepadActionFromStandardButton(7), isNull);
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
}
