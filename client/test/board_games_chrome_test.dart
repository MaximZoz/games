import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/checkers/checkers_board.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_material.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/games/chess/chess_board.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/framework/game_opponent_panel.dart';
import 'package:multigames_client/games/framework/game_screen_scaffold.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_dice_widget.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_layout_toggle.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/checkers_game_screen.dart';
import 'package:multigames_client/screens/chess_game_screen.dart';
import 'package:multigames_client/screens/nardy_game_screen.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

import 'test_locale.dart';

// Префикс offline — экран не ходит в сеть; партию отдаёт провайдер ниже.
const _chessId = 'offline:chess:chrome-test';
const _checkersId = 'offline:checkers:chrome-test';
const _nardyId = 'offline:nardy:chrome-test';

// Без входа экран считает соперником первого в списке — он и стоит первым.
const _oppId = 'user-opp';
const _meId = 'user-me';
const _ids = [_oppId, _meId];
const _mySeat = 1;

const _phonePortrait = Size(360, 740);
const _phoneLandscape = Size(740, 360);
const _desktop = Size(1200, 800);
const _sizes = [_phonePortrait, _phoneLandscape, _desktop];

int _deadlineIn(int seconds) =>
    DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + seconds;

class _FixedChess extends ChessGameNotifier {
  _FixedChess(this.view, {this.onBuild});

  final ChessGameView view;
  final VoidCallback? onBuild;

  @override
  Future<ChessGameView> build(String arg) async {
    onBuild?.call();
    return view;
  }
}

class _FixedCheckers extends CheckersGameNotifier {
  _FixedCheckers(this.view);

  final CheckersGameView view;

  @override
  Future<CheckersGameView> build(String arg) async => view;
}

class _FixedNardy extends NardyGameNotifier {
  _FixedNardy(this.view);

  final NardyGameView view;

  @override
  Future<NardyGameView> build(String arg) async => view;
}

ChessGameView _chessView({
  required bool myTurn,
  bool over = false,
  int deadlineIn = 40,
}) {
  final engine = ChessEngine.newGame(chessModeRapid);
  final turn = myTurn ? _mySeat : 1 - _mySeat;
  return ChessGameView(
    id: _chessId,
    lobbyId: '',
    gameMode: chessModeRapid,
    board: List<int>.from(engine.board),
    turn: turn,
    seq: 1,
    inCheck: false,
    lastFromR: -1,
    lastFromC: -1,
    lastToR: -1,
    lastToC: -1,
    players: const [
      ChessPlayerView(userId: _oppId, seat: 0, displayName: 'Соперник'),
      ChessPlayerView(userId: _meId, seat: 1, displayName: 'Я'),
    ],
    playerIds: _ids,
    legalMoves: const [],
    myIndex: _mySeat,
    isMyTurn: myTurn && !over,
    turnTimeSec: 60,
    turnDeadline: over ? 0 : _deadlineIn(deadlineIn),
    stakeBronze: 0,
    isOver: over,
    winnerIndex: over ? _mySeat : -1,
    winnerUserId: over ? _meId : '',
    isDraw: false,
    hasClock: true,
    clockMs0: 600000,
    clockMs1: 600000,
    clockRunning: over ? -1 : turn,
  );
}

CheckersGameView _checkersView({required bool myTurn}) {
  final engine = CheckersEngine.newGame(CheckersEngine.modeRussian);
  return CheckersGameView(
    id: _checkersId,
    lobbyId: '',
    gameMode: CheckersEngine.modeRussian,
    board: List<int>.from(engine.board),
    turn: myTurn ? _mySeat : 1 - _mySeat,
    seq: 1,
    mustContinue: false,
    contR: -1,
    contC: -1,
    lastFromR: -1,
    lastFromC: -1,
    lastToR: -1,
    lastToC: -1,
    players: const [
      CheckersPlayerView(userId: _oppId, seat: 0, displayName: 'Соперник'),
      CheckersPlayerView(userId: _meId, seat: 1, displayName: 'Я'),
    ],
    playerIds: _ids,
    legalMoves: const [],
    myIndex: _mySeat,
    isMyTurn: myTurn,
    turnTimeSec: 60,
    turnDeadline: _deadlineIn(40),
    stakeBronze: 0,
    isOver: false,
    winnerIndex: -1,
    winnerUserId: '',
    isDraw: false,
  );
}

NardyGameView _nardyView({required bool myTurn}) {
  final engine = NardyEngine.newGame(nardyModeShort);
  return NardyGameView(
    id: _nardyId,
    lobbyId: '',
    gameMode: nardyModeShort,
    board: engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: const [3, 5],
    rolled: const [3, 5],
    turn: myTurn ? _mySeat : 1 - _mySeat,
    turnNo: 1,
    seq: 1,
    headMoved: 0,
    players: [
      NardyPlayerView(
        userId: _oppId,
        seat: 0,
        displayName: 'Соперник',
        off: 0,
        bar: 0,
        pips: engine.pips(0),
      ),
      NardyPlayerView(
        userId: _meId,
        seat: 1,
        displayName: 'Я',
        off: 0,
        bar: 0,
        pips: engine.pips(1),
      ),
    ],
    playerIds: _ids,
    // Ход есть — экран не завершает его сам и не зовёт репозиторий.
    legalMoves: myTurn ? const [NardyMove(0, 3)] : const [],
    myIndex: _mySeat,
    isMyTurn: myTurn,
    needsRoll: false,
    canUndo: false,
    turnComplete: false,
    currentTurn: const [],
    lastTurn: const [],
    lastTurnSeat: -1,
    turnTimeSec: 60,
    turnDeadline: _deadlineIn(40),
    stakeBronze: 0,
    isOver: false,
    winnerIndex: -1,
    winnerUserId: '',
    winKind: '',
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Widget screen,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      // Каждый размер и ход — свой экран, без состояния прошлого.
      key: UniqueKey(),
      overrides: [
        realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpChess(
  WidgetTester tester,
  Size size, {
  required bool myTurn,
  bool over = false,
}) =>
    _pump(
      tester,
      size: size,
      screen: const ChessGameScreen(gameId: _chessId),
      overrides: [
        chessGameProvider.overrideWith(
          () => _FixedChess(_chessView(myTurn: myTurn, over: over)),
        ),
      ],
    );

Future<void> _pumpCheckers(
  WidgetTester tester,
  Size size, {
  required bool myTurn,
}) =>
    _pump(
      tester,
      size: size,
      screen: const CheckersGameScreen(gameId: _checkersId),
      overrides: [
        checkersGameProvider.overrideWith(
          () => _FixedCheckers(_checkersView(myTurn: myTurn)),
        ),
      ],
    );

Future<void> _pumpNardy(
  WidgetTester tester,
  Size size, {
  required bool myTurn,
}) =>
    _pump(
      tester,
      size: size,
      screen: const NardyGameScreen(gameId: _nardyId),
      overrides: [
        nardyGameProvider.overrideWith(
          () => _FixedNardy(_nardyView(myTurn: myTurn)),
        ),
      ],
    );

/// Снять экран, чтобы таймеры хрома и часов не пережили тест.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

final _rules = find.byKey(const ValueKey('game-chrome-rules'));
final _rail = find.byKey(const ValueKey('game-chrome-rail'));
final _frame = find.byKey(const ValueKey('game-opponent-frame'));
final _flag = find.byIcon(Icons.flag_outlined);

Finder _inAppBar(Finder matching) =>
    find.descendant(of: find.byType(AppBar), matching: matching);

/// Общий хром: в шапке — таймер своего хода и правила, под правилами —
/// флаг и (если игра её предлагает) ничья.
void _expectChrome(
  WidgetTester tester, {
  required bool draw,
  bool myTurn = true,
}) {
  expect(find.byType(GameScreenScaffold), findsOneWidget);
  expect(find.byType(GameCloseButton), findsOneWidget);
  expect(_inAppBar(_flag), findsNothing);
  expect(_inAppBar(find.byType(DrawOfferButton)), findsNothing);

  // Таймер хода один на экран, живёт в шапке и виден только в мой ход.
  expect(find.byType(GameTurnCountdown, skipOffstage: false), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(GameTurnCountdown, skipOffstage: false),
      skipOffstage: false,
    ),
    findsOneWidget,
  );
  final rules = tester.getRect(_rules);
  if (myTurn) {
    final timer = tester.getRect(find.byType(GameTurnCountdown));
    expect(timer.right, lessThanOrEqualTo(rules.left));
    expect(rules.left - timer.right, lessThan(24));
  } else {
    expect(find.byType(GameTurnCountdown), findsNothing);
  }

  final flag = tester.getRect(_flag);
  expect(flag.top, greaterThanOrEqualTo(rules.bottom - 8));
  expect((flag.center.dx - rules.center.dx).abs(), lessThan(8));
  if (draw) {
    final handshake = tester.getRect(find.byType(DrawOfferButton));
    expect(handshake.top, greaterThanOrEqualTo(flag.bottom));
    expect((handshake.center.dx - rules.center.dx).abs(), lessThan(8));
  } else {
    expect(find.byType(DrawOfferButton), findsNothing);
  }
}

/// Ничто из тела партии не заходит под кнопки «сдаться / ничья».
///
/// Меряем по самим иконкам с полем вокруг: невидимая зона нажатия шире
/// полосы, которую хром отдаёт телу через `GameChromeScope`.
void _expectClearOfRail(WidgetTester tester, List<Finder> body, Size size) {
  final icons = find.descendant(of: _rail, matching: find.byType(Icon));
  final buttons = [
    for (var i = 0; i < icons.evaluate().length; i++)
      tester.getRect(icons.at(i)).inflate(6),
  ];
  expect(buttons, isNotEmpty);
  for (final finder in body) {
    final count = finder.evaluate().length;
    expect(count, greaterThan(0), reason: '$finder при $size');
    for (var i = 0; i < count; i++) {
      final rect = tester.getRect(finder.at(i));
      for (final button in buttons) {
        expect(
          rect.overlaps(button),
          isFalse,
          reason: '$finder $rect под кнопкой $button при $size',
        );
      }
    }
  }
}

TurnTimerBorder _opponentFrame(WidgetTester tester) =>
    tester.widget<TurnTimerBorder>(_frame);

void main() {
  setUp(() {
    setUpTestLocaleRu();
    TurnClockSfx.reset();
  });

  testWidgets('шахматы: общий хром, доска и часы не под столбиком действий',
      (tester) async {
    for (final size in _sizes) {
      await _pumpChess(tester, size, myTurn: true);
      expect(tester.takeException(), isNull, reason: '$size');
      _expectChrome(tester, draw: true);
      expect(find.byType(GameOpponentPanel), findsOneWidget);
      expect(_opponentFrame(tester).active, isFalse);
      // Шахматные часы остались у доски: соперника — сверху, мои — снизу.
      expect(find.byType(GameClock), findsNWidgets(2));
      _expectClearOfRail(
        tester,
        [
          find.byType(GameOpponentCard),
          find.byType(ChessBoard),
          find.byType(GameClock),
          find.byType(GameStatusWithReward),
          find.byType(GameReviewBar),
        ],
        size,
      );
    }
    await _unmount(tester);
  });

  testWidgets('шахматы: ход соперника — рамка карточки, таймер в шапке скрыт',
      (tester) async {
    await _pumpChess(tester, _phonePortrait, myTurn: false);
    final frame = _opponentFrame(tester);
    expect(frame.active, isTrue);
    expect(frame.turnTimeSec, 60);
    expect(frame.turnDeadline, greaterThan(0));
    expect(find.byType(GameTurnCountdown), findsNothing);
    expect(find.byType(GameTurnCountdown, skipOffstage: false), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('шахматы: после партии нет ни столбика, ни таймера хода',
      (tester) async {
    await _pumpChess(tester, _phonePortrait, myTurn: false, over: true);
    expect(tester.takeException(), isNull);
    expect(_rail, findsNothing);
    expect(find.byType(GameTurnCountdown, skipOffstage: false), findsNothing);
    expect(_opponentFrame(tester).active, isFalse);
    expect(_rules, findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('шахматы: вышло время соперника — партия перечитывается один раз',
      (tester) async {
    var builds = 0;
    await _pump(
      tester,
      size: _phonePortrait,
      screen: const ChessGameScreen(gameId: _chessId),
      overrides: [
        chessGameProvider.overrideWith(
          () => _FixedChess(
            _chessView(myTurn: false, deadlineIn: -5),
            onBuild: () => builds++,
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(_opponentFrame(tester).active, isTrue);
    // Первая загрузка и одно обновление по истёкшему дедлайну, без цикла.
    expect(builds, 2);
    await _unmount(tester);
  });

  testWidgets('шашки: общий хром, доска и статус не под столбиком действий',
      (tester) async {
    for (final size in _sizes) {
      await _pumpCheckers(tester, size, myTurn: true);
      expect(tester.takeException(), isNull, reason: '$size');
      _expectChrome(tester, draw: true);
      expect(find.byType(GameOpponentPanel), findsOneWidget);
      expect(_opponentFrame(tester).active, isFalse);
      _expectClearOfRail(
        tester,
        [
          find.byType(GameOpponentCard),
          find.byType(CheckersBoard),
          find.byType(CheckersMaterialLine),
          find.byType(GameStatusWithReward),
          find.byType(GameReviewBar),
        ],
        size,
      );
    }
    await _pumpCheckers(tester, _phonePortrait, myTurn: false);
    expect(_opponentFrame(tester).active, isTrue);
    expect(find.byType(GameTurnCountdown), findsNothing);
    await _unmount(tester);
  });

  testWidgets('нарды: общий хром без ничьей, доска не под флагом',
      (tester) async {
    await _pumpNardy(tester, _phonePortrait, myTurn: true);
    expect(tester.takeException(), isNull);
    _expectChrome(tester, draw: false);
    expect(_opponentFrame(tester).active, isFalse);

    // Ход соперника: в боковой колонке нет кнопок моего хода, а их подписи
    // тестовым шрифтом шире колонки.
    for (final size in _sizes) {
      await _pumpNardy(tester, size, myTurn: false);
      expect(tester.takeException(), isNull, reason: '$size');
      _expectChrome(tester, draw: false, myTurn: false);
      expect(find.byType(GameOpponentPanel), findsOneWidget);
      expect(_opponentFrame(tester).active, isTrue);
      _expectClearOfRail(
        tester,
        [
          find.byType(GameOpponentCard),
          find.byType(NardyBoard),
          find.byType(NardyPipsBar),
          find.byType(NardyLayoutToggleButton),
          find.byType(NardyDiceRow),
          find.byType(GameStatusWithReward),
        ],
        size,
      );
    }
    await _unmount(tester);
  });
}
