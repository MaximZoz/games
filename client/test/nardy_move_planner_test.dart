import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_move_planner.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

NardyGameView _viewFrom(NardyEngine engine) {
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
    players: const [],
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

void main() {
  test('одна шашка подсвечивает всю цепочку дубля', () {
    final engine = NardyEngine.newGame(nardyModeShort)
      ..debugSetPosition(
        tracksForSeat0: {0: 1},
        tracksForSeat1: {0: 1},
      )
      ..rollWith(4, 4);
    final targets = nardyMoveTargetsFor(_viewFrom(engine), 0);

    expect(targets.keys, containsAll([4, 8, 12, 16]));
    expect(targets[4]!.moves, [const NardyMove(0, 4)]);
    expect(targets[8]!.moves, [
      const NardyMove(0, 4),
      const NardyMove(4, 4),
    ]);
    expect(targets[12]!.moves, [
      const NardyMove(0, 4),
      const NardyMove(4, 4),
      const NardyMove(8, 4),
    ]);
  });

  test('три оставшихся одинаковых кубика дают три дальнейшие цели', () {
    final engine = NardyEngine.newGame(nardyModeShort)
      ..debugSetPosition(
        tracksForSeat0: {4: 1},
        tracksForSeat1: {0: 1},
      )
      ..rollWith(4, 4);
    // Один ход дубля уже потрачен.
    expect(engine.applyMove(0, const NardyMove(4, 4)), isTrue);
    final targets = nardyMoveTargetsFor(_viewFrom(engine), 8);

    expect(targets.keys, containsAll([12, 16, 20]));
    expect(targets[20]!.moves, [
      const NardyMove(8, 4),
      const NardyMove(12, 4),
      const NardyMove(16, 4),
    ]);
  });

  test('цепочка обрывается на заблокированном пункте', () {
    final engine = NardyEngine.newGame(nardyModeShort)
      ..debugSetPosition(
        tracksForSeat0: {0: 1},
        tracksForSeat1: {
          nardyBoardToTrack(
            nardyModeShort,
            1,
            nardyTrackToBoard(nardyModeShort, 0, 8),
          ): 2,
        },
      )
      ..rollWith(4, 4);
    final targets = nardyMoveTargetsFor(_viewFrom(engine), 0);

    expect(targets.keys, contains(4));
    expect(targets.keys, isNot(contains(8)));
    expect(targets.keys, isNot(contains(12)));
  });

  test('планировщик не отдаёт ходы, когда очередь не моя', () {
    final engine = NardyEngine.newGame(nardyModeShort)..rollWith(4, 4);
    final view = NardyGameView.fromJson({
      'id': 'g',
      'game_mode': nardyModeShort,
      'board': engine.board,
      'bar': engine.bar,
      'off': engine.off,
      'dice': engine.dice,
      'rolled': engine.rolled,
      'turn': 1,
      'turn_no': 0,
      'seq': 1,
      'head_moved': 0,
      'players': const [],
      'player_ids': const ['me', 'bot:nardy'],
      'legal_moves': const [],
      'my_index': 0,
      'is_my_turn': false,
    });

    expect(nardyMoveTargetsFor(view, 0), isEmpty);
  });

  test('оптимистичный снимок сразу меняет доску и сохраняет дедлайн', () {
    final engine = NardyEngine.newGame(nardyModeShort)
      ..debugSetPosition(
        tracksForSeat0: {0: 1},
        tracksForSeat1: {0: 1},
      )
      ..rollWith(4, 2);
    final view = _viewFrom(engine);
    final optimistic = nardyViewAfterMoves(view, [const NardyMove(0, 4)]);

    expect(optimistic.seq, view.seq + 1);
    expect(optimistic.board, isNot(view.board));
    expect(optimistic.myCountAt(0), 0);
    expect(optimistic.myCountAt(4), 1);
    expect(optimistic.dice, [2]);
    expect(optimistic.canUndo, isTrue);
    expect(optimistic.currentTurn.single.from, 0);
    expect(optimistic.currentTurn.single.to, 4);
    // Микродействие того же хода не должно менять таймер.
    expect(optimistic.turnDeadline, view.turnDeadline);
  });

  test('оптимистичный снимок цепочки применяет несколько ходов сразу', () {
    final engine = NardyEngine.newGame(nardyModeShort)
      ..debugSetPosition(
        tracksForSeat0: {0: 1},
        tracksForSeat1: {0: 1},
      )
      ..rollWith(4, 4);
    final view = _viewFrom(engine);
    final optimistic = nardyViewAfterMoves(view, [
      const NardyMove(0, 4),
      const NardyMove(4, 4),
      const NardyMove(8, 4),
    ]);

    expect(optimistic.myCountAt(12), 1);
    expect(optimistic.dice, [4]);
    expect(optimistic.currentTurn.map((m) => m.to), [4, 8, 12]);
  });
}
