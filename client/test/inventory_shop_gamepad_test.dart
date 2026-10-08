import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/shop_section_help.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
    GamepadFocusRegistry.reset();
  });

  testWidgets('вправо с названия коллекции — подарить, затем продать',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var opened = 0;
    var gifted = 0;
    var sold = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: GamepadNavGroup(
                name: 'inv-col-test',
                child: Row(
                  children: [
                    GamepadFocusBlock(
                      radius: 12,
                      onActivate: () => opened++,
                      child: const SizedBox(
                        width: 160,
                        height: 48,
                        child: Text('col-name'),
                      ),
                    ),
                    GamepadFocusBlock(
                      radius: 20,
                      onActivate: () => gifted++,
                      child: IconButton(
                        tooltip: 'Подарить',
                        onPressed: () => gifted++,
                        icon: const Icon(Icons.card_giftcard_outlined),
                      ),
                    ),
                    GamepadFocusBlock(
                      radius: 20,
                      onActivate: () => sold++,
                      child: IconButton(
                        tooltip: 'Продать',
                        onPressed: () => sold++,
                        icon: const Icon(Icons.sell_outlined),
                      ),
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
    expect(
      GamepadFocusBlock.maybeOf(tester.element(find.text('col-name')))
          ?.focusNode
          .hasFocus,
      isTrue,
    );

    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(gifted, 1);
    expect(opened, 0);

    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump();
    expect(sold, 1);
  });

  testWidgets('влево/вправо с блока магазина попадает на инфо', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var help = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              appBar: AppBar(
                actions: const [
                  ShopSectionHelpButton(
                    title: 'Коллекции',
                    body: 'справка',
                  ),
                ],
              ),
              body: GamepadFocusBlock(
                radius: 16,
                onActivate: () {},
                child: const SizedBox(
                  width: 220,
                  height: 80,
                  child: Text('shop-block'),
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
    await tester.pumpAndSettle();
    expect(find.text('справка'), findsOneWidget);
    help++;
    expect(help, 1);
  });

  testWidgets('всплышка куплено закрывается кнопкой', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showGamepadOwnedDialog(
                      context: context,
                      message: 'Эликсир',
                    );
                  },
                  child: const Text('buy'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buy'));
    await tester.pumpAndSettle();
    expect(find.text('Куплено'), findsOneWidget);
    expect(find.text('Эликсир'), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pumpAndSettle();
    expect(find.text('Куплено'), findsNothing);
  });
}
