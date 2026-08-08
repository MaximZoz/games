import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';

DurakGameView _view({
  required String status,
  required int myIndex,
  required int loserIndex,
  required List<int> finished,
  List<int> eliminated = const [],
  int stakeBronze = 2,
}) {
  const trump = DurakApiCard(6, 'H');
  return DurakGameView(
    id: 'g1',
    status: status,
    lobbyId: 'l1',
    chatId: null,
    mode: 'podkidnoi',
    deckSize: 36,
    playerIds: const ['a', 'b', 'c'],
    players: const [],
    hands: const [
      DurakHandView(count: 0, cards: []),
      DurakHandView(count: 1, cards: []),
      DurakHandView(count: 0, cards: []),
    ],
    deckCount: 0,
    trumpSuit: 'hearts',
    trumpCard: trump,
    table: const [],
    bitoCount: 0,
    attackerIndex: 0,
    defenderIndex: 1,
    phase: 'attack',
    myIndex: myIndex,
    legalAttack: const [],
    legalDefend: const [],
    loserIndex: loserIndex,
    finished: finished,
    eliminated: eliminated,
    turnTimeSec: 0,
    turnDeadline: 0,
    stakeBronze: stakeBronze,
  );
}

void main() {
  group('DurakGameView place order after eliminate', () {
    test('includes last remaining player as 2nd place', () {
      final view = _view(
        status: 'over',
        myIndex: 1,
        loserIndex: 1,
        finished: const [0],
        eliminated: const [2],
      );
      expect(view.winnerPlaceOrder, [0, 1]);
      expect(view.myPlace, 2);
    });

    test('winner is 1st; eliminated has no place', () {
      final winner = _view(
        status: 'over',
        myIndex: 0,
        loserIndex: 1,
        finished: const [0],
        eliminated: const [2],
      );
      expect(winner.myPlace, 1);

      final out = _view(
        status: 'over',
        myIndex: 2,
        loserIndex: 1,
        finished: const [0],
        eliminated: const [2],
      );
      expect(out.myPlace, 0);
    });

    test('classic fool without eliminate still has no place', () {
      final fool = _view(
        status: 'over',
        myIndex: 2,
        loserIndex: 2,
        finished: const [0, 1],
      );
      expect(fool.winnerPlaceOrder, [0, 1]);
      expect(fool.myPlace, 0);
    });
  });
}
