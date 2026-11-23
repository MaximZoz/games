import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/framework/game_opponent_panel.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/uno_game_screen.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_locale.dart';

class _EmptyShop extends ShopRepository {
  _EmptyShop() : super(AuthRepository());

  @override
  Future<List<InventoryItem>> listCollectionsShowcase(String userId) async =>
      const [];
}

class _FixedUnoGame extends UnoGameNotifier {
  _FixedUnoGame(this.view);

  final UnoGameView view;

  @override
  Future<UnoGameView> build(String arg) async => view;
}

// Префикс offline — экран не ходит в сеть; саму партию отдаёт провайдер ниже.
const _gameId = 'offline:uno:chrome-test';

/// Партия на троих (или [players]); ходит место [current].
/// [deadline] == 0 — без лимита.
UnoGameView _view({required int current, int deadline = 0, int players = 3}) {
  final ids = ['user-1', 'user-2', 'user-3'].take(players).toList();
  return UnoGameView.fromJson({
    'id': _gameId,
    'status': 'active',
    'players': [
      for (var i = 0; i < ids.length; i++)
        {
          'user_id': ids[i],
          'display_name': 'player${i + 1}',
          'seat': i,
          'hand_count': 2,
          'score': i * 15,
          if (i == 0)
            'hand': [
              {'id': 'c1', 'color': 'red', 'kind': 'number', 'number': 3},
              {'id': 'c2', 'color': 'blue', 'kind': 'number', 'number': 7},
            ],
        },
    ],
    'top_discard': {'id': 'd1', 'color': 'red', 'kind': 'number', 'number': 5},
    'draw_count': 40,
    'current_color': 'red',
    'direction': 1,
    'current_index': current,
    'current_user_id': ids[current],
    'my_index': 0,
    'round_number': 1,
    'turn_time_sec': deadline > 0 ? 60 : 0,
    'turn_deadline': deadline,
  });
}

int _deadlineIn(int seconds) =>
    DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + seconds;

Future<void> _pump(
  WidgetTester tester,
  UnoGameView view, {
  List<Override> overrides = const [],
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        unoGameProvider.overrideWith(() => _FixedUnoGame(view)),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const UnoGameScreen(gameId: _gameId),
      ),
    ),
  );
  await tester.pump();
  // Раздача: пока карты летят, рамка хода соперника стоит на паузе.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Снять экран, чтобы таймеры стола не пережили тест.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    TurnClockSfx.reset();
  });

  testWidgets('свой ход с лимитом: отсчёт в шапке перед правилами',
      (tester) async {
    await _pump(tester, _view(current: 0, deadline: _deadlineIn(30)));
    expect(tester.takeException(), isNull);

    final timer = tester.getRect(find.byType(GameTurnCountdown));
    final rules =
        tester.getRect(find.byKey(const ValueKey('game-chrome-rules')));
    expect(timer.right, lessThanOrEqualTo(rules.left));
    expect(rules.left - timer.right, lessThan(24));
    expect((timer.center.dy - rules.center.dy).abs(), lessThan(8));

    // Звук хода ведёт отсчёт шапки — отдельного сигнала в теле нет.
    expect(find.byType(MyTurnAlert), findsNothing);
    // Флаг «сдаться» — в общем столбике под правилами, как в остальных играх.
    final rail = tester.getRect(find.byKey(const ValueKey('game-chrome-rail')));
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(rail.top, greaterThanOrEqualTo(rules.bottom - 4));
    expect((rail.center.dx - rules.center.dx).abs(), lessThan(6));
    // Столбик не накрывает ни статус, ни места соперников.
    final flag = tester.getRect(find.byIcon(Icons.flag_outlined));
    for (final seat in tester.widgetList<GameActorHighlight>(
      find.byType(GameActorHighlight),
    )) {
      final rect = tester.getRect(find.byWidget(seat));
      expect(rect.overlaps(flag), isFalse, reason: 'место $rect под флагом');
    }
    final status = tester.getRect(find.byType(GameStatusWithReward));
    expect(status.overlaps(flag), isFalse);
    await _unmount(tester);
  });

  testWidgets('ход соперника: отсчёт в шапке скрыт, таймер — рамка его места',
      (tester) async {
    final deadline = _deadlineIn(30);
    await _pump(tester, _view(current: 1, deadline: deadline));
    expect(tester.takeException(), isNull);

    expect(find.byType(GameTurnCountdown), findsNothing);
    expect(
      find.byType(GameTurnCountdown, skipOffstage: false),
      findsOneWidget,
    );
    final seats = tester
        .widgetList<GameActorHighlight>(find.byType(GameActorHighlight))
        .toList();
    expect(seats, hasLength(2));
    final acting = seats.where((s) => s.isActing).toList();
    expect(acting, hasLength(1));
    expect(acting.single.turnDeadline, deadline);
    expect(acting.single.turnTimeSec, 60);
    expect(
      find.descendant(
        of: find.byWidget(acting.single),
        matching: find.text('player2'),
      ),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('тап по месту соперника открывает его профиль', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(
      tester,
      _view(current: 0),
      overrides: [
        profilePresenceProvider.overrideWith((ref, id) async => null),
        headToHeadProvider.overrideWith(
          (ref, id) async => HeadToHead(
            opponentId: id,
            displayName: 'player2',
            won: 0,
            drawn: 0,
            lost: 0,
          ),
        ),
        shopRepositoryProvider.overrideWith((ref) => _EmptyShop()),
      ],
    );
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);

    await tester.tap(find.text('player2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('player2'), findsNWidgets(2));
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('1×1: соперник в общей карточке, карты и счёт — под ней',
      (tester) async {
    for (final size in const [Size(390, 800), Size(800, 390), Size(1200, 800)]) {
      final deadline = _deadlineIn(30);
      await _pump(
        tester,
        _view(current: 1, deadline: deadline, players: 2),
        size: size,
      );
      expect(tester.takeException(), isNull, reason: '$size');

      final panel = find.byType(GameOpponentPanel);
      expect(panel, findsOneWidget, reason: '$size');
      final card = find.byType(GameOpponentCard);
      expect(
        find.descendant(of: card, matching: find.text('player2')),
        findsOneWidget,
      );
      // В карточке только соперник: ни карт, ни счёта.
      for (final gameInfo in [
        find.byType(UnoCardBackWidget),
        find.text('Карт: 2'),
        find.text('Очки: 15'),
      ]) {
        expect(
          find.descendant(of: card, matching: gameInfo),
          findsNothing,
          reason: '$size',
        );
      }
      final tally = find.byType(UnoOpponentTally);
      expect(tally, findsOneWidget);
      expect(
        find.descendant(of: tally, matching: find.text('Карт: 2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tally, matching: find.text('Очки: 15')),
        findsOneWidget,
      );
      // Рамка карточки — таймер его хода; старой плашки места нет.
      expect(find.byType(UnoOpponentHand), findsNothing);
      final frame = tester.widget<TurnTimerBorder>(
        find.byKey(const ValueKey('game-opponent-frame')),
      );
      expect(frame.active, isTrue);
      expect(frame.turnDeadline, deadline);
      // Карточка и рука целиком на экране и не под столбиком действий.
      final screen = Offset.zero & size;
      final cardRect = tester.getRect(card);
      final tallyRect = tester.getRect(tally);
      expect(screen.contains(cardRect.topLeft), isTrue, reason: '$size');
      expect(screen.contains(cardRect.bottomRight), isTrue, reason: '$size');
      expect(screen.contains(tallyRect.topLeft), isTrue, reason: '$size');
      expect(screen.contains(tallyRect.bottomRight), isTrue, reason: '$size');
      final flag = tester.getRect(
        find.widgetWithIcon(IconButton, Icons.flag_outlined),
      );
      expect(cardRect.overlaps(flag), isFalse, reason: '$size');
      await _unmount(tester);
    }
  });

  testWidgets('на троих места за столом остаются со своими значками',
      (tester) async {
    await _pump(tester, _view(current: 0));
    expect(find.byType(GameOpponentPanel), findsNothing);
    expect(find.byType(UnoOpponentTally), findsNothing);
    expect(find.byType(UnoOpponentHand), findsNWidgets(2));
    await _unmount(tester);
  });

  testWidgets('без лимита времени о своём ходе сообщает один сигнал каркаса',
      (tester) async {
    await _pump(tester, _view(current: 0));
    expect(tester.takeException(), isNull);

    expect(find.byType(GameTurnCountdown, skipOffstage: false), findsNothing);
    final alert = tester.widget<MyTurnAlert>(find.byType(MyTurnAlert));
    expect(alert.isMyTurn, isTrue);
    await _unmount(tester);
  });

  testWidgets('офлайн-уно: флаг под правилами сдаёт партию', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = OfflineUnoSession.create(humanUserId: 'local:player');
    addTearDown(OfflineUnoRegistry.instance.disposeAll);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UnoGameScreen(gameId: session.gameId),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final flag = find.descendant(
      of: find.byKey(const ValueKey('game-chrome-rail')),
      matching: find.byIcon(Icons.flag_outlined),
    );
    expect(flag, findsOneWidget);
    await tester.tap(flag);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Сдаться'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(session.view.isOver, isTrue);
    expect(session.view.iWon, isFalse);
    expect(find.byKey(const ValueKey('game-chrome-rail')), findsNothing);
    expect(tester.takeException(), isNull);
    OfflineUnoRegistry.instance.disposeAll();
    await _unmount(tester);
  });
}
