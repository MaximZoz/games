import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/battleship_game_screen.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

import 'test_locale.dart';

const _railKey = ValueKey('game-chrome-rail');
const _rulesKey = ValueKey('game-chrome-rules');
const _timerKey = ValueKey('game-chrome-timer');

const _sizes = <String, Size>{
  'phone portrait': Size(360, 740),
  'phone landscape': Size(740, 360),
  'desktop': Size(1200, 800),
};

int _deadlineIn(int seconds) =>
    DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + seconds;

class _Auth extends AuthStateNotifier {
  _Auth(super.ref) {
    state = AsyncValue.data(AuthUser(id: 'me', email: 'me@test.com'));
  }
}

class _NoActiveGame extends ActiveGameNotifier {
  @override
  Future<ActiveGameItem?> build() async => null;

  @override
  Future<ActiveGameItem?> refresh() async => state.valueOrNull;
}

class _FixedTtt extends GameStateNotifier {
  _FixedTtt(this.item);

  final GameStateItem item;

  @override
  Future<GameStateItem> build(String arg) async => item;

  @override
  Future<void> reconcile() async {}
}

class _FixedBattleship extends BattleshipGameNotifier {
  _FixedBattleship(this.item);

  final BattleshipGameView item;

  @override
  Future<BattleshipGameView> build(String arg) async => item;

  @override
  Future<void> reconcile() async {}
}

GameStateItem _ttt({
  required String turn,
  int players = 2,
  int secondsLeft = 40,
}) =>
    GameStateItem(
      id: 'g1',
      board: List.filled(players > 2 ? 64 : 9, ''),
      gridSize: players > 2 ? 8 : 3,
      turn: turn,
      status: 'active',
      turnTimeSec: 60,
      turnDeadline: _deadlineIn(secondsLeft),
      maxPlayers: players,
      xUserId: 'me',
      oUserId: 'opp',
      tUserId: players > 2 ? 'third' : '',
      sUserId: players > 3 ? 'fourth' : '',
      xDisplayName: 'Me',
      oDisplayName: 'VeryLongOpponentDisplayName12345',
      tDisplayName: 'Third player',
      sDisplayName: 'Fourth player',
      chatId: players > 2 ? 'chat1' : null,
      stakeBronze: 2,
    );

BattleshipGameView _battleship({
  required String phase,
  required String turn,
  int secondsLeft = 40,
}) =>
    BattleshipGameView(
      id: 'b1',
      status: 'active',
      phase: phase,
      lobbyId: 'l1',
      p1UserId: 'me',
      p2UserId: 'opp',
      p1Ready: phase == 'battle',
      p2Ready: phase == 'battle',
      myShips: const [],
      myShots: const [],
      myHits: const [],
      opponentShots: const [],
      opponentShipsHit: const [],
      opponentSunkShips: const [],
      opponentShips: const [],
      isMyTurn: turn == 'me',
      turn: phase == 'battle' ? turn : '',
      turnTimeSec: 60,
      turnDeadline: phase == 'battle' ? _deadlineIn(secondsLeft) : 0,
      setupDeadline: phase == 'setup' ? _deadlineIn(50) : 0,
      setupSecondsLeft: phase == 'setup' ? 50 : 0,
      stakeBronze: 2,
      p1DisplayName: 'Me',
      p2DisplayName: 'VeryLongOpponentDisplayName12345',
    );

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  Size size, {
  GameStateItem? ttt,
  BattleshipGameView? battleship,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => _Auth(ref)),
        activeGameProvider.overrideWith(_NoActiveGame.new),
        realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
        chatsListProvider
            .overrideWith((ref) => Stream.value(const <ChatPreviewItem>[])),
        friendsSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            FriendsSnapshot(friends: [], incoming: [], outgoing: []),
          ),
        ),
        if (ttt != null) gameStateProvider.overrideWith(() => _FixedTtt(ttt)),
        if (battleship != null)
          battleshipGameProvider
              .overrideWith(() => _FixedBattleship(battleship)),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

GameActionsOverlay _rail(WidgetTester tester) {
  // Столбик действий один и живёт в хроме, а не в теле экрана.
  expect(find.byType(GameActionsOverlay), findsOneWidget);
  return tester.widget<GameActionsOverlay>(find.byKey(_railKey));
}

void _expectOpponentCardClearOfRail(WidgetTester tester) {
  final card = tester.getRect(find.byType(GameOpponentCard));
  final rail = tester.getRect(find.byKey(_railKey));
  expect(card.overlaps(rail), isFalse, reason: 'card $card, rail $rail');
}

void _expectTimerBeforeRules(WidgetTester tester, {required bool visible}) {
  final timer = find.byKey(_timerKey);
  expect(timer, findsOneWidget);
  expect(tester.widget<AnimatedOpacity>(timer).opacity, visible ? 1 : 0);
  // Обратный отсчёт остался только в шапке; в чужой ход он скрыт, но жив.
  expect(
    find.byType(GameTurnCountdown, skipOffstage: false),
    findsOneWidget,
  );
  if (!visible) return;
  final clock = tester.getRect(find.byType(GameTurnCountdown));
  final rules = tester.getRect(find.byKey(_rulesKey));
  expect(clock.right, lessThanOrEqualTo(rules.left));
  expect(rules.left - clock.right, lessThan(24));
  expect(clock.center.dy, closeTo(rules.center.dy, 12));
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    TurnClockSfx.reset();
  });

  for (final size in _sizes.entries) {
    group('tic-tac-toe, ${size.key}', () {
      testWidgets('1v1 on my turn: timer by the rules, rail with draw',
          (tester) async {
        await _pump(
          tester,
          const TicTacToeGameScreen(gameId: 'g1'),
          size.value,
          ttt: _ttt(turn: 'x'),
        );
        expect(tester.takeException(), isNull);

        final rail = _rail(tester);
        expect(rail.canSurrender, isTrue);
        expect(rail.canDraw, isTrue);
        _expectTimerBeforeRules(tester, visible: true);
        _expectOpponentCardClearOfRail(tester);
        await _unmount(tester);
      });

      testWidgets('1v1 on the opponent turn: timer moves to the card frame',
          (tester) async {
        await _pump(
          tester,
          const TicTacToeGameScreen(gameId: 'g1'),
          size.value,
          ttt: _ttt(turn: 'o'),
        );
        expect(tester.takeException(), isNull);

        _expectTimerBeforeRules(tester, visible: false);
        final frame = tester.widget<TurnTimerBorder>(
          find.byKey(const ValueKey('game-opponent-frame')),
        );
        expect(frame.active, isTrue);
        expect(frame.turnTimeSec, 60);
        _expectOpponentCardClearOfRail(tester);
        await _unmount(tester);
      });

      testWidgets('4 players: surrender in the rail, acting seat highlighted',
          (tester) async {
        await _pump(
          tester,
          const TicTacToeGameScreen(gameId: 'g1'),
          size.value,
          ttt: _ttt(turn: 'o', players: 4),
        );
        expect(tester.takeException(), isNull);

        final rail = _rail(tester);
        expect(rail.canSurrender, isTrue);
        expect(rail.canDraw, isFalse);
        final acting = tester
            .widgetList<GameActorHighlight>(find.byType(GameActorHighlight))
            .where((h) => h.isActing)
            .toList();
        expect(acting, hasLength(1));
        expect(acting.single.turnTimeSec, 60);
        await _unmount(tester);
      });
    });

    group('battleship, ${size.key}', () {
      testWidgets('setup: header shows the placement deadline, no draw',
          (tester) async {
        await _pump(
          tester,
          const BattleshipGameScreen(gameId: 'b1'),
          size.value,
          battleship: _battleship(phase: 'setup', turn: 'opp'),
        );
        expect(tester.takeException(), isNull);

        final rail = _rail(tester);
        expect(rail.canSurrender, isTrue);
        expect(rail.canDraw, isFalse);
        _expectTimerBeforeRules(tester, visible: true);
        _expectOpponentCardClearOfRail(tester);
        await _unmount(tester);
      });

      for (final turn in ['me', 'opp']) {
        testWidgets('battle, turn of $turn', (tester) async {
          await _pump(
            tester,
            const BattleshipGameScreen(gameId: 'b1'),
            size.value,
            battleship: _battleship(phase: 'battle', turn: turn),
          );
          expect(tester.takeException(), isNull);

          final rail = _rail(tester);
          expect(rail.canSurrender, isTrue);
          expect(rail.canDraw, isTrue);
          _expectTimerBeforeRules(tester, visible: turn == 'me');
          final frame = tester.widget<TurnTimerBorder>(
            find.byKey(const ValueKey('game-opponent-frame')),
          );
          expect(frame.active, turn == 'opp');
          _expectOpponentCardClearOfRail(tester);
          await _unmount(tester);
        });
      }
    });
  }

  testWidgets('tic-tac-toe survives an already expired opponent deadline',
      (tester) async {
    await _pump(
      tester,
      const TicTacToeGameScreen(gameId: 'g1'),
      const Size(360, 740),
      ttt: _ttt(turn: 'o', secondsLeft: -5),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('battleship survives an already expired opponent deadline',
      (tester) async {
    await _pump(
      tester,
      const BattleshipGameScreen(gameId: 'b1'),
      const Size(360, 740),
      battleship: _battleship(phase: 'battle', turn: 'opp', secondsLeft: -5),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });
}
