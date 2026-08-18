import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/admin/admin_provider.dart';
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

  group('chatRoomPeerUser', () {
    test('admin support mode uses override, not inbox support peer', () {
      final inboxSupport = ChatUserItem(
        id: 'su',
        displayName: 'Поддержка',
        isSupport: true,
      );
      final user = ChatUserItem(id: 'u1', displayName: 'Zozulya');
      final peer = chatRoomPeerUser(
        actingAsUserId: 'su',
        listPeer: inboxSupport,
        overridePeer: user,
      );
      expect(peer?.id, 'u1');
      expect(peer?.displayName, 'Zozulya');
      expect(peer?.isSupport, isFalse);
    });

    test('regular chat keeps list peer', () {
      final listPeer = ChatUserItem(id: 'p1', displayName: 'Alice');
      expect(
        chatRoomPeerUser(listPeer: listPeer, overridePeer: null)?.id,
        'p1',
      );
    });
  });

  group('supportUnreadVisible', () {
    test('skips locally read chats', () {
      const items = [
        SupportChatItem(chatId: 'c1', peerId: 'u1', unreadCount: 3),
        SupportChatItem(chatId: 'c2', peerId: 'u2', unreadCount: 1),
      ];
      expect(supportUnreadVisible(items, {}), 4);
      expect(supportUnreadVisible(items, {'c1'}), 1);
      expect(supportUnreadVisible(items, {'c1', 'c2'}), 0);
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
