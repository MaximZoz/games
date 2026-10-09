import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
    GamepadPagerRegistry.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
    GamepadFocusRegistry.reset();
    GamepadPagerRegistry.reset();
    GamepadDispatcher.reset();
  });

  testWidgets('карточка настроек: рамка со свечением, вниз не на тумблер',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Язык')), isTrue);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .any((paint) => paint.painter is GamepadFocusOutlinePainter),
      isTrue,
    );

    _pad(tester, GamepadAction.down);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Звук')), isTrue);
    expect(_blockFocused(tester, find.byType(Switch).first), isFalse);
  });

  testWidgets('вправо с карточки звука — тумблер, затем чекбокс',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.down);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Звук')), isTrue);

    _pad(tester, GamepadAction.right);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-switch')),
          matching: find.byType(Switch),
        ),
      ),
      isTrue,
    );

    _pad(tester, GamepadAction.right);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-games')),
          matching: find.byType(Checkbox),
        ),
      ),
      isTrue,
    );

    final gamesBox = find.descendant(
      of: find.byKey(const ValueKey('settings-sound-games')),
      matching: find.byType(Checkbox),
    );
    final before = tester.widget<Checkbox>(gamesBox).value;
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<Checkbox>(gamesBox).value, isNot(before));
  });

  testWidgets('вправо с языка не прыгает на тумблер звука', (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Язык')), isTrue);
    _pad(tester, GamepadAction.right);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Язык')), isTrue);
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-switch')),
          matching: find.byType(Switch),
        ),
      ),
      isFalse,
    );
  });

  testWidgets('A на языке открывает список, A выбирает, B закрывает',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('lang-system')), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);

    _pad(tester, GamepadAction.cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('lang-system')), findsNothing);
    expect(find.textContaining('Как в системе'), findsOneWidget);

    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Arabic'), findsOneWidget);
    GamepadFocusBlock.maybeOf(tester.element(find.text('Arabic')))!
        .focusNode
        .requestFocus();
    await tester.pump();
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('lang-ar')), findsNothing);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets(
      'правый стик в списке языков листает страницу и фокусирует первый',
      (tester) async {
    tester.view.physicalSize = const Size(400, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('lang-system')), findsOneWidget);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('lang-system')),
          matching: find.byType(ListTile),
        ),
      ),
      isTrue,
    );

    scrollGamepadByPage(
      1,
      context: tester.element(find.byKey(const ValueKey('lang-system'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('lang-system')),
          matching: find.byType(ListTile),
        ),
      ),
      isFalse,
    );
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'GamepadFocusBlock');
    expect(
      GamepadFocusBlock.maybeOf(focused!.context!)?.includeInEdgeFocus,
      isTrue,
    );
  });

  testWidgets('шапка языка непрозрачная, список не рисуется поверх',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('settings-language-list')),
    );
    expect(list.clipBehavior, Clip.hardEdge);
    expect(
      tester
          .widget<ColoredBox>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('settings-language-close')),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color,
      AppColors.surfaceCard,
    );
  });

  testWidgets('правый стик в языке не листает настройки за шитом',
      (tester) async {
    tester.view.physicalSize = const Size(400, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('lang-system')), findsOneWidget);

    final settingsScrollable = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    final settingsBefore =
        tester.state<ScrollableState>(settingsScrollable.first).position.pixels;
    final langBefore = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('settings-language-list')),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;

    scrollGamepadByPage(
      1,
      context: tester.element(find.byKey(const ValueKey('lang-system'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(
      tester.state<ScrollableState>(settingsScrollable.first).position.pixels,
      settingsBefore,
    );
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const ValueKey('settings-language-list')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels,
      greaterThan(langBefore),
    );
  });

  testWidgets('B с чекбокса возвращает рамку на карточку', (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.down);
    await tester.pump();
    _pad(tester, GamepadAction.right);
    await tester.pump();
    _pad(tester, GamepadAction.right);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-games')),
          matching: find.byType(Checkbox),
        ),
      ),
      isTrue,
    );
    _pad(tester, GamepadAction.cancel);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Звук')), isTrue);
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-games')),
          matching: find.byType(Checkbox),
        ),
      ),
      isFalse,
    );
  });

  testWidgets('правый стик вправо с карточки звука — на чекбокс',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    _pad(tester, GamepadAction.down);
    await tester.pump();
    _pad(tester, GamepadAction.scrollRight);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-switch')),
          matching: find.byType(Switch),
        ),
      ),
      isTrue,
    );
    _pad(tester, GamepadAction.scrollRight);
    await tester.pump();
    expect(
      _blockFocused(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('settings-sound-games')),
          matching: find.byType(Checkbox),
        ),
      ),
      isTrue,
    );
  });

  testWidgets(
      'у края настроек правый стик оставляет фокус на первом или последнем',
      (tester) async {
    tester.view.physicalSize = const Size(400, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(_blockFocused(tester, find.text('Язык')), isTrue);
    scrollGamepadByPage(-1, context: tester.element(find.text('Язык')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(_blockFocused(tester, find.text('Язык')), isTrue);

    for (var i = 0; i < 6; i++) {
      scrollGamepadByPage(1, context: tester.element(find.text('Язык')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(_blockFocused(tester, find.text('Язык')), isFalse);
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'GamepadFocusBlock');
    expect(
      GamepadFocusBlock.maybeOf(focused!.context!)?.includeInEdgeFocus,
      isTrue,
    );
  });

  testWidgets('в группе карточки вправо — тумблер, вниз — следующая карточка',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var card = 0;
    var sw = 0;
    var next = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: Column(
                children: [
                  GamepadNavGroup(
                    name: 'settings-iso',
                    child: Column(
                      children: [
                        GamepadFocusBlock(
                          radius: 20,
                          onActivate: () => card++,
                          child: const SizedBox(
                            width: 280,
                            height: 80,
                            child: Text('iso-card'),
                          ),
                        ),
                        GamepadFocusBlock(
                          includeInEdgeFocus: false,
                          radius: 18,
                          onActivate: () => sw++,
                          child: const SizedBox(
                            width: 48,
                            height: 32,
                            child: Text('iso-switch'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GamepadNavGroup(
                    name: 'settings-iso-next',
                    child: GamepadFocusBlock(
                      radius: 20,
                      onActivate: () => next++,
                      child: const SizedBox(
                        width: 280,
                        height: 80,
                        child: Text('iso-next'),
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
    expect(
      GamepadFocusBlock.maybeOf(tester.element(find.text('iso-card')))
          ?.focusNode
          .hasFocus,
      isTrue,
    );

    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(sw, 1);
    expect(card, 0);

    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(next, 1);
  });
}

Future<void> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  GamepadService.instance.start();
  GamepadService.instance.setDevicesForTest(const [
    GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GamepadHost(child: SettingsScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

bool _blockFocused(WidgetTester tester, Finder inner) {
  if (inner.evaluate().isEmpty) return false;
  return GamepadFocusBlock.maybeOf(tester.element(inner))?.focusNode.hasFocus ==
      true;
}

void _pad(WidgetTester tester, GamepadAction action) {
  handleGamepadUiAction(tester.element(find.byType(SettingsScreen)), action);
}
