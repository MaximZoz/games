import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/chats/chats_repository.dart';

void main() {
  group('chatSelfId', () {
    test('prefers acting support account over admin jwt', () {
      expect(
        chatSelfId(actingAsUserId: 'support-1', authUserId: 'admin-9'),
        'support-1',
      );
    });

    test('falls back to auth user', () {
      expect(chatSelfId(actingAsUserId: '  ', authUserId: 'admin-9'), 'admin-9');
      expect(chatSelfId(authUserId: 'admin-9'), 'admin-9');
    });

    test('empty when nobody is known', () {
      expect(chatSelfId(), isNull);
      expect(chatSelfId(actingAsUserId: '', authUserId: ''), isNull);
    });
  });

  group('SupportChatSession', () {
    test('fromJson reads chat and support ids', () {
      final s = SupportChatSession.fromJson({
        'chat_id': 'c1',
        'support_user_id': 'su',
        'peer_id': 'u1',
      });
      expect(s.chatId, 'c1');
      expect(s.supportUserId, 'su');
      expect(s.peerId, 'u1');
    });
  });
}
