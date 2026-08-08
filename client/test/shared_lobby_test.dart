import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/shared_lobby.dart';

void main() {
  group('LobbyGameKind', () {
    test('normalize', () {
      expect(LobbyGameKind.normalize('durak'), LobbyGameKind.durak);
      expect(LobbyGameKind.normalize('tictactoe'), LobbyGameKind.tictactoe);
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
}
