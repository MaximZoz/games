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
    expect(_focusedKey(tester, 'settings-language-card'), isTrue);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .any((paint) => paint.painter is GamepadFocusOutlinePainter),
      isTrue,
    );

    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-sound-card'), isTrue);
    expect(_focusedKey(tester, 'settings-sound-switch'), isFalse);
  });

  testWidgets('вправо с карточки звука — тумблер, затем чекбокс',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-sound-card'), isTrue);

    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-sound-switch'), isTrue);

    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-sound-games'), isTrue);

    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(
              of: find.byKey(const ValueKey('settings-sound-games')),
              matching: find.byType(Checkbox),
            ),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('вправо с языка не прыгает на тумблер звука', (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-language-card'), isTrue);
    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    expect(_focusedKey(tester, 'settings-language-card'), isTrue);
    expect(_focusedKey(tester, 'settings-sound-switch'), isFalse);
  });

  testWidgets('A на языке открывает список, A выбирает, B закрывает',
      (tester) async {
    await _pumpSettings(tester);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-system')), findsOneWidget);
    expect(find.byKey(const ValueKey('lang-en')), findsOneWidget);

    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-system')), findsNothing);
    expect(find.text('Как в системе'), findsOneWidget);

    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-en')), findsOneWidget);
    final english = GamepadFocusBlock.maybeOf(
      tester.element(find.byKey(const ValueKey('lang-en'))),
    );
    english!.focusNode.requestFocus();
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-en')), findsNothing);
    expect(find.text('English'), findsOneWidget);
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
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-system')), findsOneWidget);
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(
      GamepadFocusBlock.maybeOf(
        tester.element(find.byKey(const ValueKey('lang-system'))),
      )?.focusNode.hasFocus,
      isTrue,
    );

    GamepadService.instance.emit(GamepadAction.scrollDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();
    await tester.pump();
    final system = GamepadFocusBlock.maybeOf(
      tester.element(find.byKey(const ValueKey('lang-system'))),
    );
    expect(system?.focusNode.hasFocus, isFalse);
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

bool _focusedKey(WidgetTester tester, String key) {
  final found = find.byKey(ValueKey(key));
  if (found.evaluate().isEmpty) return false;
  return GamepadFocusBlock.maybeOf(tester.element(found))?.focusNode.hasFocus ==
      true;
}
