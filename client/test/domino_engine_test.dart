import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/domino/domino_bot.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';

DominoGame freshGame(
    List<List<int>> hands, List<int> boneyard, int left, int right) {
  final game = DominoGame(
    players: [
      for (var i = 0; i < hands.length; i++)
        DominoPlayer(userId: 'p$i', hand: hands[i]),
    ],
    boneyard: boneyard,
    leftEnd: left,
    rightEnd: right,
    round: 2,
    rng: 99,
    starter: 0,
  );
  if (left >= 0) {
    game.chain = [
      DominoPlaced(
        id: dominoTileId(left, right),
        lo: left,
        hi: right,
        inward: left,
        outward: right,
        end: 'start',
        isDouble: left == right,
      ),
    ];
  }
  return game;
}

DominoGame seaGame(
    List<List<int>> hands, List<int> boneyard, int left, int right) {
  final game = freshGame(hands, boneyard, left, right);
  game.mode = dominoModeSea;
  game.target = dominoSeaScore;
  return game;
}

void main() {
  test('catalog and deal', () {
    expect(dominoTileId(0, 0), 0);
    expect(dominoTileId(6, 6), 27);
    expect(dominoTileId(5, 3), dominoTileId(3, 5));
    final seen = <int>{};
    for (var hi = 0; hi <= 6; hi++) {
      for (var lo = 0; lo <= hi; lo++) {
        final id = dominoTileId(lo, hi);
        final pips = dominoPips(id);
        expect(pips, (lo, hi));
        expect(seen.add(id), isTrue);
      }
    }
    expect(seen, hasLength(28));

    final two = DominoGame.newGame(['a', 'b'], 7);
    expect(two.boneyard, hasLength(14));
    expect(two.players[0].hand, hasLength(7));
    final opening = two.pickOpening()!;
    expect(two.turn, opening.$1);
    expect(two.forcedTile, opening.$2);
    expect(two.legal(two.turn), hasLength(1));
    two.apply(DominoAction(
      type: dominoActionPlay,
      tile: opening.$2,
      end: 'left',
    ));
    expect(two.chain, hasLength(1));
    expect(two.leftEnd, isNonNegative);

    expect(DominoGame.newGame(['a', 'b', 'c'], 9).boneyard, hasLength(7));
    expect(DominoGame.newGame(['a', 'b', 'c', 'd'], 11).boneyard, isEmpty);
  });

  test('deal matches server uint64 splitmix', () {
    final seed7 = DominoGame.newGame(['a', 'b'], 7);
    expect(seed7.players[0].hand, [17, 6, 26, 13, 20, 19, 2]);
    expect(seed7.players[1].hand, [27, 21, 11, 16, 7, 18, 15]);
    expect(
      seed7.boneyard,
      [4, 14, 8, 1, 9, 5, 25, 12, 0, 10, 3, 22, 24, 23],
    );

    final seed42 = DominoGame.newGame(['a', 'b'], 42);
    expect(seed42.players[0].hand, [22, 1, 16, 24, 15, 3, 12]);
    expect(seed42.players[1].hand, [8, 18, 21, 9, 26, 4, 0]);
    expect(
      seed42.boneyard,
      [23, 6, 11, 17, 13, 27, 20, 7, 2, 25, 14, 10, 19, 5],
    );
  });

  test('double keeps the end and the round continues', () {
    final game = freshGame([
      [dominoTileId(3, 5), dominoTileId(3, 3)],
      [dominoTileId(1, 1)],
    ], const [], -1, -1);
    game.apply(DominoAction(type: dominoActionPlay, tile: dominoTileId(3, 5)));
    expect(game.leftEnd, 3);
    expect(game.rightEnd, 5);
    game.apply(const DominoAction(type: dominoActionPass));
    expect(game.status, dominoStatusPlaying);
    game.apply(DominoAction(
      type: dominoActionPlay,
      tile: dominoTileId(3, 3),
      end: 'left',
    ));
    expect(game.leftEnd, 3);
    expect(game.rightEnd, 5);
    expect(game.chain.first.isDouble, isTrue);
  });

  test('draw is last-in and hidden from the opponent', () {
    final match = dominoTileId(0, 4);
    final game = freshGame(
      [
        [dominoTileId(2, 2)],
        [dominoTileId(1, 1)],
      ],
      [match, dominoTileId(5, 5)],
      0,
      1,
    );
    expect(
      () => game.apply(const DominoAction(type: dominoActionPass)),
      throwsStateError,
    );
    game.apply(const DominoAction(type: dominoActionDraw));
    expect(game.lastTile, dominoTileId(5, 5));
    expect(game.turn, 0);
    game.apply(const DominoAction(type: dominoActionDraw));
    expect(game.lastTile, match);
    expect(game.view('p1').lastTile, -1);
    final me = game.view('p0');
    expect(me.lastTile, match);
    expect(me.players[1].hand, isEmpty);
    expect(me.legal.single.tile, match);
  });

  test('fish, out and the next starter', () {
    final fish = freshGame(
      [
        [dominoTileId(1, 1)],
        [dominoTileId(2, 3)],
      ],
      const [],
      6,
      6,
    );
    fish.apply(const DominoAction(type: dominoActionPass));
    expect(fish.roundKind, dominoRoundFish);
    expect(fish.players[0].roundDelta, 0);
    expect(fish.players[1].roundDelta, 5);

    final tied = freshGame(
      [
        [dominoTileId(1, 1)],
        [dominoTileId(1, 1)],
      ],
      const [],
      6,
      6,
    );
    tied.apply(const DominoAction(type: dominoActionPass));
    expect(tied.players[0].roundDelta, 2);
    expect(tied.players[1].roundDelta, 2);

    final out = freshGame(
      [
        [dominoTileId(4, 6)],
        [dominoTileId(2, 3), dominoTileId(1, 1)],
      ],
      const [],
      6,
      0,
    );
    out.apply(DominoAction(
      type: dominoActionPlay,
      tile: dominoTileId(4, 6),
      end: 'left',
    ));
    expect(out.roundKind, dominoRoundOut);
    expect(out.players[0].roundDelta, 0);
    expect(out.players[1].score, 7);
    out.apply(const DominoAction(type: dominoActionNextRound));
    expect(out.starter, 0);
    expect(out.forcedTile, -1);
    expect(out.status, dominoStatusPlaying);
  });

  test('tied fish starts at the next seat', () {
    final game = freshGame(
      [
        [dominoTileId(1, 1)],
        [dominoTileId(1, 1)],
        [dominoTileId(2, 3)],
      ],
      const [],
      6,
      6,
    );
    game.apply(const DominoAction(type: dominoActionPass));
    game.apply(const DominoAction(type: dominoActionNextRound));
    expect(game.starter, 1);
  });

  test('highest score is the goat', () {
    final game = freshGame(
      [
        [dominoTileId(0, 1)],
        [dominoTileId(6, 6)],
        [dominoTileId(0, 5)],
      ],
      const [],
      1,
      2,
    );
    game.players[0].score = 100;
    game.players[1].score = 100;
    game.players[2].score = 99;
    game.apply(DominoAction(
      type: dominoActionPlay,
      tile: dominoTileId(0, 1),
      end: 'left',
    ));
    expect(game.status, dominoStatusOver);
    expect(game.goatSeat, 1);
    expect(game.winnerUserIds, ['p0']);
    expect(game.view('p2').players[1].hand, isNotEmpty);
  });

  test('forfeit leaves the survivor', () {
    final game = freshGame(
      [
        [dominoTileId(0, 0), dominoTileId(1, 1)],
        [dominoTileId(2, 2)],
      ],
      const [],
      -1,
      -1,
    );
    game.apply(const DominoAction(type: dominoActionForfeit, actor: 'p0'));
    expect(game.isOver, isTrue);
    expect(game.winnerUserIds, ['p1']);
    expect(game.goatSeat, 0);
  });

  test('encode roundtrip', () {
    final game = DominoGame.newGame(['a', 'b', 'c'], 42);
    final back = DominoGame.decode(game.encode());
    expect(back.forcedTile, game.forcedTile);
    expect(back.boneyard, game.boneyard);
    expect(back.players[0].hand, game.players[0].hand);
    expect(back.rng, game.rng);
    expect(back.players[1].userId, 'b');
  });

  test('bot dumps the heavy double and does not peek', () {
    final heavy = freshGame(
      [
        [dominoTileId(6, 6), dominoTileId(1, 1)],
        [dominoTileId(2, 2)],
      ],
      [dominoTileId(3, 3)],
      6,
      1,
    );
    expect(dominoBestAction(heavy, 0).tile, dominoTileId(6, 6));

    final mine = [dominoTileId(0, 6), dominoTileId(1, 2)];
    final left = dominoBestAction(
      freshGame(
        [
          mine,
          [dominoTileId(5, 5), dominoTileId(4, 4)],
        ],
        [dominoTileId(3, 3), dominoTileId(2, 2)],
        0,
        1,
      ),
      0,
    );
    final right = dominoBestAction(
      freshGame(
        [
          mine,
          [dominoTileId(3, 3), dominoTileId(2, 2)],
        ],
        [dominoTileId(5, 5), dominoTileId(4, 4)],
        0,
        1,
      ),
      0,
    );
    expect(left, right);
    expect(left.tile, dominoTileId(0, 6));
  });

  test('bot closes a dead suit', () {
    final game = freshGame(
      [
        [dominoTileId(1, 1), dominoTileId(0, 3)],
        [dominoTileId(2, 4)],
      ],
      [dominoTileId(0, 2)],
      1,
      3,
    );
    game.chain = [
      for (final id in [
        dominoTileId(0, 1),
        dominoTileId(1, 2),
        dominoTileId(1, 3),
        dominoTileId(1, 4),
        dominoTileId(1, 5),
        dominoTileId(1, 6),
      ])
        DominoPlaced(
          id: id,
          lo: dominoPips(id).$1,
          hi: dominoPips(id).$2,
          inward: 0,
          outward: 0,
          end: 'right',
          isDouble: false,
        ),
    ];
    expect(game.knownSuit(0, 1, dominoTileId(1, 1)), dominoSuitCopies);
    expect(dominoBestAction(game, 0).tile, dominoTileId(1, 1));
  });

  test('bot loses to greedy less than a third of the time', () {
    var losses = 0;
    const games = 16;
    for (var seed = 1; seed <= 8; seed++) {
      for (final seat in const [0, 1]) {
        final game = DominoGame.newGame(['p0', 'p1'], seed * 10 + seat);
        for (var step = 0; step < 4000 && !game.isOver; step++) {
          if (game.status == dominoStatusRoundEnd) {
            game.apply(const DominoAction(type: dominoActionNextRound));
            continue;
          }
          final action = game.turn == seat
              ? dominoBestAction(game, game.turn)
              : dominoGreedyAction(game, game.turn);
          expect(action.type, isNotEmpty);
          game.apply(action);
        }
        expect(game.isOver, isTrue);
        if (game.goatSeat == seat) losses++;
      }
    }
    expect(losses, lessThanOrEqualTo(games ~/ 3));
  });

  test('classic and sea scoring', () {
    final four = DominoGame.newGame(
      ['a', 'b', 'c', 'd'],
      3,
      dominoModeClassic,
    );
    expect(four.mode, dominoModeClassic);
    expect(four.target, dominoClassicScore);
    expect(four.players.first.hand, hasLength(5));
    expect(four.boneyard, hasLength(8));

    final opening = freshGame([
      [dominoTileId(1, 1)],
      [dominoTileId(6, 6)],
    ], const [], -1, -1);
    opening.mode = dominoModeClassic;
    expect(opening.pickOpening(), (1, dominoTileId(6, 6)));
    opening.mode = dominoModeKozel;
    expect(opening.pickOpening(), (0, dominoTileId(1, 1)));

    final out = freshGame([
      [dominoTileId(1, 1)],
      [dominoTileId(3, 3), dominoTileId(4, 4)],
    ], const [], 1, 2);
    out.mode = dominoModeClassic;
    out.target = dominoClassicScore;
    out.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(1, 1), end: 'left'));
    expect(out.status, dominoStatusRoundEnd);
    expect(out.players[0].score, 14);
    expect(out.players[1].score, 0);

    final fish = freshGame([
      [dominoTileId(2, 3)],
      [dominoTileId(4, 4)],
      [dominoTileId(5, 5), dominoTileId(6, 6)],
    ], const [], 0, 1);
    fish.mode = dominoModeClassic;
    fish.target = dominoClassicScore;
    fish.apply(const DominoAction(type: dominoActionPass));
    expect(fish.roundKind, dominoRoundFish);
    expect(fish.players[0].score, 20);

    // 0-0 посреди кона — обычная кость: кон идёт дальше.
    final blank = seaGame([
      [dominoTileId(0, 0), dominoTileId(1, 2)],
      [dominoTileId(6, 6), dominoTileId(5, 1)],
    ], const [], 0, 5);
    blank.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(0, 0), end: 'left'));
    expect(blank.status, dominoStatusPlaying);
    expect(blank.turn, 1);
    expect(blank.players[1].score, 0);
    expect(blank.players[0].hand, hasLength(1));

    final six = freshGame([
      [dominoTileId(6, 6)],
      [dominoTileId(5, 5)],
    ], const [], 6, 1);
    six.mode = dominoModeSea;
    six.target = dominoSeaScore;
    six.players[0].score = 40;
    six.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(6, 6), end: 'left'));
    expect(six.players[0].score, 0);
    expect(six.players[1].score, dominoSeaSixHit);
  });

  test('sea: lone 0-0, lone 6-6 and both together', () {
    final cases = <(List<int>, int)>[
      ([dominoTileId(0, 0)], dominoSeaLoneBlank),
      ([dominoTileId(6, 6)], dominoSeaLoneSix),
      ([dominoTileId(6, 6), dominoTileId(0, 0)], dominoSeaBlankSix),
      ([dominoTileId(6, 6), dominoTileId(0, 1)], 0),
      (
        [
          dominoTileId(0, 0),
          dominoTileId(6, 5),
          dominoTileId(6, 4),
          dominoTileId(5, 5),
        ],
        31,
      ),
    ];
    for (final (hand, want) in cases) {
      final game = seaGame([
        [dominoTileId(1, 2)],
        hand,
      ], const [], 3, 1);
      game.apply(DominoAction(
          type: dominoActionPlay, tile: dominoTileId(1, 2), end: 'right'));
      expect(game.roundKind, dominoRoundOut);
      expect(game.players[1].score, want, reason: '$hand');
      expect(game.players[1].roundDelta, want, reason: '$hand');
      expect(game.players[0].score, 0);
    }

    // Одинокий дубль тяжелее обычной руки: пишут ему, а не руке на 20.
    final three = seaGame([
      [dominoTileId(1, 2)],
      [dominoTileId(0, 0)],
      [dominoTileId(6, 4), dominoTileId(5, 5)],
    ], const [], 3, 1);
    three.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(1, 2), end: 'right'));
    expect(three.players[1].score, dominoSeaLoneBlank);
    expect(three.players[2].score, 0);
  });

  test('sea: fast opening needs records and charges 50 or 75', () {
    final game = seaGame([
      [dominoTileId(0, 0), dominoTileId(6, 6), dominoTileId(2, 3)],
      [dominoTileId(3, 5)],
    ], const [], -1, -1);
    expect([for (final move in game.legal(0)) move.tile], [dominoTileId(2, 3)]);
    expect(
      () => game.apply(DominoAction(
          type: dominoActionPlay, tile: dominoTileId(0, 0), end: 'left')),
      throwsStateError,
    );
    game.players[1].score = 30;
    expect(game.legal(0), hasLength(3));

    // В «Козле» ограничения нет.
    final goat = freshGame([
      [dominoTileId(0, 0), dominoTileId(2, 3)],
      [dominoTileId(3, 5)],
    ], const [], -1, -1);
    expect(goat.legal(0), hasLength(2));

    for (final (pip, want) in [
      (0, dominoSeaFastBlank),
      (6, dominoSeaFastSix)
    ]) {
      final fast = seaGame([
        [dominoTileId(pip, pip), dominoTileId(pip, 3)],
        [dominoTileId(3, 5), dominoTileId(1, 1)],
      ], const [], -1, -1);
      fast.players[1].score = 30;
      fast.apply(DominoAction(
          type: dominoActionPlay, tile: dominoTileId(pip, pip), end: 'left'));
      expect(fast.status, dominoStatusPlaying);
      fast.apply(const DominoAction(type: dominoActionPass));
      fast.apply(DominoAction(
          type: dominoActionPlay, tile: dominoTileId(pip, 3), end: 'left'));
      expect(fast.status, dominoStatusRoundEnd);
      expect(fast.players[1].score, 30 + want);
      expect(fast.players[1].roundDelta, want);
    }

    // Рыба в быстром коне не пишется никому.
    final fish = seaGame([
      [dominoTileId(1, 2), dominoTileId(1, 3), dominoTileId(1, 4)],
      [dominoTileId(5, 5), dominoTileId(5, 4), dominoTileId(5, 3)],
    ], const [], 6, 6);
    fish.players[0].score = 40;
    fish.apply(const DominoAction(type: dominoActionPass));
    expect(fish.roundKind, dominoRoundFish);
    expect(fish.status, dominoStatusRoundEnd);
    expect(fish.players[0].score, 40);
    expect(fish.players[1].score, 0);
  });

  test('sea: going out with 0-0 ends the match', () {
    final game = seaGame([
      [dominoTileId(0, 0)],
      [dominoTileId(1, 2)],
      [dominoTileId(6, 5), dominoTileId(4, 4)],
    ], const [], 0, 3);
    game.players[0].score = 90;
    game.players[1].score = 110;
    game.players[2].score = 10;
    game.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(0, 0), end: 'left'));
    expect(game.isOver, isTrue);
    expect(game.goatSeat, 2);
    expect(game.winnerUserIds, ['p0']);
    expect([for (final player in game.players) player.score], [90, 110, 10]);
  });

  test('sea: two doubles in one move', () {
    final game = seaGame([
      [dominoTileId(3, 3), dominoTileId(5, 5), dominoTileId(1, 2)],
      [dominoTileId(3, 4), dominoTileId(5, 1)],
    ], const [], 3, 5);
    expect(game.canPair(0), isTrue);
    expect(game.view('p0').canPair, isTrue);
    expect(game.view('p1').canPair, isFalse);
    game.apply(const DominoAction(type: dominoActionPlayPair));
    expect(game.players[0].hand, [dominoTileId(1, 2)]);
    expect((game.leftEnd, game.rightEnd, game.turn), (3, 5, 1));
    expect(game.lastAction, dominoActionPlayPair);
    expect((game.lastTile, game.lastTile2),
        (dominoTileId(3, 3), dominoTileId(5, 5)));
    expect([for (final placed in game.chain) placed.id],
        [dominoTileId(3, 3), dominoTileId(3, 5), dominoTileId(5, 5)]);
    final seen = game.view('p1');
    expect((seen.lastTile, seen.lastTile2),
        (dominoTileId(3, 3), dominoTileId(5, 5)));
    game.apply(DominoAction(
        type: dominoActionPlay, tile: dominoTileId(3, 4), end: 'left'));
    expect(game.lastTile2, -1);

    // Обычная кость, потом «Два дубля»: после 5-4 концы 3 и 4, и дубли
    // 3-3 с 4-4 всё ещё в руке. Если ход не уйдёт, кнопка положит ещё две.
    final after = seaGame([
      [
        dominoTileId(5, 4),
        dominoTileId(3, 3),
        dominoTileId(5, 5),
        dominoTileId(4, 4),
      ],
      [dominoTileId(0, 1)],
    ], [dominoTileId(6, 6)], 3, 5);
    expect(after.canPair(0), isTrue);
    after.apply(DominoAction(
      type: dominoActionPlay,
      tile: dominoTileId(5, 4),
      end: 'right',
    ));
    expect(after.turn, 1);
    expect((after.leftEnd, after.rightEnd), (3, 4));
    expect(after.chain, hasLength(2));
    expect(after.players[0].hand, [
      dominoTileId(3, 3),
      dominoTileId(5, 5),
      dominoTileId(4, 4),
    ]);
    expect(after.canPair(0), isFalse);
    expect(
      () => after.apply(const DominoAction(type: dominoActionPlayPair)),
      throwsStateError,
    );
    after.turn = 0;
    expect(after.canPair(0), isTrue);

    // Одного дубля мало, как и одинаковых концов.
    final one = seaGame([
      [dominoTileId(3, 3), dominoTileId(1, 2)],
      [dominoTileId(3, 4)],
    ], const [], 3, 5);
    expect(one.canPair(0), isFalse);
    expect(() => one.apply(const DominoAction(type: dominoActionPlayPair)),
        throwsStateError);
    final same = seaGame([
      [dominoTileId(3, 3), dominoTileId(1, 2)],
      [dominoTileId(3, 4)],
    ], const [], 3, 3);
    expect(same.canPair(0), isFalse);

    // Только морской режим.
    final goat = freshGame([
      [dominoTileId(3, 3), dominoTileId(5, 5), dominoTileId(1, 2)],
      [dominoTileId(3, 4)],
    ], const [], 3, 5);
    expect(goat.canPair(0), isFalse);
    expect(() => goat.apply(const DominoAction(type: dominoActionPlayPair)),
        throwsStateError);

    // Пара закрывает кон: 6-6 в паре — 100 и сброс счёта закрывшего.
    final six = seaGame([
      [dominoTileId(6, 6), dominoTileId(2, 2)],
      [dominoTileId(1, 3)],
    ], const [], 6, 2);
    six.players[0].score = 60;
    six.apply(const DominoAction(type: dominoActionPlayPair));
    expect(six.status, dominoStatusRoundEnd);
    expect(six.roundKind, dominoRoundOut);
    expect(six.players[0].score, 0);
    expect(six.players[1].score, dominoSeaSixHit);

    // 0-0 в паре — конец партии, даже вместе с 6-6.
    final admiral = seaGame([
      [dominoTileId(6, 6), dominoTileId(0, 0)],
      [dominoTileId(1, 3)],
    ], const [], 6, 0);
    admiral.players[0].score = 60;
    admiral.apply(const DominoAction(type: dominoActionPlayPair));
    expect(admiral.isOver, isTrue);
    expect(admiral.goatSeat, 1);
    expect(admiral.winnerUserIds, ['p0']);
    expect(admiral.players[0].score, 60);
  });

  test('sea: state without last_tile2 decodes to no second tile', () {
    final game = DominoGame.newGame(['a', 'b'], 7, dominoModeSea);
    expect(game.lastTile2, -1);
    final json = game.toJson()..remove('last_tile2');
    final back = DominoGame.decode(jsonEncode(json));
    expect(back.lastTile2, -1);
    expect(DominoGame.decode(game.encode()).lastTile2, -1);
  });

  test('sea: bot plays the pair of doubles', () {
    final game = seaGame([
      [dominoTileId(3, 3), dominoTileId(5, 5), dominoTileId(1, 2)],
      [dominoTileId(3, 4), dominoTileId(5, 1), dominoTileId(0, 2)],
    ], [
      dominoTileId(0, 4),
      dominoTileId(2, 6),
      dominoTileId(4, 6)
    ], 3, 5);
    expect(dominoBestAction(game, 0).type, dominoActionPlayPair);

    // Закрыть кон парой с 0-0 — выиграть партию.
    final out = seaGame([
      [dominoTileId(0, 0), dominoTileId(4, 4)],
      [dominoTileId(0, 1), dominoTileId(2, 3)],
    ], const [], 0, 4);
    final action = dominoBestAction(out, 0);
    expect(action.type, dominoActionPlayPair);
    out.apply(action);
    expect(out.isOver, isTrue);
    expect(out.goatSeat, 1);
  });

  // Те же строки сверяет server/internal/domino/parity_test.go: движок и бот
  // на Dart и на Go обязаны сыграть морскую партию одинаково, ход в ход.
  test('sea: bot match is identical to the server', () {
    String signature(int players, int seed) {
      final game = DominoGame.newGame(
        [for (var i = 0; i < players; i++) 'p$i'],
        seed,
        dominoModeSea,
      );
      var pairs = 0;
      for (var step = 0; step < 20000 && !game.isOver; step++) {
        if (game.status == dominoStatusRoundEnd) {
          game.apply(const DominoAction(type: dominoActionNextRound));
          continue;
        }
        final action = dominoBestAction(game, game.turn);
        if (action.type == dominoActionPlayPair) pairs++;
        game.apply(action);
      }
      final scores =
          [for (final player in game.players) player.score].join(',');
      return 'goat=${game.goatSeat} scores=$scores events=${game.eventSeq} '
          'rounds=${game.round} pairs=$pairs';
    }

    expect(
        signature(2, 3), 'goat=1 scores=25,125 events=336 rounds=13 pairs=5');
    expect(signature(2, 11), 'goat=0 scores=136,0 events=221 rounds=8 pairs=1');
    expect(
        signature(3, 5), 'goat=1 scores=33,50,0 events=350 rounds=12 pairs=7');
    expect(
      signature(4, 9),
      'goat=2 scores=75,50,150,0 events=1047 rounds=41 pairs=16',
    );
  });
}
