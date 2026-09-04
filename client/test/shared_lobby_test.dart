import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/shared_lobby.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  group('LobbyGameKind', () {
    test('normalize', () {
      expect(LobbyGameKind.normalize('durak'), LobbyGameKind.durak);
      expect(LobbyGameKind.normalize('tictactoe'), LobbyGameKind.tictactoe);
      expect(LobbyGameKind.normalize('nardy'), LobbyGameKind.nardy);
      expect(LobbyGameKind.normalize('battleship'), LobbyGameKind.battleship);
      expect(LobbyGameKind.normalize(null), LobbyGameKind.tictactoe);
      expect(LobbyGameKind.normalize(''), LobbyGameKind.tictactoe);
    });

    test('lobbyPath', () {
      expect(
        LobbyGameKind.lobbyPath('abc', gameType: 'durak'),
        '/games/durak/lobby/abc',
      );
      expect(
        LobbyGameKind.lobbyPath('xyz', gameType: 'tictactoe'),
        '/games/tictactoe/lobby/xyz',
      );
    });
  });

  group('lobbyAppBarTitle', () {
    test('invite — Своя игра для всех игр', () {
      expect(lobbyAppBarTitle(initialMode: 'invite'), 'Своя игра');
      expect(
        lobbyAppBarTitle(status: 'waiting_invite', lobbyMode: 'invite'),
        'Своя игра',
      );
    });

    test('matchmake — Лобби сразу, без вспышки своей игры', () {
      expect(lobbyAppBarTitle(initialMode: 'matchmake'), 'Лобби');
      expect(
        lobbyAppBarTitle(
          status: 'waiting_invite',
          lobbyMode: 'matchmake',
          initialMode: 'invite',
        ),
        'Лобби',
      );
    });

    test('без режима заголовок пустой, а не название игры', () {
      expect(lobbyAppBarTitle(), isEmpty);
    });
  });

  group('normalizeLobbyMode', () {
    test('принимает только invite и matchmake', () {
      expect(normalizeLobbyMode('invite'), 'invite');
      expect(normalizeLobbyMode(' matchmake '), 'matchmake');
      expect(normalizeLobbyMode(''), isEmpty);
      expect(normalizeLobbyMode('podkidnoi'), isEmpty);
    });
  });
}
