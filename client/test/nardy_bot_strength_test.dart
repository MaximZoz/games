import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_bot.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

void main() {
  test('поиск не портит позицию', () {
    final game = NardyEngine.newGame(nardyModeShort);
    expect(game.rollWith(6, 5), isTrue);
    final board = List<int>.of(game.board);
    final dice = List<int>.of(game.dice);
    final mv = nardyBotBestMove(game, math.Random(1));
    expect(mv, isNotNull);
    expect(game.board, board);
    expect(game.dice, dice);
    expect(game.bar, [0, 0]);
    expect(game.off, [0, 0]);
  });

  test('бот бьёт blot, а не перекладывает дом', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.debugSetPosition(
      tracksForSeat0: const {
        10: 1,
        18: 2,
        19: 2,
        20: 2,
        21: 2,
        22: 3,
        23: 3,
      },
      tracksForSeat1: {
        nardyBoardToTrack(
          nardyModeShort,
          1,
          nardyTrackToBoard(nardyModeShort, 0, 13),
        ): 1,
        0: 14,
      },
    );
    expect(game.rollWith(3, 1), isTrue);
    expect(game.opponentAt(0, 13), 1);
    _playDice(game);
    expect(game.bar[1], greaterThan(0));
  });

  test('бот снимает шашку, чтобы не отдать марс', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.debugSetPosition(
      tracksForSeat0: const {18: 14, 23: 1},
      tracksForSeat1: const {20: 5},
      off: const [0, 10],
    );
    expect(game.rollWith(1, 2), isTrue);
    _playDice(game);
    expect(game.off[0], greaterThan(0));
  });
}

void _playDice(NardyEngine game) {
  final rng = math.Random(1);
  while (game.dice.isNotEmpty && !game.isOver) {
    final mv = nardyBotBestMove(game, rng);
    expect(mv, isNotNull);
    expect(game.applyMove(game.turn, mv!), isTrue);
  }
}
