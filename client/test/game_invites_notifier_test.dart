import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';

GameInvite invite({
  required String lobbyId,
  required String creatorId,
  String name = 'A',
}) {
  return GameInvite(
    lobbyId: lobbyId,
    creatorId: creatorId,
    creatorName: name,
    gameType: 'tictactoe',
  );
}

void main() {
  test('GameInvitesNotifier add dedupes by lobbyId', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L1', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L1', creatorId: 'c1', name: 'A2'));
    expect(n.state.length, 1);
    n.add(invite(lobbyId: 'L2', creatorId: 'c2', name: 'B'));
    expect(n.state.length, 2);
  });

  test('remove / removeByCreatorId / clear', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L1', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L2', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L3', creatorId: 'c2', name: 'B'));
    n.remove('L1');
    expect(n.state.map((e) => e.lobbyId), ['L2', 'L3']);
    n.removeByCreatorId('c1');
    expect(n.state.map((e) => e.lobbyId), ['L3']);
    n.clear();
    expect(n.state, isEmpty);
  });
}
