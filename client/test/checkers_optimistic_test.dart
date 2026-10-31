import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_optimistic.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';

CheckersGameView _view(CheckersEngine engine) {
  return CheckersGameView(
    id: 't',
    lobbyId: 'l',
    gameMode: engine.mode,
    board: List<int>.from(engine.board),
    turn: engine.turn,
    seq: engine.seq,
    mustContinue: engine.mustContinue,
    contR: engine.contR,
    contC: engine.contC,
    lastFromR: engine.lastFromR,
    lastFromC: engine.lastFromC,
    lastToR: engine.lastToR,
    lastToC: engine.lastToC,
    players: const [],
    playerIds: const ['a', 'b'],
    legalMoves: engine.legalMoves(),
    myIndex: 0,
    isMyTurn: engine.turn == 0,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: 0,
    isOver: engine.isOver,
    winnerIndex: -1,
    winnerUserId: '',
    isDraw: false,
  );
}

void main() {
  test('ход шашки виден до ответа сервера', () {
    final engine = CheckersEngine.newGame(CheckersEngine.modeRussian);
    engine.board = List<int>.filled(64, 0);
    engine.set(2, 1, CheckersEngine.whiteMan);
    engine.turn = 0;
    final move = engine.legalMoves().first;
    final next = checkersViewAfterMove(_view(engine), move);
    expect(next.seq, 1);
    expect(next.board[2 * 8 + 1], 0);
    expect(next.board[move.to.r * 8 + move.to.c], CheckersEngine.whiteMan);
    expect(next.isMyTurn, isFalse);
    expect(next.lastFromR, move.from.r);
    expect(next.lastToR, move.to.r);
  });

  test('взятие снимает шашку соперника сразу', () {
    final engine = CheckersEngine.newGame(CheckersEngine.modeRussian);
    engine.board = List<int>.filled(64, 0);
    engine.set(3, 2, CheckersEngine.whiteMan);
    engine.set(4, 3, CheckersEngine.blackMan);
    engine.turn = 0;
    final move = engine.legalMoves().first;
    final next = checkersViewAfterMove(_view(engine), move);
    expect(next.board[4 * 8 + 3], 0);
    expect(next.board[5 * 8 + 4], CheckersEngine.whiteMan);
  });
}
