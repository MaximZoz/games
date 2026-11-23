import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/framework/game_chrome.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem;
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

import 'test_locale.dart';

int _deadlineIn(int seconds) =>
    DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + seconds;

Future<void> _pump(
  WidgetTester tester,
  GameChrome chrome, {
  Widget body = const SizedBox.expand(),
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreenScaffold(chrome: chrome, body: body),
      ),
    ),
  );
  await tester.pump();
}

/// Снять экран, чтобы таймеры хрома не пережили тест.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    TurnClockSfx.reset();
  });

  testWidgets('столбик на тёмном сукне рисует флаг светлым', (tester) async {
    await _pump(
      tester,
      GameChrome(onClose: () {}, onShowRules: () {}, onSurrender: () {}),
    );
    expect(_flagColor(tester), isNot(GamePalette.feltInk));

    await _pump(
      tester,
      GameChrome(
        onClose: () {},
        onShowRules: () {},
        onSurrender: () {},
        railOnDark: true,
      ),
    );
    expect(_flagColor(tester), GamePalette.feltInk);
    await _unmount(tester);
  });

  testWidgets('таймер своего хода стоит перед правилами, ниже — флаг и ничья',
      (tester) async {
    await _pump(
      tester,
      GameChrome(
        onClose: () {},
        onShowRules: () {},
        title: const Text('Игра'),
        turn: GameTurnClock(
          isMyTurn: true,
          deadline: _deadlineIn(30),
          turnTimeSec: 60,
        ),
        onSurrender: () {},
        draw: GameDrawOffer(onPressed: () {}),
      ),
    );

    final timer = tester.getRect(find.byType(GameTurnCountdown));
    final rules = tester.getRect(find.byKey(const ValueKey('game-chrome-rules')));
    final flag = tester.getRect(find.byIcon(Icons.flag_outlined));
    final draw = tester.getRect(find.byType(DrawOfferButton));

    // Таймер и правила — в одной строке шапки, таймер сразу левее.
    expect(timer.right, lessThanOrEqualTo(rules.left));
    expect(rules.left - timer.right, lessThan(24));
    expect((timer.center.dy - rules.center.dy).abs(), lessThan(8));
    // Под правилами столбиком: сдаться, затем ничья.
    expect(flag.top, greaterThanOrEqualTo(rules.bottom - 8));
    expect(draw.top, greaterThanOrEqualTo(flag.bottom));
    expect((flag.center.dx - rules.center.dx).abs(), lessThan(8));
    expect((draw.center.dx - rules.center.dx).abs(), lessThan(8));
    await _unmount(tester);
  });

  testWidgets('в чужой ход таймер в шапке скрыт, но остаётся в дереве',
      (tester) async {
    await _pump(
      tester,
      GameChrome(
        onClose: () {},
        onShowRules: () {},
        turn: GameTurnClock(
          isMyTurn: false,
          deadline: _deadlineIn(30),
          turnTimeSec: 60,
        ),
      ),
    );
    expect(find.byType(GameTurnCountdown), findsNothing);
    expect(
      find.byType(GameTurnCountdown, skipOffstage: false),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('без лимита времени таймера нет, о ходе сообщает звук',
      (tester) async {
    await _pump(
      tester,
      GameChrome(
        onClose: () {},
        onShowRules: () {},
        turn: const GameTurnClock(isMyTurn: true),
      ),
    );
    expect(find.byType(GameTurnCountdown, skipOffstage: false), findsNothing);
    expect(find.byType(MyTurnAlert), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('столбик действий сообщает телу свою ширину', (tester) async {
    double? inset;
    Widget probe() => Builder(
          builder: (context) {
            inset = GameChromeScope.railInsetOf(context);
            return const SizedBox.expand();
          },
        );

    await _pump(
      tester,
      GameChrome(onClose: () {}, onShowRules: () {}),
      body: probe(),
    );
    expect(inset, 0);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);

    await _pump(
      tester,
      GameChrome(onClose: () {}, onShowRules: () {}, onSurrender: () {}),
      body: probe(),
    );
    expect(inset, GameScreenScaffold.railWidth);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    // Игра без ничьей рукопожатие не показывает.
    expect(find.byType(DrawOfferButton), findsNothing);
    await _unmount(tester);
  });

  testWidgets('кнопки хрома зовут колбэки игры', (tester) async {
    var closed = 0;
    var rules = 0;
    var surrendered = 0;
    var draws = 0;
    await _pump(
      tester,
      GameChrome(
        onClose: () => closed++,
        onShowRules: () => rules++,
        onSurrender: () => surrendered++,
        draw: GameDrawOffer(onPressed: () => draws++),
      ),
    );
    await tester.tap(find.byType(GameCloseButton));
    await tester.tap(find.byKey(const ValueKey('game-chrome-rules')));
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.tap(find.byType(DrawOfferButton));
    expect([closed, rules, surrendered, draws], [1, 1, 1, 1]);
    await _unmount(tester);
  });

  testWidgets('карточка соперника: рамка-таймер в его ход, у бота нет чата',
      (tester) async {
    Future<void> pumpPanel({required bool theirTurn}) => _pump(
          tester,
          GameChrome(onClose: () {}, onShowRules: () {}, onSurrender: () {}),
          body: Align(
            alignment: Alignment.topCenter,
            child: GameOpponentPanel(
              opponent: const GameOpponent(userId: 'bot:domino'),
              gameType: 'domino',
              gameId: 'g1',
              isTheirTurn: theirTurn,
              turnDeadline: _deadlineIn(20),
              turnTimeSec: 60,
            ),
          ),
        );

    await pumpPanel(theirTurn: true);
    final frame = tester.widget<TurnTimerBorder>(
      find.byKey(const ValueKey('game-opponent-frame')),
    );
    expect(frame.active, isTrue);
    expect(find.text('Бот'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);

    // Карточка не заходит под столбик «сдаться».
    final card = tester.getRect(find.byType(GameOpponentCard));
    final flag = tester.getRect(find.byIcon(Icons.flag_outlined));
    expect(card.right, lessThanOrEqualTo(flag.left));

    await pumpPanel(theirTurn: false);
    final idle = tester.widget<TurnTimerBorder>(
      find.byKey(const ValueKey('game-opponent-frame')),
    );
    expect(idle.active, isFalse);
    await _unmount(tester);
  });

  test('после выхода active не должен указывать на сыгранную партию', () {
    final game = ActiveGameItem(type: 'game', gameId: 'g1', gameType: 'domino');
    expect(activeStillPointsAtGame(game, 'g1'), isTrue);
    expect(activeStillPointsAtGame(game, ' g1 '), isTrue);
    expect(activeStillPointsAtGame(game, 'g2'), isFalse);
    expect(activeStillPointsAtGame(null, 'g1'), isFalse);
    final lobby = ActiveGameItem(type: 'lobby', lobbyId: 'g1');
    expect(activeStillPointsAtGame(lobby, 'g1'), isFalse);
  });

  testWidgets('выход из партии забывает стол: «Игры» открывают каталог',
      (tester) async {
    late WidgetRef ref;
    Future<void> pump(ActiveGameItem? active) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeGameProvider.overrideWith(() => _FixedActiveGame(active)),
          ],
          child: Consumer(
            builder: (context, widgetRef, _) {
              ref = widgetRef;
              widgetRef.watch(activeGameProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    }

    await pump(ActiveGameItem(type: 'game', gameId: 'g1', gameType: 'domino'));
    pinBlockingGame(ref, 'g1', gameType: 'domino');
    ref.read(lastGamesSessionPathProvider.notifier).state =
        '/games/domino/game/g1';
    expect(hasBlockingActiveMatch(ref.read(activeGameProvider).valueOrNull),
        isTrue);

    forgetGameSession(ref, gameId: 'g1');
    expect(ref.read(lastGamesSessionPathProvider), isNull);
    expect(ref.read(blockingGamePinProvider), isNull);
    expect(ref.read(activeGameProvider).valueOrNull, isNull);

    // Чужую партию выход из сыгранной не трогает.
    await pump(ActiveGameItem(type: 'game', gameId: 'g2', gameType: 'chess'));
    pinBlockingGame(ref, 'g2', gameType: 'chess');
    forgetGameSession(ref, gameId: 'g1');
    expect(ref.read(blockingGamePinProvider)?.gameId, 'g2');
    expect(ref.read(activeGameProvider).valueOrNull?.gameId, 'g2');
  });
}

Color? _flagColor(WidgetTester tester) {
  final glyph = tester.widget<RichText>(
    find.descendant(
      of: find.byKey(const ValueKey('game-chrome-rail')),
      matching: find.byType(RichText),
    ),
  );
  return glyph.text.style?.color;
}

class _FixedActiveGame extends ActiveGameNotifier {
  _FixedActiveGame(this.item);

  final ActiveGameItem? item;

  @override
  Future<ActiveGameItem?> build() async => item;

  @override
  Future<ActiveGameItem?> refresh() async => state.valueOrNull;
}
