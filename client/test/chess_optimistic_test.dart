import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_optimistic.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';

ChessGameView _view(List<int> board, {int turn = 0, int myIndex = 0}) =>
    ChessGameView(
      id: 'g',
      lobbyId: 'l',
      gameMode: ChessEngine.modeClassic,
      board: board,
      turn: turn,
      seq: 5,
      inCheck: false,
      lastFromR: -1,
      lastFromC: -1,
      lastToR: -1,
      lastToC: -1,
      players: const [],
      playerIds: const [],
      legalMoves: const [],
      myIndex: myIndex,
      isMyTurn: turn == myIndex,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isOver: false,
      winnerIndex: -1,
      winnerUserId: '',
      isDraw: false,
    );

int _i(int r, int c) => r * ChessEngine.size + c;

void main() {
  test('обычный ход двигает фигуру и передаёт ход сопернику', () {
    final board = ChessEngine.newGame(ChessEngine.modeClassic).board;
    final v = chessViewAfterMove(
      _view(board),
      const ChessMove(from: ChessSquare(1, 4), to: ChessSquare(3, 4)),
    );
    expect(v.board[_i(3, 4)], ChessEngine.whitePawn);
    expect(v.board[_i(1, 4)], ChessEngine.empty);
    expect(v.turn, 1);
    expect(v.seq, 6);
    expect(v.isMyTurn, isFalse);
    expect(v.lastFromR, 1);
    expect(v.lastToR, 3);
  });

  test('рокировка двигает и короля, и ладью', () {
    final board = List<int>.filled(64, ChessEngine.empty);
    board[_i(0, 4)] = ChessEngine.whiteKing;
    board[_i(0, 7)] = ChessEngine.whiteRook;
    board[_i(7, 4)] = ChessEngine.blackKing;
    final v = chessViewAfterMove(
      _view(board),
      const ChessMove(from: ChessSquare(0, 4), to: ChessSquare(0, 6)),
    );
    expect(v.board[_i(0, 6)], ChessEngine.whiteKing);
    expect(v.board[_i(0, 5)], ChessEngine.whiteRook);
    expect(v.board[_i(0, 7)], ChessEngine.empty);
  });

  test('взятие на проходе снимает пешку соперника', () {
    final board = List<int>.filled(64, ChessEngine.empty);
    board[_i(4, 4)] = ChessEngine.whitePawn;
    board[_i(4, 5)] = ChessEngine.blackPawn;
    board[_i(0, 0)] = ChessEngine.whiteKing;
    board[_i(7, 7)] = ChessEngine.blackKing;
    final v = chessViewAfterMove(
      _view(board),
      const ChessMove(from: ChessSquare(4, 4), to: ChessSquare(5, 5)),
    );
    expect(v.board[_i(5, 5)], ChessEngine.whitePawn);
    expect(v.board[_i(4, 4)], ChessEngine.empty);
    expect(v.board[_i(4, 5)], ChessEngine.empty);
  });

  test('превращение пешки ставит выбранную фигуру', () {
    final board = List<int>.filled(64, ChessEngine.empty);
    board[_i(6, 0)] = ChessEngine.whitePawn;
    board[_i(0, 4)] = ChessEngine.whiteKing;
    board[_i(7, 7)] = ChessEngine.blackKing;
    final v = chessViewAfterMove(
      _view(board),
      const ChessMove(
        from: ChessSquare(6, 0),
        to: ChessSquare(7, 0),
        promo: ChessEngine.whiteQueen,
      ),
    );
    expect(v.board[_i(7, 0)], ChessEngine.whiteQueen);
    expect(v.board[_i(6, 0)], ChessEngine.empty);
  });
}
