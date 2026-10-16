import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/android_notify_map.dart';
import 'package:multigames_client/core/web_push_provider.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('баннер только в настоящем фоне, не при открытии приложения', () {
    expect(shouldShowAndroidTrayBanner(AppLifecycleState.paused), isTrue);
    expect(shouldShowAndroidTrayBanner(AppLifecycleState.hidden), isTrue);
    expect(shouldShowAndroidTrayBanner(AppLifecycleState.detached), isTrue);
    expect(shouldShowAndroidTrayBanner(AppLifecycleState.resumed), isFalse);
    expect(shouldShowAndroidTrayBanner(AppLifecycleState.inactive), isFalse);
  });

  test('на iPhone баннер и в inactive: до paused событие часто не доживает', () {
    expect(
      shouldShowPhoneTrayBanner(AppLifecycleState.inactive, ios: true),
      isTrue,
    );
    expect(
      shouldShowPhoneTrayBanner(AppLifecycleState.inactive, ios: false),
      isFalse,
    );
    expect(
      shouldShowPhoneTrayBanner(AppLifecycleState.resumed, ios: true),
      isFalse,
    );
    expect(
      shouldShowPhoneTrayBanner(AppLifecycleState.paused, ios: true),
      isTrue,
    );
  });

  test('chat_message даёт url/tag как PWA', () {
    final spec = mapAndroidNotifyEvent(
      {
        'type': 'chat_message',
        'chat_id': 'c1',
        'message': {
          'sender_user_id': 'u2',
          'sender_name': 'Алиса',
          'body': 'Привет',
        },
      },
      meId: 'u1',
      cats: const WebPushCategoryPrefs(),
    );
    expect(spec, isNotNull);
    expect(spec!.url, '/chats/c1');
    expect(spec.tag, 'chat_c1');
    expect(spec.chatId, 'c1');
    expect(spec.title, 'Алиса');
    expect(spec.body, 'Привет');
  });

  test('своё сообщение и чужой чат без id не баннерим', () {
    expect(
      mapAndroidNotifyEvent(
        {
          'type': 'chat_message',
          'chat_id': 'c1',
          'message': {'sender_user_id': 'u1', 'body': 'я'},
        },
        meId: 'u1',
        cats: const WebPushCategoryPrefs(),
      ),
      isNull,
    );
    expect(
      mapAndroidNotifyEvent(
        {
          'type': 'chat_message',
          'message': {'sender_user_id': 'u2', 'body': 'x'},
        },
        meId: 'u1',
        cats: const WebPushCategoryPrefs(),
      ),
      isNull,
    );
  });

  test('game_invite и заявка в друзья ведут на нужный экран', () {
    final invite = mapAndroidNotifyEvent(
      {
        'type': 'game_invite',
        'lobby_id': 'L9',
        'game_type': 'durak',
        'creator_name': 'Боб',
      },
      meId: 'u1',
      cats: const WebPushCategoryPrefs(),
    );
    expect(invite!.url, '/games/durak/lobby/L9');
    expect(invite.tag, 'game_invite_L9');

    final friend = mapAndroidNotifyEvent(
      {'type': 'friends_updated', 'incoming': true},
      meId: 'u1',
      cats: const WebPushCategoryPrefs(),
    );
    expect(friend!.url, '/friends?tab=incoming');
    expect(friend.tag, 'friend_request');
  });

  test('выключенная категория чата глушит баннер', () {
    expect(
      mapAndroidNotifyEvent(
        {
          'type': 'chat_message',
          'chat_id': 'c1',
          'message': {'sender_user_id': 'u2', 'body': 'x'},
        },
        meId: 'u1',
        cats: const WebPushCategoryPrefs(chat: false),
      ),
      isNull,
    );
  });
}
