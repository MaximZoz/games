import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_dismiss.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_tab_sticks.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/games/games_gamepad.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
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
  });

  test('правый стик влево/вправо листает игры и лобби без круга', () {
    expect(gamesHubScrollSwitchesTab(GamepadAction.scrollRight), isTrue);
    expect(gamesHubScrollSwitchesTab(GamepadAction.scrollLeft), isTrue);
    expect(gamesHubScrollSwitchesTab(GamepadAction.scrollDown), isFalse);
    expect(
      gamesHubTabIndexAfterScroll(
        index: 0,
        length: 2,
        action: GamepadAction.scrollRight,
      ),
      1,
    );
    expect(
      gamesHubTabIndexAfterScroll(
        index: 1,
        length: 2,
        action: GamepadAction.scrollRight,
      ),
      1,
    );
    expect(
      gamesHubTabIndexAfterScroll(
        index: 0,
        length: 2,
        action: GamepadAction.scrollLeft,
      ),
      0,
    );
  });

  test('вверх/вниз правого стика листают карточки, не вкладки', () {
    expect(gamesHubScrollPagesCards(GamepadAction.scrollDown), isTrue);
    expect(gamesHubScrollPagesCards(GamepadAction.scrollUp), isTrue);
    expect(gamesHubScrollPagesCards(GamepadAction.scrollRight), isFalse);
  });

  test('попап не даёт стику листать вкладки игр', () {
    expect(
      gamesGamepadAllowsHubScroll(popupOpen: true, exclusive: false),
      isFalse,
    );
    expect(
      gamesGamepadAllowsHubScroll(popupOpen: false, exclusive: true),
      isFalse,
    );
    expect(
      gamesGamepadAllowsHubScroll(
        popupOpen: false,
        exclusive: false,
        routeCovered: true,
      ),
      isFalse,
    );
    expect(
      gamesGamepadAllowsHubScroll(popupOpen: false, exclusive: false),
      isTrue,
    );
  });

  testWidgets('без геймпада глифы правого стика на вкладках скрыты',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GamepadTabSticks(child: Text('вкладки')),
        ),
      ),
    );
    expect(find.text('вкладки'), findsOneWidget);
    expect(find.byType(GamepadGlyph), findsNothing);
  });

  testWidgets('после страницы фокус на якоре «Создать игру»', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: Column(
                children: [
                  GamepadFocusBlock(
                    radius: 10,
                    onActivate: () {},
                    child: const SizedBox(
                      width: 80,
                      height: 40,
                      child: Text('chip'),
                    ),
                  ),
                  GamepadFocusBlock(
                    radius: 12,
                    pageAnchor: true,
                    onActivate: () {},
                    child: const SizedBox(
                      width: 200,
                      height: 48,
                      child: Text('create'),
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
    final createScope =
        GamepadFocusBlock.maybeOf(tester.element(find.text('create')));
    expect(createScope, isNotNull);
    expect(createScope!.pageAnchor, isTrue);
    expect(createScope.focusNode.hasFocus, isTrue);
  });

  testWidgets('правила: стик не закрывает, кнопка закрывает', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var created = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    GamepadFocusBlock(
                      pageAnchor: true,
                      onActivate: () => created++,
                      child: const SizedBox(
                        width: 200,
                        height: 48,
                        child: Text('create-bg'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showGameRulesDialog(
                          context: context,
                          content: const SizedBox(
                            height: 800,
                            child: Text('rule-body'),
                          ),
                        );
                      },
                      child: const Text('open-rules'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-rules'));
    await tester.pumpAndSettle();
    expect(find.text('rule-body'), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.scrollDown);
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump();
    expect(find.text('rule-body'), findsOneWidget);
    expect(created, 0);
    final bg =
        GamepadFocusBlock.maybeOf(tester.element(find.text('create-bg')));
    expect(bg?.focusNode.hasFocus, isFalse);
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pumpAndSettle();
    expect(find.text('rule-body'), findsNothing);
    expect(created, 0);
  });

  test('страница карточек упирается в края и не крутится', () {
    expect(
      gamepadPageOffset(
        pixels: 0,
        minExtent: 0,
        maxExtent: 800,
        viewport: 400,
        direction: -1,
      ),
      isNull,
    );
    expect(
      gamepadPageOffset(
        pixels: 800,
        minExtent: 0,
        maxExtent: 800,
        viewport: 400,
        direction: 1,
      ),
      isNull,
    );
    expect(
      gamepadPageOffset(
        pixels: 0,
        minExtent: 0,
        maxExtent: 800,
        viewport: 400,
        direction: 1,
      ),
      400,
    );
    expect(
      gamepadPageOffset(
        pixels: 400,
        minExtent: 0,
        maxExtent: 800,
        viewport: 400,
        direction: -1,
      ),
      0,
    );
  });

  testWidgets(
      'правый стик листает карточки экраном и фокусирует создать на новой странице',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late ScrollController controller;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamepadHost(
            child: Scaffold(
              body: GamepadScrollPager(
                builder: (context, scrollController) {
                  controller = scrollController;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final page = constraints.maxHeight;
                      return ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        cacheExtent: page * 4,
                        children: [
                          for (var i = 0; i < 4; i++)
                            SizedBox(
                              height: page,
                              child: GamepadFocusBlock(
                                pageAnchor: true,
                                onActivate: () {},
                                child: Text('create-$i'),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusFirstVisibleGamepadTarget(), isTrue);
    await tester.pump();
    expect(
      GamepadFocusBlock.maybeOf(tester.element(find.text('create-0')))
          ?.focusNode
          .hasFocus,
      isTrue,
    );
    expect(controller.offset, 0);
    final viewport = controller.position.viewportDimension;
    final maxExtent = controller.position.maxScrollExtent;
    expect(viewport, greaterThan(0));
    expect(maxExtent, closeTo(viewport * 3, 1));

    Future<void> pageStick(int direction) async {
      expect(scrollGamepadByPage(direction), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpAndSettle();
    }

    bool createFocused(int index) {
      final found = find.text('create-$index');
      if (found.evaluate().isEmpty) return false;
      return GamepadFocusBlock.maybeOf(tester.element(found))
              ?.focusNode
              .hasFocus ==
          true;
    }

    await pageStick(1);
    expect(controller.offset, closeTo(viewport, 1));
    expect(createFocused(1), isTrue);

    await pageStick(1);
    expect(controller.offset, closeTo(viewport * 2, 1));
    expect(createFocused(2), isTrue);

    await pageStick(1);
    expect(controller.offset, closeTo(maxExtent, 1));
    expect(createFocused(3), isTrue);

    expect(scrollGamepadByPage(1), isFalse);
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(maxExtent, 1));
    expect(createFocused(3), isTrue);

    await pageStick(-1);
    expect(controller.offset, closeTo(viewport * 2, 1));
    expect(createFocused(2), isTrue);

    await pageStick(-1);
    await pageStick(-1);
    expect(controller.offset, 0);
    expect(createFocused(0), isTrue);
  });

  test('кнопка закрывает правила, стик — нет', () {
    expect(gamepadScrollDismissCloses(GamepadAction.confirm), isTrue);
    expect(gamepadScrollDismissCloses(GamepadAction.cancel), isTrue);
    expect(gamepadScrollDismissCloses(GamepadAction.actionX), isTrue);
    expect(gamepadScrollDismissCloses(GamepadAction.scrollDown), isFalse);
    expect(gamepadScrollDismissCloses(GamepadAction.down), isFalse);
  });
}
