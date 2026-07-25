import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/invite_link.dart';

void main() {
  test('buildInviteLobbyShareUrl uses origin and invite mode', () {
    expect(
      buildInviteLobbyShareUrl(
        lobbyId: 'lobby-42',
        baseUri: Uri.parse('https://multigames.example/games'),
      ),
      'https://multigames.example/games/tictactoe/lobby/lobby-42?mode=invite',
    );
  });
}
