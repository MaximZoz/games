import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  group('GameStateItem.winLength', () {
    test('3–5 use N, 6–8 use 5', () {
      expect(GameStateItem.winLength(3), 3);
      expect(GameStateItem.winLength(4), 4);
      expect(GameStateItem.winLength(5), 5);
      expect(GameStateItem.winLength(6), 5);
      expect(GameStateItem.winLength(7), 5);
      expect(GameStateItem.winLength(8), 5);
    });
  });

  group('effectiveWinningCells', () {
    GameStateItem game({
      required List<String> board,
      required String status,
      String? winner,
      int gridSize = 3,
      List<int>? winningCells,
    }) {
      return GameStateItem(
        id: 'g1',
        board: board,
        turn: 'x',
        status: status,
        winner: winner,
        xUserId: 'u1',
        oUserId: 'u2',
        gridSize: gridSize,
        winningCells: winningCells,
      );
    }

    test('uses server winningCells when length matches', () {
      final g = game(
        board: List.filled(9, ''),
        status: 'x_won',
        winner: 'x',
        winningCells: const [0, 1, 2],
      );
      expect(g.effectiveWinningCells, [0, 1, 2]);
    });

    test('computes row win when winningCells missing', () {
      final board = ['x', 'x', 'x', '', '', '', '', '', ''];
      final g = game(board: board, status: 'x_won', winner: 'x');
      expect(g.effectiveWinningCells, [0, 1, 2]);
    });

    test('computes diagonal win', () {
      final board = ['o', '', '', '', 'o', '', '', '', 'o'];
      final g = game(board: board, status: 'o_won', winner: 'o');
      expect(g.effectiveWinningCells, [0, 4, 8]);
    });

    test('returns null when not finished', () {
      final g = game(
        board: List.filled(9, ''),
        status: 'active',
        winner: null,
      );
      expect(g.effectiveWinningCells, isNull);
    });

    test('4x4 needs four in a row', () {
      final board = List.filled(16, '');
      board[0] = board[1] = board[2] = 'x';
      var g = game(
        board: board,
        status: 'x_won',
        winner: 'x',
        gridSize: 4,
      );
      expect(g.effectiveWinningCells, isNull);
      board[3] = 'x';
      g = game(board: board, status: 'x_won', winner: 'x', gridSize: 4);
      expect(g.effectiveWinningCells, [0, 1, 2, 3]);
    });
  });

  group('GameStateItem.fromJson', () {
    test('pads board and parses frames/stake', () {
      final g = GameStateItem.fromJson({
        'id': 'abc',
        'board': ['x'],
        'turn': 'o',
        'status': 'active',
        'grid_size': 3,
        'x_user_id': 'x1',
        'o_user_id': 'o1',
        'stake_bronze': 100,
        'x_frame_color': '#FFD700',
        'x_frame_code': 'frame_gold',
        'winning_cells': [0, 1],
      });
      expect(g.board.length, 9);
      expect(g.board[0], 'x');
      expect(g.stakeBronze, 100);
      expect(g.xFrameCode, 'frame_gold');
      expect(g.xFrameColor, '#FFD700');
      // too short winning_cells → null
      expect(g.winningCells, isNull);
    });

    test('accepts winning_cells of valid length', () {
      final g = GameStateItem.fromJson({
        'id': 'abc',
        'board': List.filled(9, ''),
        'status': 'x_won',
        'winner': 'x',
        'x_user_id': 'x1',
        'o_user_id': 'o1',
        'winning_cells': [0, 1, 2],
      });
      expect(g.winningCells, [0, 1, 2]);
    });
  });

  group('LobbyItem.fromJson', () {
    test('parses flags and defaults', () {
      final lobby = LobbyItem.fromJson({
        'id': 'L1',
        'creator_id': 'c1',
        'creator_name': 'Bob',
        'status': 'waiting_invite',
        'created_at': '2026-01-01T00:00:00Z',
        'turn_time_sec': 30,
        'grid_size': 5,
        'swap_rule': true,
        'first_move_restriction': true,
        'stake_bronze': 50,
      });
      expect(lobby.turnTimeSec, 30);
      expect(lobby.gridSize, 5);
      expect(lobby.swapRule, isTrue);
      expect(lobby.firstMoveRestriction, isTrue);
      expect(lobby.stakeBronze, 50);
      expect(lobby.creatorName, 'Bob');
    });
  });
}
