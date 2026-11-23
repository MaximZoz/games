import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_offline_session.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/domino/domino_table.dart';
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/domino_game_screen.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

import 'test_locale.dart';

DominoPlaced _tile(int lo, int hi, {String end = 'right'}) {
  return DominoPlaced(
    id: dominoTileId(lo, hi),
    lo: lo,
    hi: hi,
    inward: lo,
    outward: hi,
    end: end,
    isDouble: lo == hi,
  );
}

DominoPlaced _oriented(int inward, int outward, {String end = 'right'}) {
  final lo = inward <= outward ? inward : outward;
  final hi = inward <= outward ? outward : inward;
  return DominoPlaced(
    id: dominoTileId(lo, hi),
    lo: lo,
    hi: hi,
    inward: inward,
    outward: outward,
    end: end,
    isDouble: inward == outward,
  );
}

/// Число на половине, которой кость смотрит на соседа.
int _pipToward(
  DominoPlaced tile,
  DominoLayoutSlot self,
  Rect neighbor, {
  required bool upperLeadsRight,
}) {
  final halves = dominoHalfPips(tile, leadingOnRight: self.leadingOnRight);
  final dx = neighbor.center.dx - self.rect.center.dx;
  final dy = neighbor.center.dy - self.rect.center.dy;
  if (dx.abs() > dy.abs() + 4) return dx > 0 ? halves.right : halves.left;
  final leftMeet = (self.rect.left - neighbor.left).abs() < 2;
  final rightMeet = (self.rect.right - neighbor.right).abs() < 2;
  if (rightMeet && !leftMeet) return halves.right;
  if (leftMeet && !rightMeet) return halves.left;
  return upperLeadsRight ? halves.right : halves.left;
}

void _expectJoints(List<DominoPlaced> chain, double maxWidth) {
  final slots = layoutDominoChain(chain, maxWidth);
  expect(slots, hasLength(chain.length));
  var sawReturn = false;
  var sawThird = false;
  for (var i = 0; i < chain.length - 1; i++) {
    if (!slots[i].leadingOnRight) sawReturn = true;
    if (sawReturn && slots[i].leadingOnRight) sawThird = true;
    final upperLeadsRight = slots[i].rect.top <= slots[i + 1].rect.top
        ? slots[i].leadingOnRight
        : slots[i + 1].leadingOnRight;
    final mine = _pipToward(
      chain[i],
      slots[i],
      slots[i + 1].rect,
      upperLeadsRight: upperLeadsRight,
    );
    final theirs = _pipToward(
      chain[i + 1],
      slots[i + 1],
      slots[i].rect,
      upperLeadsRight: upperLeadsRight,
    );
    expect(mine, theirs, reason: 'стык $i: $mine и $theirs');
  }
  expect(sawReturn, isTrue, reason: 'ряд должен развернуться');
  expect(sawThird, isTrue, reason: 'третий ряд снова вправо');
}

Map<String, dynamic> _chainTile(int inward, int outward,
    {String end = 'start'}) {
  final lo = inward <= outward ? inward : outward;
  final hi = inward <= outward ? outward : inward;
  return {
    'id': dominoTileId(lo, hi),
    'lo': lo,
    'hi': hi,
    'inward': inward,
    'outward': outward,
    'end': end,
    'double': lo == hi,
  };
}

/// Партия 1×1 против бота; [turn] 0 — мой ход.
DominoGameView _duel({
  required List<int> hand,
  List<Map<String, dynamic>>? chain,
  List<int> legal = const [],
  int opponent = 5,
  int boneyard = 3,
  int turn = 0,
  int seq = 1,
  int lastTile = -1,
  int lastActor = -1,
}) {
  return DominoGameView.fromJson({
    'id': 'g',
    'players': [
      {'user_id': 'me', 'seat': 0, 'hand': hand, 'hand_count': hand.length},
      {
        'user_id': 'bot:domino',
        'seat': 1,
        'hand': <int>[],
        'hand_count': opponent,
      },
    ],
    'chain': chain ?? [_chainTile(2, 3)],
    'left_end': 2,
    'right_end': 3,
    'boneyard_count': boneyard,
    'turn': turn,
    'round': 1,
    'status': 'playing',
    'legal': [
      for (final tile in legal) {'tile': tile, 'end': 'left'},
    ],
    'my_index': 0,
    'is_my_turn': turn == 0,
    'target_score': 101,
    'event_seq': seq,
    if (lastTile >= 0) 'last_action': 'play',
    if (lastTile >= 0) 'last_tile': lastTile,
    if (lastActor >= 0) 'last_actor': lastActor,
  });
}

Future<void> _pumpTable(
  WidgetTester tester,
  DominoGameView view, {
  ValueChanged<DominoMove>? onPlay,
  VoidCallback? onDraw,
  Size size = const Size(420, 640),
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
        home: Scaffold(
          body: DominoTable(
            view: view,
            onPlay: onPlay ?? (_) {},
            onDraw: onDraw,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('цепь не накладывает кости и дубль выше обычной', () {
    final chain = [
      for (var i = 0; i < 12; i++) _tile(i % 7, (i + 1) % 7),
      _tile(6, 6),
    ];
    final slots = layoutDominoChain(chain, 220);
    expect(slots, hasLength(chain.length));
    final doubleSlot = slots.last;
    expect(doubleSlot.rect.height, greaterThan(doubleSlot.rect.width));
    expect(slots.first.leadingOnRight, isTrue);
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final overlap = slots[i].rect.intersect(slots[j].rect);
        expect(
          overlap.width <= 0 || overlap.height <= 0,
          isTrue,
          reason: 'слоты $i и $j пересекаются',
        );
      }
    }
  });

  test('дубль на обратном ряду не накрывает соседей', () {
    final chain = [
      for (var i = 0; i < 5; i++) _tile(i, i + 1),
      _tile(5, 5),
      _tile(5, 6),
      _tile(6, 6),
      _tile(0, 6),
      _tile(0, 0),
      _tile(0, 3),
      _tile(3, 3),
      _tile(1, 3),
    ];
    for (final width in [150.0, 200.0, 260.0, 332.0]) {
      final slots = layoutDominoChain(chain, width);
      expect(slots.any((slot) => !slot.leadingOnRight), isTrue);
      for (var i = 0; i < slots.length; i++) {
        expect(slots[i].rect.left, greaterThanOrEqualTo(0));
        for (var j = i + 1; j < slots.length; j++) {
          final overlap = slots[i].rect.intersect(slots[j].rect);
          expect(
            overlap.width <= 0 || overlap.height <= 0,
            isTrue,
            reason: 'ширина $width: слоты $i и $j пересекаются',
          );
        }
      }
    }
  });

  test('на обратном ряду 1-6 смотрит шестёркой к соседу', () {
    final chain = [
      _oriented(6, 6, end: 'start'),
      _oriented(6, 4),
      _oriented(4, 2),
      _oriented(2, 3),
      _oriented(3, 0),
      _oriented(0, 2),
      _oriented(2, 5),
      _oriented(5, 6),
      _oriented(6, 1),
      _oriented(1, 0),
      _oriented(0, 6),
      _oriented(6, 3),
      _oriented(3, 5),
    ];
    final slots = layoutDominoChain(chain, 332);
    final played = chain[8];
    expect(slots[8].leadingOnRight, isFalse);
    final halves = dominoHalfPips(played, leadingOnRight: false);
    expect(halves.right, 6);
    expect(halves.left, 1);
    _expectJoints(chain, 332);

    final fromLeft = [
      _oriented(4, 5, end: 'left'),
      _oriented(3, 4, end: 'left'),
      _oriented(2, 3, end: 'left'),
      _oriented(1, 2, end: 'left'),
      _oriented(1, 0, end: 'start'),
      _oriented(0, 6),
      _oriented(6, 5),
    ];
    _expectJoints(fromLeft, 120);
  });

  test('старый кадр козла не откатывает кон', () {
    DominoGameView view(int round, int seq) => DominoGameView.fromJson({
          'players': [
            {'user_id': 'me', 'hand': <int>[], 'hand_count': 0},
          ],
          'chain': <Map<String, dynamic>>[],
          'boneyard_count': 0,
          'round': round,
          'event_seq': seq,
          'status': 'playing',
          'my_index': 0,
        });
    expect(isOlderDomino(view(1, 9), view(2, 1)), isTrue);
    expect(isOlderDomino(view(2, 3), view(2, 4)), isTrue);
    expect(isOlderDomino(view(2, 5), view(2, 4)), isFalse);
    expect(
      hasFullDominoView({
        'game_type': 'domino',
        'chain': <Map<String, dynamic>>[],
        'boneyard_count': 4,
      }),
      isTrue,
    );
    expect(hasFullDominoView({'players': <Map<String, dynamic>>[]}), isFalse);
  });

  testWidgets('тап по кости руки ставит её на единственный конец',
      (tester) async {
    final tile = dominoTileId(1, 2);
    DominoMove? played;
    final view = DominoGameView.fromJson({
      'id': 'g',
      'players': [
        {
          'user_id': 'me',
          'hand': [tile],
          'hand_count': 1,
        },
        {
          'user_id': 'bot:domino',
          'hand': <int>[],
          'hand_count': 5,
        },
      ],
      'chain': [
        {
          'id': dominoTileId(2, 3),
          'lo': 2,
          'hi': 3,
          'inward': 2,
          'outward': 3,
          'end': 'start',
          'double': false,
        },
      ],
      'left_end': 2,
      'right_end': 3,
      'boneyard_count': 3,
      'turn': 0,
      'round': 1,
      'status': 'playing',
      'legal': [
        {'tile': tile, 'end': 'left'},
      ],
      'my_index': 0,
      'is_my_turn': true,
      'target_score': 101,
    });
    await _pumpTable(tester, view, onPlay: (move) => played = move);
    await tester.tap(find.byKey(ValueKey('domino-hand-$tile')));
    await tester.pump();
    expect(played?.tile, tile);
    expect(played?.end, 'left');
  });

  test('цепь ужимается, пока не влезет в стол по высоте', () {
    final chain = [
      for (var i = 0; i < 20; i++) _tile(i % 7, (i + 1) % 7),
    ];
    const area = Size(300, 150);
    final roomy = fitDominoChain(chain, const Size(300, 900));
    expect(roomy.scale, 1);
    final tight = fitDominoChain(chain, area);
    expect(tight.scale, lessThan(1));
    expect(tight.size.height, lessThanOrEqualTo(area.height + 0.01));
    expect(tight.size.width, lessThanOrEqualTo(area.width + 0.01));
    for (final slot in tight.slots) {
      expect(slot.rect.left, greaterThanOrEqualTo(-0.01));
      expect(slot.rect.top, greaterThanOrEqualTo(-0.01));
    }
    expect(fitDominoChain(const [], area).slots, isEmpty);
  });

  testWidgets('базар лежит россыпью, кости соперника видны рубашками',
      (tester) async {
    await _pumpTable(tester, _duel(hand: [dominoTileId(1, 2)], boneyard: 9));
    // 9 костей базара + 5 костей соперника.
    expect(find.byType(DominoTileBack), findsNWidgets(14));
    expect(find.text('Базар 9'), findsOneWidget);
    final backs = tester
        .widgetList<Transform>(find.ancestor(
          of: find.byType(DominoTileBack),
          matching: find.byType(Transform),
        ))
        .length;
    expect(backs, greaterThanOrEqualTo(9), reason: 'кости базара повёрнуты');
    expect(find.byKey(const ValueKey('game-opponent-frame')), findsOneWidget);
  });

  testWidgets('мой ход: кость летит из руки в цепь', (tester) async {
    final played = dominoTileId(1, 2);
    final kept = dominoTileId(4, 5);
    await _pumpTable(tester, _duel(hand: [played, kept], legal: [played]));
    expect(find.byType(DominoTileFace), findsNWidgets(2));

    await _pumpTable(
      tester,
      _duel(
        hand: [kept],
        chain: [_chainTile(2, 3), _chainTile(1, 2, end: 'left')],
        seq: 2,
        turn: 1,
        lastTile: played,
        lastActor: 0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(ValueKey('domino-hand-$played')), findsNothing);
    // Одна кость в руке и одна в воздухе.
    expect(find.byType(DominoTileFace), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byType(DominoTileFace), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('соперник ходит: кость вылетает из его ряда и переворачивается',
      (tester) async {
    final mine = dominoTileId(4, 5);
    await _pumpTable(tester, _duel(hand: [mine], turn: 1, opponent: 5));
    await _pumpTable(
      tester,
      _duel(
        hand: [mine],
        chain: [_chainTile(2, 3), _chainTile(3, 6)],
        seq: 2,
        opponent: 4,
        lastTile: dominoTileId(3, 6),
        lastActor: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(DominoFlipTile), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(DominoFlipTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('взятая кость летит из базара и встаёт в руку', (tester) async {
    final had = dominoTileId(4, 5);
    final drawn = dominoTileId(0, 6);
    var draws = 0;
    await _pumpTable(
      tester,
      _duel(hand: [had], boneyard: 6),
      onDraw: () => draws++,
    );
    expect(find.byKey(const ValueKey('domino-draw')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('domino-boneyard')));
    expect(draws, 1, reason: 'нажатие на базар берёт кость');

    await _pumpTable(
      tester,
      _duel(hand: [had, drawn], boneyard: 5, seq: 2, legal: [drawn]),
      onDraw: () => draws++,
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Базар 5'), findsOneWidget);
    expect(find.byType(DominoFlipTile), findsOneWidget);
    Opacity slot() => tester.widget<Opacity>(find
        .descendant(
          of: find.byKey(ValueKey('domino-hand-$drawn')),
          matching: find.byType(Opacity),
        )
        .first);
    expect(slot().opacity, 0, reason: 'место в руке пустует до посадки');
    await tester.pumpAndSettle();
    expect(find.byType(DominoFlipTile), findsNothing);
    expect(slot().opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('большая рука листается, кости крупные и с зазором',
      (tester) async {
    final hand = [
      for (var lo = 0; lo < 3; lo++)
        for (var hi = lo; hi < lo + 4; hi++) dominoTileId(lo, hi),
    ];
    await _pumpTable(tester, _duel(hand: hand), size: const Size(390, 700));
    final first = tester.getRect(find.byKey(ValueKey('domino-hand-${hand[0]}')));
    final second =
        tester.getRect(find.byKey(ValueKey('domino-hand-${hand[1]}')));
    expect(first.width, greaterThanOrEqualTo(38));
    expect(second.left - first.right, greaterThanOrEqualTo(9.9));
    final last = find.byKey(ValueKey('domino-hand-${hand.last}'));
    expect(tester.getRect(last).left, greaterThan(390));

    await tester.drag(find.byType(GameHandStrip), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(last).right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('офлайн-стол живёт на узком и широком экране', (tester) async {
    setUpTestLocaleRu();
    final session = OfflineDominoSession.create(
      humanUserId: 'local:player',
      playerCount: 4,
      humanDisplayName: 'Я',
    );
    addTearDown(() {
      OfflineDominoRegistry.instance.get(session.gameId)?.dispose();
    });

    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DominoGameScreen(gameId: session.gameId),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAt(const Size(390, 800));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Базар'), findsOneWidget);
    expect(find.textContaining('до 101'), findsOneWidget);

    // Раздача случайная: человек может не открывать, а боты ходят с паузой.
    DominoMove? opening;
    for (var i = 0; i < 24 && opening == null; i++) {
      final legal = session.view.legal;
      if (legal.isNotEmpty) {
        opening = legal.first;
        break;
      }
      if (session.view.canDraw) {
        await session.applyMove(type: dominoActionDraw);
      } else if (session.view.canPass) {
        await session.applyMove(type: dominoActionPass);
      }
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(opening, isNotNull);
    // После ходов ботов рука на узком экране может уехать под край,
    // тап по кости проверяет отдельный тест стола.
    await session.applyMove(
      type: dominoActionPlay,
      tile: opening!.tile,
      end: opening.end,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(tester.takeException(), isNull);
    expect(session.engine.chain, isNotEmpty);

    await pumpAt(const Size(1100, 800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Базар'), findsOneWidget);
    OfflineDominoRegistry.instance.disposeAll();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('крайняя левая кость руки нажимается', (tester) async {
    setUpTestLocaleRu();
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = OfflineDominoSession.create(
      humanUserId: 'local:player',
      playerCount: 2,
      humanDisplayName: 'Я',
    );
    addTearDown(() {
      OfflineDominoRegistry.instance.disposeAll();
    });
    final tile = dominoTileId(0, 1);
    final game = session.engine;
    game
      ..leftEnd = -1
      ..rightEnd = -1
      ..turn = 0
      ..forcedTile = -1
      ..status = dominoStatusPlaying
      ..chain.clear();
    // Рука шире экрана: первая кость стоит у самого левого края.
    game.players[0].hand
      ..clear()
      ..addAll([
        tile,
        dominoTileId(2, 3),
        dominoTileId(4, 5),
        dominoTileId(6, 6),
        dominoTileId(0, 2),
        dominoTileId(1, 3),
        dominoTileId(2, 4),
        dominoTileId(3, 5),
        dominoTileId(4, 6),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DominoGameScreen(gameId: session.gameId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final key = find.byKey(ValueKey('domino-hand-$tile'));
    expect(key, findsOneWidget);
    final center = tester.getCenter(key);
    expect(center.dx, lessThan(48),
        reason: 'кость в зоне старой полосы крестика');
    await tester.tapAt(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(session.engine.chain, isNotEmpty);
    expect(session.engine.chain.first.id, tile);
    OfflineDominoRegistry.instance.disposeAll();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('офлайн-домино: флаг под правилами сдаёт партию', (tester) async {
    setUpTestLocaleRu();
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = OfflineDominoSession.create(
      humanUserId: 'local:player',
      playerCount: 2,
      humanDisplayName: 'Я',
    );
    addTearDown(OfflineDominoRegistry.instance.disposeAll);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DominoGameScreen(gameId: session.gameId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final rules = find.byKey(const ValueKey('game-chrome-rules'));
    final rail = find.byKey(const ValueKey('game-chrome-rail'));
    expect(rules, findsOneWidget);
    expect(rail, findsOneWidget);
    expect(
      tester.getRect(rail).top,
      greaterThanOrEqualTo(tester.getRect(rules).bottom - 4),
    );

    final flag = find.descendant(
      of: rail,
      matching: find.byIcon(Icons.flag_outlined),
    );
    expect(flag, findsOneWidget);
    await tester.tap(flag);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сдаться'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(session.view.isOver, isTrue);
    expect(session.view.iWon, isFalse);
    expect(find.byKey(const ValueKey('game-chrome-rail')), findsNothing);
    expect(tester.takeException(), isNull);
    OfflineDominoRegistry.instance.disposeAll();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
