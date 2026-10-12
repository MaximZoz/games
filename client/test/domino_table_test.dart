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

  testWidgets('тап по кости руки ставит её на единственный конец', (tester) async {
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

    final opening = session.view.legal.first;
    await tester.tap(find.byKey(ValueKey('domino-hand-${opening.tile}')));
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
}
