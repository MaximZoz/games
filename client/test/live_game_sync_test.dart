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
      const ping = {
        'type': 'game_state',
        'game_id': 'g1',
        'game_type': 'durak'
      };
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

    test('keeps portraits when a move snapshot omits avatar fields', () {
      final http = GameStateItem.fromJson({
        'id': 'g1',
        'board': List.filled(9, ''),
        'turn': 'x',
        'status': 'active',
        'x_user_id': 'u1',
        'o_user_id': 'u2',
        't_user_id': 'u3',
        's_user_id': 'u4',
        'x_display_name': 'Макс',
        'o_display_name': 'Анна',
        'x_avatar_kind': 'preset',
        'x_avatar_value': '1',
        'o_avatar_kind': 'file',
        'o_avatar_value': 'base64,abc',
        'o_frame_code': 'frame_gold',
        'o_frame_color': '#ffd700',
        't_avatar_kind': 'preset',
        't_avatar_value': '6',
        's_avatar_kind': 'file',
        's_avatar_value': 'base64,def',
      });
      final ws = GameStateItem.fromJson({
        'type': 'game_state',
        'game_id': 'g1',
        'board': ['x', '', '', '', '', '', '', '', ''],
        'turn': 'o',
        'status': 'active',
        'x_user_id': 'u1',
        'o_user_id': 'u2',
        't_user_id': 'u3',
        's_user_id': 'u4',
      });
      expect(ws.oAvatarKnown, isFalse);
      expect(ws.oAvatarKind, 'letter');
      final merged = http.mergePreservingIdentity(ws);
      expect(merged.board[0], 'x');
      expect(merged.turn, 'o');
      expect(merged.oAvatarKind, 'file');
      expect(merged.oAvatarValue, 'base64,abc');
      expect(merged.xAvatarKind, 'preset');
      expect(merged.xAvatarValue, '1');
      expect(merged.tAvatarKind, 'preset');
      expect(merged.tAvatarValue, '6');
      expect(merged.sAvatarKind, 'file');
      expect(merged.sAvatarValue, 'base64,def');
      expect(merged.oDisplayName, 'Анна');
      expect(merged.oFrameCode, 'frame_gold');
      expect(merged.oFrameColor, '#ffd700');

      final explicit = GameStateItem.fromJson({
        'id': 'g1',
        'board': ['x', 'o', '', '', '', '', '', '', ''],
        'turn': 'x',
        'status': 'active',
        'x_user_id': 'u1',
        'o_user_id': 'u2',
        'o_avatar_kind': 'letter',
      });
      final replaced = merged.mergePreservingIdentity(explicit);
      expect(replaced.board[1], 'o');
      expect(replaced.oAvatarKind, 'letter');
      expect(replaced.oAvatarValue, isNull);
      expect(replaced.xAvatarKind, 'preset');
      expect(replaced.xAvatarValue, '1');
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
        bool lastWasTake = false,
        int deckCount = 20,
        List<DurakHandView> hands = const [
          DurakHandView(count: 4),
          DurakHandView(count: 2),
        ],
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
          hands: hands,
          deckCount: deckCount,
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
          lastWasTake: lastWasTake,
        );
      }

      final beforeTake = view(bito: 2, tablePairs: 3);
      final afterTake = view(
        bito: 2,
        tablePairs: 0,
        lastWasTake: true,
        hands: const [
          DurakHandView(count: 4),
          DurakHandView(count: 5),
        ],
      );
      expect(isOlderDurak(afterTake, beforeTake), isFalse);
      expect(isOlderDurak(view(bito: 1, tablePairs: 0), beforeTake), isTrue);
      expect(isOlderDurak(view(bito: 2, tablePairs: 1), beforeTake), isTrue);
      expect(
        isOlderDurak(
          view(bito: 2, tablePairs: 3, deckCount: 24),
          beforeTake,
        ),
        isTrue,
      );
      expect(
        isOlderDurak(beforeTake, afterTake),
        isTrue,
      );
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
        isOlderPoker(
            poker(hand: 1, street: 'preflop'), poker(hand: 1, street: 'flop')),
        isTrue,
      );
    });

    test('фолд-вина (street over) не старше preflop той же руки', () {
      PokerGameView poker({
        required int hand,
        required String street,
        bool handOver = false,
        bool tableOver = false,
        bool isOver = false,
      }) {
        return PokerGameView(
          id: 'g',
          status: isOver ? 'over' : 'active',
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
          legalActions: const ['fold'],
          callAmount: 0,
          minRaiseTo: 0,
          maxRaiseTo: 0,
          turnTimeSec: 0,
          turnDeadline: 0,
          stakeBronze: 0,
          winners: const [],
          winnerIds: const [],
          isOver: isOver,
          isForfeit: false,
          isTimeout: false,
          handNumber: hand,
          blindLevel: 1,
          handsPerLevel: 0,
          isHandOver: handOver,
          isTableOver: tableOver,
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

      final preflop = poker(hand: 3, street: 'preflop');
      final foldWin = poker(hand: 3, street: 'over', handOver: true);
      expect(pokerStreetRank('over'), 6);
      expect(isOlderPoker(foldWin, preflop), isFalse);
      expect(isOlderPoker(preflop, foldWin), isTrue);
      expect(pokerProgress(foldWin), greaterThan(pokerProgress(preflop)));
    });

    test('кнопки хода не возвращаются после своего фолда', () {
      expect(
        pokerShouldKeepActionBarHidden(
          hideUntilSync: true,
          isMyTurn: true,
          isHandOver: false,
          isOver: false,
          meFolded: false,
        ),
        isTrue,
      );
      expect(
        pokerShouldKeepActionBarHidden(
          hideUntilSync: true,
          isMyTurn: true,
          isHandOver: true,
          isOver: false,
          meFolded: false,
        ),
        isFalse,
      );
      expect(
        pokerActionBarVisible(
          isOver: false,
          isHandOver: false,
          isMyTurn: true,
          hasLegalActions: true,
          meFolded: false,
          hideUntilSync: true,
        ),
        isFalse,
      );
      expect(
        pokerActionBarVisible(
          isOver: false,
          isHandOver: true,
          isMyTurn: false,
          hasLegalActions: true,
          meFolded: false,
          hideUntilSync: false,
        ),
        isFalse,
      );
    });

    test('кнопки возвращаются на новом решении того же игрока', () {
      PokerGameView view({
        required String street,
        int pot = 40,
        int actingIndex = 1,
        int turnDeadline = 100,
        int community = 0,
      }) {
        return PokerGameView(
          id: 'g',
          status: 'active',
          street: street,
          lobbyId: '',
          chatId: null,
          playerIds: const ['a', 'b'],
          players: const [
            PokerPlayerView(
              id: 'a',
              seat: 0,
              chips: 100,
              bet: 20,
              folded: false,
              allIn: false,
              isActing: false,
            ),
            PokerPlayerView(
              id: 'b',
              seat: 1,
              chips: 80,
              bet: 20,
              folded: false,
              allIn: false,
              isActing: true,
            ),
          ],
          community: List<PokerApiCard>.filled(
            community,
            const PokerApiCard(14, 'H'),
          ),
          pot: pot,
          currentBet: 20,
          minRaise: 20,
          smallBlind: 10,
          bigBlind: 20,
          dealerIndex: 0,
          actingIndex: actingIndex,
          myIndex: 1,
          legalActions: const ['fold', 'check', 'raise'],
          callAmount: 0,
          minRaiseTo: 40,
          maxRaiseTo: 100,
          turnTimeSec: 30,
          turnDeadline: turnDeadline,
          stakeBronze: 0,
          winners: const [],
          winnerIds: const [],
          isOver: false,
          isForfeit: false,
          isTimeout: false,
          handNumber: 2,
        );
      }

      final preflop = view(street: 'preflop');
      final flop = view(street: 'flop', community: 3, turnDeadline: 140);
      expect(pokerDecisionKey(preflop), pokerDecisionKey(preflop));
      expect(pokerDecisionKey(flop), isNot(pokerDecisionKey(preflop)));
      expect(
        pokerShouldKeepActionBarHidden(
          hideUntilSync: true,
          isMyTurn: flop.isMyTurn,
          isHandOver: false,
          isOver: false,
          meFolded: false,
          decisionChanged: pokerDecisionKey(flop) != pokerDecisionKey(preflop),
        ),
        isFalse,
      );
      expect(
        pokerActionBarVisible(
          isOver: false,
          isHandOver: false,
          isMyTurn: flop.isMyTurn,
          hasLegalActions: flop.legalActions.isNotEmpty,
          meFolded: false,
          hideUntilSync: false,
        ),
        isTrue,
      );

      final same = view(street: 'preflop');
      expect(
        pokerShouldKeepActionBarHidden(
          hideUntilSync: true,
          isMyTurn: true,
          isHandOver: false,
          isOver: false,
          meFolded: false,
          decisionChanged: pokerDecisionKey(same) != pokerDecisionKey(preflop),
        ),
        isTrue,
      );
    });

    test('профиль игрока покера читает возраст, пол и о себе', () {
      final player = PokerPlayerView.fromJson({
        'id': 'user-1',
        'seat': 1,
        'chips': 100,
        'bet': 0,
        'age': 27,
        'gender': 'female',
        'about': '  играю по вечерам  ',
      });
      expect(player.age, 27);
      expect(player.gender, 'female');
      expect(player.about, 'играю по вечерам');
    });
  });
}
