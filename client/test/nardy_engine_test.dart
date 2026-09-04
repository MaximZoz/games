import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_bot.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

int _total(NardyEngine game, int seat) {
  var total = game.bar[seat] + game.off[seat];
  for (var t = 0; t < nardyPoints; t++) {
    total += game.countAt(seat, t);
  }
  return total;
}

void main() {
  group('стартовая расстановка', () {
    test('короткие нарды — классические 2/5/3/5 у обоих', () {
      final game = NardyEngine.newGame(nardyModeShort);
      for (final seat in [0, 1]) {
        expect(_total(game, seat), nardyCheckers);
        expect(game.countAt(seat, 0), 2);
        expect(game.countAt(seat, 11), 5);
        expect(game.countAt(seat, 16), 3);
        expect(game.countAt(seat, 18), 5);
      }
      expect(game.board[23], 2);
      expect(game.board[0], -2);
    });

    test('длинные нарды — 15 шашек на своей голове', () {
      final game = NardyEngine.newGame(nardyModeLong);
      expect(game.countAt(0, 0), nardyCheckers);
      expect(game.countAt(1, 0), nardyCheckers);
      expect(game.board[23], nardyCheckers);
      expect(game.board[11], -nardyCheckers);
    });
  });

  test('дорожка и физический пункт переводятся туда и обратно', () {
    for (final mode in [nardyModeShort, nardyModeLong]) {
      for (var seat = 0; seat < 2; seat++) {
        for (var track = 0; track < nardyPoints; track++) {
          final point = nardyTrackToBoard(mode, seat, track);
          expect(point, inInclusiveRange(0, nardyPoints - 1));
          expect(nardyBoardToTrack(mode, seat, point), track);
        }
      }
    }
  });

  group('длинные нарды', () {
    test('с головы уходит одна шашка за ход', () {
      final game = NardyEngine.newGame(nardyModeLong);
      expect(game.rollWith(5, 2), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 5)), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 2)), isFalse);
      expect(game.legalMoves().any((mv) => mv.from == 0), isFalse);
    });

    test('первый ход 6-6 разрешает две шашки с головы', () {
      final game = NardyEngine.newGame(nardyModeLong);
      expect(game.rollWith(6, 6), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 6)), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 6)), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 6)), isFalse);
    });

    test('2-2 исключением не является', () {
      final game = NardyEngine.newGame(nardyModeLong);
      expect(game.rollWith(2, 2), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 2)), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 2)), isFalse);
    });

    test('чужой пункт закрыт — боя нет', () {
      final game = NardyEngine.newGame(nardyModeLong);
      game.debugSetPosition(
        tracksForSeat0: {0: 1},
        // Пункт дорожки 3 белых занят чёрной шашкой.
        tracksForSeat1: {
          nardyBoardToTrack(
            nardyModeLong,
            1,
            nardyTrackToBoard(nardyModeLong, 0, 3),
          ): 1,
        },
      );
      expect(game.canLand(0, 3), isFalse);
      expect(game.opponentAt(0, 3), 1);
    });
  });

  group('короткие нарды', () {
    test('одиночная шашка соперника уходит на бар', () {
      final game = NardyEngine.newGame(nardyModeShort);
      game.debugSetPosition(
        tracksForSeat0: {0: 1},
        tracksForSeat1: {
          nardyBoardToTrack(
            nardyModeShort,
            1,
            nardyTrackToBoard(nardyModeShort, 0, 3),
          ): 1,
        },
      );
      expect(game.rollWith(3, 4), isTrue);
      expect(game.applyMove(0, const NardyMove(0, 3)), isTrue);
      expect(game.bar[1], 1);
      expect(game.countAt(0, 3), 1);
    });

    test('шашка с бара вводится в игру первой', () {
      final game = NardyEngine.newGame(nardyModeShort);
      game.debugSetPosition(clear: false, bar: [1, 0]);
      expect(game.rollWith(1, 2), isTrue);
      expect(
        game.legalMoves().every((mv) => mv.from == nardyBarTrack),
        isTrue,
      );
      expect(game.applyMove(0, const NardyMove(nardyBarTrack, 1)), isTrue);
      expect(game.bar[0], 0);
    });
  });

  test('выброс только когда все шашки дома', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.debugSetPosition(
      tracksForSeat0: {20: 1, 10: 1},
      tracksForSeat1: {0: 2},
    );
    expect(game.allHome(0), isFalse);
    game.debugSetPosition(
      tracksForSeat0: {20: 1, 21: 1},
      tracksForSeat1: {0: 2},
    );
    expect(game.allHome(0), isTrue);
    expect(game.rollWith(4, 3), isTrue);
    expect(game.applyMove(0, const NardyMove(20, 4)), isTrue);
    expect(game.off[0], 1);
  });

  test('перебор снимает только с самого дальнего пункта', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.debugSetPosition(
      tracksForSeat0: {21: 1, 22: 1},
      tracksForSeat1: {0: 2},
    );
    expect(game.rollWith(6, 1), isTrue);
    expect(game.applyMove(0, const NardyMove(22, 6)), isFalse);
    expect(game.applyMove(0, const NardyMove(21, 6)), isTrue);
  });

  test('снятие всех шашек при нулях соперника — марс', () {
    final game = NardyEngine.newGame(nardyModeLong);
    game.debugSetPosition(
      tracksForSeat0: {23: 1},
      tracksForSeat1: {0: nardyCheckers},
      off: [nardyCheckers - 1, 0],
    );
    expect(game.rollWith(1, 1), isTrue);
    expect(game.applyMove(0, const NardyMove(23, 1)), isTrue);
    expect(game.winner, 0);
    expect(game.winKind, 'mars');
  });

  test('бросок без ходов сразу передаёт ход и оставляет кубики видимыми', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.debugSetPosition(
      tracksForSeat1: {
        for (var track = 0; track < 6; track++)
          nardyBoardToTrack(
            nardyModeShort,
            1,
            nardyTrackToBoard(nardyModeShort, 0, track),
          ): 2,
      },
      bar: [1, 0],
    );
    expect(game.rollWith(3, 4), isTrue);
    expect(game.turn, 1);
    expect(game.rolled, isNotEmpty);
  });

  test('пипсы учитывают бар', () {
    final game = NardyEngine.newGame(nardyModeLong);
    expect(game.pips(0), nardyCheckers * nardyPoints);
    game.debugSetPosition(clear: false, bar: [1, 0]);
    expect(game.pips(0), nardyCheckers * nardyPoints + nardyPoints + 1);
  });

  test('сдача отдаёт победу сопернику', () {
    final game = NardyEngine.newGame(nardyModeShort);
    game.forfeit(1);
    expect(game.winner, 0);
    expect(game.dice, isEmpty);
  });

  group('длинные нарды: шесть подряд', () {
    NardyEngine longGame({
      required Map<int, int> mine,
      required Map<int, int> theirs,
      List<int>? off,
    }) {
      final game = NardyEngine.newGame(nardyModeLong);
      game.debugSetPosition(
        tracksForSeat0: mine,
        tracksForSeat1: theirs,
        off: off,
      );
      return game;
    }

    test('ряд из шести запрещён, пока соперник целиком позади', () {
      final game = longGame(
        mine: {5: 1, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2},
        theirs: {0: nardyCheckers},
      );
      expect(game.rollWith(6, 3), isTrue);
      expect(
        game.legalMoves().where((m) => m.from == 5 && m.die == 6),
        isEmpty,
      );
      expect(game.applyMove(0, const NardyMove(5, 6)), isFalse);
    });

    test('ряд разрешён, когда чужая шашка уже прошла блок', () {
      final game = longGame(
        mine: {5: 1, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2},
        theirs: {0: nardyCheckers - 1, 20: 1},
      );
      expect(game.rollWith(6, 3), isTrue);
      expect(
        game.legalMoves().where((m) => m.from == 5 && m.die == 6),
        isNotEmpty,
      );
    });

    test('пять подряд строить можно', () {
      final game = longGame(
        mine: {5: 1, 6: 2, 7: 2, 8: 2, 9: 2},
        theirs: {0: nardyCheckers},
      );
      expect(game.rollWith(5, 3), isTrue);
      expect(
        game.legalMoves().where((m) => m.from == 5 && m.die == 5),
        isNotEmpty,
      );
    });

    test('в коротких нардах блок из шести законен', () {
      final game = NardyEngine.newGame(nardyModeShort);
      game.debugSetPosition(
        tracksForSeat0: {5: 1, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2},
        tracksForSeat1: {0: nardyCheckers},
      );
      expect(game.rollWith(6, 3), isTrue);
      expect(
        game.legalMoves().where((m) => m.from == 5 && m.die == 6),
        isNotEmpty,
      );
    });

    test('снятая с доски шашка считается прошедшей блок', () {
      final game = longGame(
        mine: {5: 2, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2},
        theirs: {0: nardyCheckers - 1},
      );
      expect(
        nardyHasSealedPrime(
          mode: nardyModeLong,
          seat: 0,
          board: game.board,
          opponentOff: 0,
        ),
        isTrue,
      );
      expect(
        nardyHasSealedPrime(
          mode: nardyModeLong,
          seat: 0,
          board: game.board,
          opponentOff: 1,
        ),
        isFalse,
      );
    });
  });

  for (final mode in [nardyModeShort, nardyModeLong]) {
    test('бот доигрывает партию ($mode) без потери шашек', () {
      final game = NardyEngine.newGame(mode);
      final rng = math.Random(5);
      for (var i = 0; i < 5000 && !game.isOver; i++) {
        if (game.dice.isEmpty) {
          game.roll(rng);
          continue;
        }
        final mv = nardyBotBestMove(game, rng);
        if (mv == null) {
          game.endTurn();
          continue;
        }
        expect(game.applyMove(game.turn, mv), isTrue);
        for (var seat = 0; seat < 2; seat++) {
          expect(_total(game, seat), nardyCheckers);
        }
      }
      expect(game.isOver, isTrue);
      expect(game.off[game.winner], nardyCheckers);
    });
  }
}
