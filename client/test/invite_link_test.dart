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

  test('buildInviteLobbyShareUrl durak path', () {
    expect(
      buildInviteLobbyShareUrl(
        lobbyId: 'lob-d',
        baseUri: Uri.parse('https://multigames.example/'),
        gameType: 'durak',
      ),
      'https://multigames.example/games/durak/lobby/lob-d?mode=invite',
    );
    final parsed = parseInviteLobbyShareUrl(
      'https://multigames.example/games/durak/lobby/lob-d?mode=invite',
    );
    expect(parsed?.gameType, 'durak');
    expect(parsed?.lobbyId, 'lob-d');
  });

  test('parseInviteLobbyShareUrl absolute with mode=invite', () {
    final link = parseInviteLobbyShareUrl(
      'https://multigameszozu.fly.dev/games/tictactoe/lobby/f84e367b-674a-4290-900c-a5133fa23204?mode=invite',
    );
    expect(link, isNotNull);
    expect(link!.lobbyId, 'f84e367b-674a-4290-900c-a5133fa23204');
    expect(
      link.appPath,
      '/games/tictactoe/lobby/f84e367b-674a-4290-900c-a5133fa23204?mode=invite',
    );
  });

  test('parseInviteLobbyShareUrl relative path', () {
    final link = parseInviteLobbyShareUrl(
      '/games/tictactoe/lobby/abc-123?mode=invite',
    );
    expect(link?.lobbyId, 'abc-123');
    expect(link?.appPath, '/games/tictactoe/lobby/abc-123?mode=invite');
  });

  test('parseInviteLobbyShareUrl ignores surrounding whitespace', () {
    final link = parseInviteLobbyShareUrl(
      '  https://zozugames.com/games/tictactoe/lobby/x1  ',
    );
    expect(link?.lobbyId, 'x1');
  });

  test('parseInviteLobbyShareUrl rejects plain text', () {
    expect(parseInviteLobbyShareUrl('привет'), isNull);
    expect(parseInviteLobbyShareUrl('https://example.com/other'), isNull);
    expect(isInviteLobbyMessage('я тоже'), isFalse);
  });

  test('parseInviteLobbyShareUrl rejects unregistered game type', () {
    expect(
      parseInviteLobbyShareUrl('/games/chess/lobby/abc-123?mode=invite'),
      isNull,
    );
  });

  test('appPathFromMessage appends from_message query', () {
    final link = parseInviteLobbyShareUrl(
      '/games/tictactoe/lobby/abc-123?mode=invite',
    );
    expect(
      link!.appPathFromMessage('msg-42'),
      '/games/tictactoe/lobby/abc-123?mode=invite&from_message=msg-42',
    );
  });
}
