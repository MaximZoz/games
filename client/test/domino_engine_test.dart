import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/domino/domino_bot.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';

DominoGame freshGame(List<List<int>> hands, List<int> boneyard, int left, int right) {
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
    expect(back.boneyard, hasLength(game.boneyard.length));
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
    out.apply(DominoAction(type: dominoActionPlay, tile: dominoTileId(1, 1), end: 'left'));
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

    final blank = freshGame([
      [dominoTileId(0, 0), dominoTileId(1, 2)],
      [dominoTileId(6, 6)],
    ], const [], 0, 5);
    blank.mode = dominoModeSea;
    blank.target = dominoSeaScore;
    blank.apply(DominoAction(type: dominoActionPlay, tile: dominoTileId(0, 0), end: 'left'));
    expect(blank.roundKind, dominoRoundFast);
    expect(blank.players[1].score, dominoSeaBlankHit);
    expect(blank.players[0].hand, hasLength(1));

    final six = freshGame([
      [dominoTileId(6, 6)],
      [dominoTileId(5, 5)],
    ], const [], 6, 1);
    six.mode = dominoModeSea;
    six.target = dominoSeaScore;
    six.players[0].score = 40;
    six.apply(DominoAction(type: dominoActionPlay, tile: dominoTileId(6, 6), end: 'left'));
    expect(six.players[0].score, 0);
    expect(six.players[1].score, dominoSeaSixHit);
  });
}
