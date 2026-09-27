import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_layout_toggle.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_locale.dart';

NardyGameView _view(NardyEngine engine) {
  final myTurn = !engine.isOver && engine.turn == 0;
  return NardyGameView(
    id: 'g',
    lobbyId: '',
    gameMode: engine.mode,
    board: engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: engine.dice,
    rolled: engine.rolled,
    turn: engine.turn,
    turnNo: engine.turnNo,
    seq: engine.seq,
    headMoved: engine.headMoved,
    players: [
      NardyPlayerView(
        userId: 'me',
        seat: 0,
        displayName: 'Я',
        off: engine.off[0],
        bar: engine.bar[0],
        pips: engine.pips(0),
      ),
      NardyPlayerView(
        userId: 'bot:nardy',
        seat: 1,
        displayName: 'Bot',
        off: engine.off[1],
        bar: engine.bar[1],
        pips: engine.pips(1),
        isBot: true,
        avatarValue: 'B',
      ),
    ],
    playerIds: const ['me', 'bot:nardy'],
    legalMoves: myTurn ? engine.legalMoves() : const [],
    myIndex: 0,
    isMyTurn: myTurn,
    needsRoll: myTurn && engine.dice.isEmpty && !engine.canUndo,
    canUndo: myTurn && engine.canUndo,
    turnComplete: myTurn && engine.turnComplete,
    currentTurn: myTurn ? engine.currentTurn : const [],
    lastTurn: engine.lastTurn,
    lastTurnSeat: engine.lastTurnSeat,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: 0,
    isOver: engine.isOver,
    winnerIndex: engine.winner,
    winnerUserId: '',
    winKind: engine.winKind,
  );
}

Widget _harness({
  required NardyGameView game,
  required NardyCheckerTracker tracker,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: const Color(0xFFE8ECF4),
        body: Center(
          child: SizedBox(
            width: 640,
            height: 500,
            child: Consumer(
              builder: (context, ref, _) {
                final mine = game.me!;
                final opp = game.opponent!;
                return Column(
                  children: [
                    SizedBox(
                      width: 640,
                      child: Row(
                        children: [
                          Expanded(
                            child: NardyPipsBar(
                              myPips: mine.pips,
                              oppPips: opp.pips,
                              myTurn: game.isMyTurn,
                              isOver: game.isOver,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const NardyLayoutToggleButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: NardyBoard(
                        game: game,
                        tracker: tracker,
                        selectedTrack: null,
                        targetTracks: const {},
                        canBearOff: false,
                        undoTracks: const {},
                        homeOnRight: ref.watch(nardyHomeOnRightProvider),
                        onTrackTap: (_) {},
                        onBarTap: () {},
                        onBearOffTap: () {},
                        canDragFrom: (_) => false,
                        onDragStart: (_) {},
                        onDragEnd: (_) {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Offset _firstChecker() {
  final widget = find.byType(AnimatedPositioned).evaluate().first.widget
      as AnimatedPositioned;
  return Offset(widget.left ?? 0, widget.top ?? 0);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(NardyBoard.moveDuration);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    setUpTestLocaleRu();
    SharedPreferences.setMockInitialValues({});
  });

  for (final mode in [nardyModeShort, nardyModeLong]) {
    testWidgets('кнопка зеркалит раскладку ($mode)', (tester) async {
      final engine = NardyEngine.newGame(mode);
      final tracker = NardyCheckerTracker();
      await tester.pumpWidget(_harness(game: _view(engine), tracker: tracker));
      await _pumpFrames(tester);

      expect(find.byTooltip('Поменять раскладку'), findsOneWidget);
      expect(find.byType(NardyLayoutToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

      final before = _firstChecker();

      await tester.tap(find.byType(NardyLayoutToggleButton));
      await _pumpFrames(tester);

      final after = _firstChecker();
      expect(after.dx, isNot(closeTo(before.dx, 1)));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nardy_home_on_right'), isTrue);
    });
  }
}
