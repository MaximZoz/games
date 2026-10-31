import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';

/// Мгновенно применяет уже выбранный легальный ход, не дожидаясь сервера.
///
/// Шашка едет сразу. Сервер остаётся источником истины: когда его `seq`
/// догоняет оптимистичный, снимок сбрасывается.
CheckersGameView checkersViewAfterMove(CheckersGameView g, CheckersMove mv) {
  final engine = CheckersEngine(
    mode: g.gameMode,
    board: List<int>.from(g.board),
    turn: g.turn,
    seq: g.seq,
    mustContinue: g.mustContinue,
    contR: g.contR,
    contC: g.contC,
    lastFromR: g.lastFromR,
    lastFromC: g.lastFromC,
    lastToR: g.lastToR,
    lastToC: g.lastToC,
    drawReason: g.drawReason,
  );
  engine.apply(g.turn, mv);
  final over = engine.isOver;
  final draw = engine.winner == CheckersEngine.winnerDraw;
  final winner = engine.winner >= 0 ? engine.winner : -1;
  return CheckersGameView(
    id: g.id,
    lobbyId: g.lobbyId,
    gameMode: g.gameMode,
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
    players: g.players,
    playerIds: g.playerIds,
    legalMoves: engine.legalMoves(),
    myIndex: g.myIndex,
    isMyTurn: !over && engine.turn == g.myIndex,
    turnTimeSec: g.turnTimeSec,
    turnDeadline: g.turnDeadline,
    stakeBronze: g.stakeBronze,
    isOver: over,
    winnerIndex: winner,
    winnerUserId: winner >= 0 && winner < g.playerIds.length
        ? g.playerIds[winner]
        : '',
    isDraw: draw,
    drawReason: draw ? engine.drawReason : '',
    isForfeit: g.isForfeit,
    isTimeout: g.isTimeout,
    drawOfferBy: g.drawOfferBy,
  );
}
