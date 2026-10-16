import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/push_nav_paths.dart';

void main() {
  test('pathFromTag / tagFromPath как в iPhone PWA', () {
    expect(pathFromTag('chat_abc'), '/chats/abc');
    expect(tagFromPath('/chats/abc'), 'chat_abc');
    expect(pathFromTag('friend_request'), '/friends?tab=incoming');
    expect(tagFromPath('/friends?tab=incoming'), 'friend_request');
    expect(pathFromTag('game_invite_lobby1'), '/games/tictactoe/lobby/lobby1');
    expect(
      pathFromTag('game_invite_uno:L9'),
      '/games/uno/lobby/L9?mode=invite',
    );
    expect(tagFromPath('/games/durak/lobby/lobby1'), 'game_invite_durak:lobby1');
    expect(
      tagFromPath('/games/uno/lobby/L9?mode=invite'),
      'game_invite_uno:L9',
    );
    expect(pathFromTag('daily_reward'), '/coins/login');
    expect(tagFromPath('/coins/login'), 'daily_reward');
  });

  test('pathFromPushData предпочитает url, затем chat_id, затем tag', () {
    expect(
      pathFromPushData({'url': '/chats/x', 'chat_id': 'y', 'tag': 'chat_z'}),
      '/chats/x',
    );
    expect(pathFromPushData({'chat_id': 'y'}), '/chats/y');
    expect(pathFromPushData({'tag': 'friend_request'}), '/friends?tab=incoming');
  });

  test('имя из пуша попадает в шапку чата и не затирает чужой путь', () {
    expect(
      pathFromPushData({'url': '/chats/x', 'title': 'Аня'}),
      '/chats/x?name=${Uri.encodeQueryComponent('Аня')}',
    );
    expect(
      pathFromPushData({'chat_id': 'y', 'title': 'Аня'}),
      '/chats/y?name=${Uri.encodeQueryComponent('Аня')}',
    );
    expect(
      pathFromPushData({'url': '/chats/x?name=Боб', 'title': 'Аня'}),
      '/chats/x?name=Боб',
    );
    expect(
      pathFromPushData({
        'url': '/games/durak/lobby/1',
        'title': 'Игра',
        'tag': 'game_invite_1',
      }),
      '/games/durak/lobby/1?mode=invite',
    );
    expect(
      pathFromPushData({
        'game_type': 'uno',
        'lobby_id': 'L9',
      }),
      '/games/uno/lobby/L9?mode=invite',
    );
    expect(
      pathFromPushData({'tag': 'game_invite_domino:abc'}),
      '/games/domino/lobby/abc?mode=invite',
    );
  });

  test('тап iPhone понимает и FCM, и payload локального баннера', () {
    expect(
      pathFromIosTap({
        'url': '/games/domino/lobby/9',
        'tag': 'game_invite_9',
        'title': 'Оля',
      }),
      '/games/domino/lobby/9?mode=invite',
    );
    expect(
      pathFromIosTap({
        'payload': encodeNotificationPayload(
          url: '/chats/7?name=${Uri.encodeQueryComponent('Ира')}',
          tag: 'chat_7',
          chatId: '7',
        ),
      }),
      '/chats/7?name=${Uri.encodeQueryComponent('Ира')}',
    );
  });

  test('payload json и сырой path открывают тот же чат', () {
    expect(
      pathFromNotificationPayload(
        encodeNotificationPayload(url: '/chats/42', tag: 'chat_42', chatId: '42'),
      ),
      '/chats/42',
    );
    expect(pathFromNotificationPayload('/chats/42'), '/chats/42');
  });

  test('notificationIdForTag стабилен', () {
    expect(notificationIdForTag('chat_a'), notificationIdForTag('chat_a'));
    expect(notificationIdForTag('chat_a'), isNot(notificationIdForTag('chat_b')));
    expect(notificationIdForTag('chat_a'), greaterThanOrEqualTo(0));
  });

  test('pathsMatch игнорирует query', () {
    expect(pathsMatch('/chats/1', '/chats/1?x=1'), isTrue);
    expect(pathsMatch('/chats/1', '/chats/2'), isFalse);
  });
}
