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
import 'package:multigames_client/games/games_provider.dart';
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

  testWidgets('коллекции в узкой карточке переносятся и не обрезаются',
      (tester) async {
    const cardWidth = 330.0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: cardWidth,
              child: CollectionShowcaseGrid(
                items: [
                  InventoryItem(
                    code: 'coll_a',
                    kind: 'collection',
                    title: 'А',
                    description: '',
                    payload: {'emoji': '🤖', 'animated_name': 'sparkles'},
                  ),
                  InventoryItem(
                    code: 'coll_b',
                    kind: 'collection',
                    title: 'Б',
                    description: '',
                    payload: {'emoji': '🚀', 'animated_name': 'sparkles'},
                  ),
                  InventoryItem(
                    code: 'coll_c',
                    kind: 'collection',
                    title: 'В',
                    description: '',
                    payload: {'emoji': '🦋', 'animated_name': 'sparkles'},
                  ),
                  InventoryItem(
                    code: 'coll_d',
                    kind: 'collection',
                    title: 'Г',
                    description: '',
                    payload: {'emoji': '🦅', 'animated_name': 'sparkles'},
                  ),
                  InventoryItem(
                    code: 'coll_e',
                    kind: 'collection',
                    title: 'Д',
                    description: '',
                    payload: {'emoji': '🐙', 'animated_name': 'sparkles'},
                  ),
                  InventoryItem(
                    code: 'coll_f',
                    kind: 'collection',
                    title: 'Е',
                    description: '',
                    payload: {'emoji': '⛵', 'animated_name': 'sparkles'},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ListView), findsNothing);
    final tiles = find.byType(GamepadFocusBlock);
    expect(tiles, findsNWidgets(6));
    final wrapBox = tester.getRect(find.byType(Wrap));
    expect(wrapBox.width, lessThanOrEqualTo(cardWidth));
    final first = tester.getRect(tiles.first);
    final last = tester.getRect(tiles.last);
    expect(last.top, greaterThan(first.bottom - 1));
    expect(last.right, lessThanOrEqualTo(wrapBox.right + 0.1));
    expect(first.left, greaterThanOrEqualTo(wrapBox.left - 0.1));
    expect(tester.takeException(), isNull);
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
    focusFirstVisibleGamepadTarget();
    await tester.pump();
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    final focusedCtx = FocusManager.instance.primaryFocus?.context;
    expect(focusedCtx, isNotNull);
    expect(
      focusedCtx!.findAncestorWidgetOfExactType<CollectionShowcaseGrid>(),
      isNotNull,
    );
  });

  test('кнопка закрывает статистику, стик — нет', () {
    expect(statsPopupActionCloses(GamepadAction.confirm), isTrue);
    expect(statsPopupActionCloses(GamepadAction.cancel), isTrue);
    expect(statsPopupActionCloses(GamepadAction.actionX), isTrue);
    expect(statsPopupActionCloses(GamepadAction.menu), isTrue);
    expect(statsPopupActionCloses(GamepadAction.down), isFalse);
    expect(statsPopupActionCloses(GamepadAction.scrollUp), isFalse);
  });

  testWidgets('во всплывашке статистики A закрывает, стик не трогает крестик',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var closed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: StatsPopupGamepadScope(
              onClose: () => closed = true,
              child: Scaffold(
                body: ListView(
                  children: [
                    for (var i = 0; i < 20; i++)
                      SizedBox(height: 40, child: Text('строка $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(GamepadFocusBlock), findsNothing);
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    expect(closed, isFalse);
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump(const Duration(milliseconds: 40));
    expect(closed, isTrue);
  });

  testWidgets(
      'диалог статистики: крестик без рамки, стик скроллит, B закрывает',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const stats = GameStats(
      wins: 3,
      draws: 1,
      losses: 2,
      totalPlayed: 6,
      winRate: 0.5,
      totalDurationSec: 120,
      topWon: [],
      topDrawn: [],
      topLost: [],
      games: [
        GameTypeScore(gameType: 'durak', won: 2, lost: 1, drawn: 0),
        GameTypeScore(gameType: 'uno', won: 1, lost: 1, drawn: 1),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameStatsProvider.overrideWith((ref, userId) async => stats),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => showHeadToHeadStatsDialog(
                      context: context,
                      opponentId: 'opp',
                      title: 'Игрок',
                    ),
                    child: const Text('open-stats'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.close_rounded),
        matching: find.byType(GamepadFocusBlock),
      ),
      findsNothing,
    );

    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    GamepadService.instance.emit(GamepadAction.down);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(Dialog), findsOneWidget);
    GamepadService.instance.emit(GamepadAction.cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('стик в карточке профиля листает счёт, не вкладки друзей',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tabs = TabController(length: 2, vsync: const TestVSync());
    addTearDown(tabs.dispose);
    final games = [
      for (final type in const [
        'durak',
        'uno',
        'poker',
        'seka',
        'chess',
        'tictactoe',
        'domino',
        'bingo',
      ])
        GameTypeScore(gameType: type, won: 1, lost: 0, drawn: 0),
    ];
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
                  body: Column(
                    children: [
                      TabBar(
                        controller: tabs,
                        tabs: const [
                          Tab(text: 'Друзья'),
                          Tab(text: 'Найти друга'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabs,
                          children: [
                            Focus(
                              autofocus: true,
                              child: ListView(
                                children: const [
                                  SizedBox(height: 48, child: Text('друг')),
                                ],
                              ),
                            ),
                            const Center(child: Text('найти')),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) {
                              return GamepadScope(
                                exclusive: true,
                                onAction: (action) {
                                  if (action.isScroll) {
                                    scrollGamepadHorizontalStrip(
                                      action,
                                      context: dialogContext,
                                    );
                                    return true;
                                  }
                                  return true;
                                },
                                child: Dialog(
                                  child: SizedBox(
                                    width: 360,
                                    child: HeadToHeadScoreStrip(games: games),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Text('open-profile'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-profile'));
    await tester.pumpAndSettle();
    expect(find.byType(HeadToHeadScoreStrip), findsOneWidget);
    expect(tabs.index, 0);

    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    final strip = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(HeadToHeadScoreStrip),
        matching: find.byType(Scrollable),
      ),
    );
    final before = strip.position.pixels;
    GamepadService.instance.emit(GamepadAction.scrollRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tabs.index, 0);
    expect(find.text('найти'), findsNothing);
    expect(strip.position.pixels, greaterThan(before));
  });
}
