import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_repository.dart';
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
  });

  testWidgets('игры стоят в одной горизонтальной полосе без заголовка',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: HeadToHeadScoreStrip(
            games: const [
              GameTypeScore(gameType: 'durak', won: 2, lost: 1, drawn: 0),
              GameTypeScore(gameType: 'uno', won: 1, lost: 3, drawn: 1),
              GameTypeScore(gameType: 'poker', won: 4, lost: 0, drawn: 2),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ваш счёт'), findsNothing);
    expect(find.byType(GameTypeScoreChip), findsNWidgets(3));
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
  });

  testWidgets('коллекции в витрине получают рамку геймпада', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: const Scaffold(
          body: CollectionShowcaseGrid(
            items: [
              InventoryItem(
                code: 'coll_a',
                kind: 'collection',
                title: 'А',
                description: '',
                payload: {'emoji': '🔥', 'animated_name': 'sparkles'},
              ),
              InventoryItem(
                code: 'coll_b',
                kind: 'collection',
                title: 'Б',
                description: '',
                payload: {'emoji': '💎', 'animated_name': 'sparkles'},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(GamepadFocusBlock), findsNWidgets(2));
    expect(find.byType(GamepadNavGroup), findsOneWidget);
  });

  testWidgets('во exclusive-попапе стик с шапки доходит до коллекции',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return GamepadScope(
                  exclusive: true,
                  onAction: (action) {
                    if (action.isDirection || action == GamepadAction.confirm) {
                      return handleGamepadUiAction(context, action);
                    }
                    return true;
                  },
                  child: GamepadNavGroup(
                    name: 'user-profile-popup',
                    exclusive: true,
                    child: Scaffold(
                      body: Column(
                        children: [
                          GamepadFocusBlock(
                            autofocus: true,
                            onActivate: () {},
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Text('шапка'),
                            ),
                          ),
                          const CollectionShowcaseGrid(
                            items: [
                              InventoryItem(
                                code: 'coll_a',
                                kind: 'collection',
                                title: 'А',
                                description: '',
                                payload: {
                                  'emoji': '🔥',
                                  'animated_name': 'sparkles',
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    final collectionBlock = find.descendant(
      of: find.byType(CollectionShowcaseGrid),
      matching: find.byType(GamepadFocusBlock),
    );
    expect(collectionBlock, findsOneWidget);
    expect(
      GamepadFocusBlock.maybeOf(tester.element(collectionBlock))
          ?.focusNode
          .hasFocus,
      isTrue,
    );
  });
}
