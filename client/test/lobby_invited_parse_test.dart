import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';

Map<String, dynamic> _lobbyJson() => {
      'id': 'lobby-1',
      'creator_id': 'me',
      'status': 'waiting_invite',
      'mode': 'invite',
      'player_ids': ['me'],
      'players': [
        {'id': 'me', 'display_name': 'me'},
      ],
      'invited': [
        {'id': 'rival', 'display_name': 'rival', 'avatar_kind': 'letter'},
      ],
    };

void main() {
  test('приглашённые приходят с сервера в общий парсер', () {
    final invited = parseLobbyInvited(_lobbyJson()['invited']);
    expect(invited, hasLength(1));
    expect(invited.single.id, 'rival');
    expect(invited.single.displayName, 'rival');
    expect(parseLobbyInvited(null), isEmpty);
    expect(parseLobbyInvited('nope'), isEmpty);
  });

  test('лобби крестиков отдаёт приглашённых', () {
    final lobby = LobbyItem.fromJson(_lobbyJson());
    expect(lobby.invited.map((p) => p.id), ['rival']);
  });

  test('лобби дурака отдаёт приглашённых', () {
    final lobby = DurakLobbyView.fromJson(_lobbyJson());
    expect(lobby.invited.map((p) => p.id), ['rival']);
  });

  test('лобби нард отдаёт приглашённых', () {
    final lobby = NardyLobbyView.fromJson(_lobbyJson());
    expect(lobby.invited.map((p) => p.id), ['rival']);
  });

  test('без поля invited список пуст', () {
    final json = _lobbyJson()..remove('invited');
    expect(LobbyItem.fromJson(json).invited, isEmpty);
    expect(NardyLobbyView.fromJson(json).invited, isEmpty);
  });
}
