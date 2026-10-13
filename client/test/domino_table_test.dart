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
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: DominoTable(
              view: view,
              onPlay: (move) => played = move,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('domino-hand-$tile')));
    await tester.pump();
    expect(played?.tile, tile);
    expect(played?.end, 'left');
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
    game.players[0].hand
      ..clear()
      ..addAll(
          [tile, dominoTileId(2, 3), dominoTileId(4, 5), dominoTileId(6, 6)]);

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
}
