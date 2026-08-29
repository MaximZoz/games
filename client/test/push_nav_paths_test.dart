import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/push_nav_paths.dart';

void main() {
  test('pathFromTag / tagFromPath как в iPhone PWA', () {
    expect(pathFromTag('chat_abc'), '/chats/abc');
    expect(tagFromPath('/chats/abc'), 'chat_abc');
    expect(pathFromTag('friend_request'), '/friends?tab=incoming');
    expect(tagFromPath('/friends?tab=incoming'), 'friend_request');
    expect(pathFromTag('game_invite_lobby1'), '/games/tictactoe/lobby/lobby1');
    expect(tagFromPath('/games/durak/lobby/lobby1'), 'game_invite_lobby1');
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
