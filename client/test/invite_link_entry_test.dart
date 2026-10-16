import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/invite_link_entry.dart';

void main() {
  test('гость по ссылке попадает на вкладку лобби, не в партию', () async {
    GameInvite? held;
    final next = await redirectGuestInviteLocation(
      uri: Uri.parse('/games/tictactoe/lobby/L1?mode=invite'),
      userId: 'guest',
      load: (route) async {
        expect(route.gameType, 'tictactoe');
        expect(route.lobbyId, 'L1');
        return InviteLobbyPeek(
          isMember: false,
          invite: GameInvite(
            lobbyId: 'L1',
            creatorId: 'host',
            creatorName: 'Zoz',
            gameType: 'tictactoe',
            turnTimeSec: 20,
            stakeBronze: 2,
          ),
        );
      },
      holdInvite: (invite) => held = invite,
    );
    final uri = Uri.parse('https://local.app$next');
    expect(uri.path, '/games');
    expect(uri.queryParameters['tab'], 'lobbies');
    expect(held?.creatorName, 'Zoz');
    expect(held?.lobbyId, 'L1');
  });

  test('хозяин своей игры остаётся в комнате ожидания', () async {
    final next = await redirectGuestInviteLocation(
      uri: Uri.parse('/games/tictactoe/lobby/L1?mode=invite'),
      userId: 'host',
      load: (_) async => const InviteLobbyPeek(isMember: true),
    );
    expect(next, isNull);
  });

  test('открытый поиск и ошибка сети не перехватываются', () async {
    var calls = 0;
    final matchmake = await redirectGuestInviteLocation(
      uri: Uri.parse('/games/durak/lobby/L2?mode=matchmake'),
      userId: 'guest',
      load: (_) async {
        calls += 1;
        return const InviteLobbyPeek(isMember: false);
      },
    );
    final failed = await redirectGuestInviteLocation(
      uri: Uri.parse('/games/uno/lobby/L9?mode=invite'),
      userId: 'guest',
      load: (_) async {
        calls += 1;
        return null;
      },
    );
    expect(matchmake, isNull);
    expect(failed, isNull);
    expect(calls, 1);
  });

  test('карточка только пока стол ждёт, имя хозяина из состава', () {
    final waiting = waitingInviteCard(
      lobbyId: 'L1',
      gameType: 'tictactoe',
      status: 'waiting_invite',
      creatorId: 'host',
      creatorName: '',
      players: [
        LobbyPlayer(id: 'host', displayName: 'Zoz'),
      ],
      turnTimeSec: 20,
      stakeBronze: 2,
      maxPlayers: 2,
      variant: 'classic',
    );
    expect(waiting?.creatorName, 'Zoz');
    expect(waiting?.turnTimeSec, 20);
    expect(
      waitingInviteCard(
        lobbyId: 'L1',
        gameType: 'tictactoe',
        status: 'in_game',
        creatorId: 'host',
        creatorName: 'Zoz',
        players: const [],
      ),
      isNull,
    );
  });
}
