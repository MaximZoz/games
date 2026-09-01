import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

GameStateItem ttt({
  required List<String> board,
  String turn = 'o',
  String status = 'active',
  String xUserId = '',
  String oUserId = '',
  String? xDisplayName,
}) {
  return GameStateItem(
    id: 'g1',
    board: board,
    turn: turn,
    status: status,
    xUserId: xUserId,
    oUserId: oUserId,
    xDisplayName: xDisplayName,
  );
}

void main() {
  group('full view detection', () {
    test('treats ping-only payloads as incomplete', () {
      const ping = {'type': 'game_state', 'game_id': 'g1', 'game_type': 'durak'};
      expect(hasFullTictactoeView(ping), isFalse);
      expect(hasFullBattleshipView(ping), isFalse);
      expect(hasFullDurakView(ping), isFalse);
      expect(hasFullUnoView(ping), isFalse);
      expect(hasFullPokerView(ping), isFalse);
    });

    test('detects tictactoe and battleship snapshots', () {
      expect(
        hasFullTictactoeView({
          'type': 'game_state',
          'game_id': 'g1',
          'board': List.filled(9, ''),
        }),
        isTrue,
      );
      expect(
        hasFullBattleshipView({
          'type': 'game_state',
          'phase': 'battle',
          'my_shots': const <int>[],
        }),
        isTrue,
      );
    });
  });

  group('tictactoe merge and progress', () {
    test('keeps names from HTTP when WS has only the board', () {
      final http = ttt(
        board: List.filled(9, ''),
        turn: 'x',
        xUserId: 'u1',
        oUserId: 'u2',
        xDisplayName: 'Макс',
      );
      final ws = GameStateItem.fromJson({
        'type': 'game_state',
        'game_id': 'g1',
        'board': ['x', '', '', '', '', '', '', '', ''],
        'turn': 'o',
        'status': 'active',
      });
      final merged = http.mergePreservingIdentity(ws);
      expect(merged.board[0], 'x');
      expect(merged.turn, 'o');
      expect(merged.xUserId, 'u1');
      expect(merged.oUserId, 'u2');
      expect(merged.xDisplayName, 'Макс');
    });

    test('rejects stale HTTP after a newer opponent move', () {
      final shown = ttt(
        board: ['x', 'o', '', '', '', '', '', '', ''],
        turn: 'x',
      );
      final stale = ttt(
        board: ['x', '', '', '', '', '', '', '', ''],
        turn: 'o',
      );
      expect(isOlderTictactoe(stale, shown), isTrue);
      expect(isOlderTictactoe(shown, stale), isFalse);
    });
  });

  group('progress guards', () {
    test('battleship ignores fewer shots', () {
      const older = BattleshipGameView(
        id: 'g',
        status: 'active',
        phase: 'battle',
        lobbyId: '',
        p1UserId: 'a',
        p2UserId: 'b',
        p1Ready: true,
        p2Ready: true,
        myShips: [],
        myShots: [1],
        myHits: [],
        opponentShots: [],
        opponentShipsHit: [],
        opponentSunkShips: [],
        opponentShips: [],
        isMyTurn: true,
        turn: 'a',
        turnTimeSec: 0,
        turnDeadline: 0,
        setupDeadline: 0,
        stakeBronze: 0,
      );
      final newer = older.copyWith(opponentShots: const [4, 5]);
      expect(isOlderBattleship(older, newer), isTrue);
    });

    test('durak does not treat take (same bito) as older', () {
      DurakGameView view({
        required int bito,
        required int tablePairs,
        String status = 'active',
      }) {
        return DurakGameView(
          id: 'g',
          status: status,
          lobbyId: '',
          chatId: null,
          mode: 'podkidnoi',
          deckSize: 36,
          playerIds: const ['a', 'b'],
          players: const [],
          hands: const [],
          deckCount: 20,
          trumpSuit: 'H',
          trumpCard: const DurakApiCard(14, 'H'),
          table: List.generate(
            tablePairs,
            (_) => const DurakTablePairApi(
              attack: DurakApiCard(6, 'S'),
            ),
          ),
          bitoCount: bito,
          attackerIndex: 0,
          defenderIndex: 1,
          phase: 'attack',
          myIndex: 0,
          legalAttack: const [],
          legalDefend: const [],
          loserIndex: -1,
          finished: const [],
          turnTimeSec: 0,
          turnDeadline: 0,
          stakeBronze: 0,
        );
      }

      final beforeTake = view(bito: 2, tablePairs: 3);
      final afterTake = view(bito: 2, tablePairs: 0);
      expect(isOlderDurak(afterTake, beforeTake), isFalse);
      expect(isOlderDurak(view(bito: 1, tablePairs: 0), beforeTake), isTrue);
    });

    test('uno uses eventSeq', () {
      UnoGameView uno(int seq) => UnoGameView(
            id: 'g',
            lobbyId: '',
            chatId: null,
            players: const [],
            topDiscard: null,
            drawCount: 0,
            currentColor: UnoColor.red,
            direction: 1,
            currentIndex: 0,
            currentUserId: '',
            myIndex: 0,
            status: 'active',
            pendingDraw: 0,
            drawnCardId: null,
            lastPlayedBy: null,
            roundNumber: 1,
            targetScore: 100,
            winnerUserIds: const [],
            eliminatedOrder: const [],
            lastRoundWinnerUserId: '',
            lastRoundPoints: 0,
            lastRoundNumber: 0,
            canChallengeUno: false,
            canCallUno: false,
            unoVulnerableAtMs: 0,
            canChallengeWd4: false,
            mustChooseColor: false,
            canKeepOrPlayDrawn: false,
            turnTimeSec: 0,
            turnDeadline: 0,
            stakeBronze: 0,
            isForfeit: false,
            isTimeout: false,
            eventSeq: seq,
            lastEventType: '',
            lastEventActor: '',
            lastDrawUserId: '',
            lastDrawCount: 0,
            lastEventCard: null,
            lastPlayedCards: const [],
          );
      expect(isOlderUno(uno(3), uno(4)), isTrue);
      expect(isOlderUno(uno(5), uno(4)), isFalse);
    });

    test('poker later street is newer', () {
      PokerGameView poker({required int hand, required String street}) {
        return PokerGameView(
          id: 'g',
          status: 'active',
          street: street,
          lobbyId: '',
          chatId: null,
          playerIds: const ['a', 'b'],
          players: const [],
          community: const [],
          pot: 0,
          currentBet: 0,
          minRaise: 0,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          actingIndex: 0,
          myIndex: 0,
          legalActions: const [],
          callAmount: 0,
          minRaiseTo: 0,
          maxRaiseTo: 0,
          turnTimeSec: 0,
          turnDeadline: 0,
          stakeBronze: 0,
          winners: const [],
          winnerIds: const [],
          isOver: false,
          isForfeit: false,
          isTimeout: false,
          handNumber: hand,
          blindLevel: 1,
          handsPerLevel: 0,
          isHandOver: false,
          isTableOver: false,
          canShowCards: false,
          myPlace: 0,
          iAmEliminated: false,
          eliminatedOrder: const [],
          myHandRank: null,
          myHandCards: const [],
          highlightedCards: const [],
          winnerHands: const [],
        );
      }

      expect(
        isOlderPoker(poker(hand: 1, street: 'preflop'), poker(hand: 1, street: 'flop')),
        isTrue,
      );
    });
  });
}
