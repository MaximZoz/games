import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';

/// Мгновенно (оптимистично) применяет уже выбранный легальный ход к позиции —
/// чтобы фигура «поехала» сразу, не дожидаясь ответа сервера. Сервер остаётся
/// источником истины: как только придёт его снимок с бо́льшим `seq`, оптимизм
/// сбрасывается.
///
/// Ход берётся из `game.legalMoves` (уже проверен сервером), поэтому достаточно
/// отразить его на доске: обычный ход, превращение, рокировку и взятие на
/// проходе. Точные права рокировки/EP знает сервер — для показа они не нужны.
ChessGameView chessViewAfterMove(ChessGameView g, ChessMove mv) {
  final board = List<int>.from(g.board);
  int i(int r, int c) => r * ChessEngine.size + c;
  final fromI = i(mv.from.r, mv.from.c);
  final toI = i(mv.to.r, mv.to.c);
  final piece = board[fromI];
  final mover = ChessEngine.colorOf(piece);
  final kind = ChessEngine.kind(piece);

  // Взятие на проходе: пешка пошла по диагонали на пустую клетку — снимаем
  // пешку соперника, стоящую на одной горизонтали с началом хода.
  if (kind == 1 && mv.from.c != mv.to.c && board[toI] == ChessEngine.empty) {
    board[i(mv.from.r, mv.to.c)] = ChessEngine.empty;
  }

  board[fromI] = ChessEngine.empty;
  var placed = piece;
  if (kind == 1 && mv.promo != 0) placed = mv.promo + mover * 6;
  board[toI] = placed;

  // Рокировка: король шагнул на две клетки — двигаем ладью.
  if (kind == 6 && (mv.to.c - mv.from.c).abs() == 2) {
    final home = mv.from.r;
    if (mv.to.c == 6) {
      board[i(home, 5)] = board[i(home, 7)];
      board[i(home, 7)] = ChessEngine.empty;
    } else {
      board[i(home, 3)] = board[i(home, 0)];
      board[i(home, 0)] = ChessEngine.empty;
    }
  }

  final nextTurn = 1 - g.turn;
  final probe = ChessEngine(mode: g.gameMode, board: board, turn: nextTurn);

  return ChessGameView(
    id: g.id,
    lobbyId: g.lobbyId,
    gameMode: g.gameMode,
    board: board,
    turn: nextTurn,
    seq: g.seq + 1,
    inCheck: probe.inCheck,
    lastFromR: mv.from.r,
    lastFromC: mv.from.c,
    lastToR: mv.to.r,
    lastToC: mv.to.c,
    players: g.players,
    playerIds: g.playerIds,
    legalMoves: const [],
    myIndex: g.myIndex,
    isMyTurn: false,
    turnTimeSec: g.turnTimeSec,
    turnDeadline: g.turnDeadline,
    stakeBronze: g.stakeBronze,
    isOver: g.isOver,
    winnerIndex: g.winnerIndex,
    winnerUserId: g.winnerUserId,
    isDraw: g.isDraw,
    drawReason: g.drawReason,
    isForfeit: g.isForfeit,
    isTimeout: g.isTimeout,
    drawOfferBy: null,
  );
}
