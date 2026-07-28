import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';

void main() {
  group('giftCollectionCodeFromBody', () {
    test('parses gift token', () {
      expect(
        giftCollectionCodeFromBody(
          '[gift_coll:coll_unicorn|Единорог|🦄|unicorn]',
        ),
        'coll_unicorn',
      );
    });

    test('ignores plain text', () {
      expect(giftCollectionCodeFromBody('привет'), isNull);
    });
  });

  group('giftCodesFromUnreadChats', () {
    ChatPreviewItem chat({
      required int unread,
      required String sender,
      required String body,
    }) {
      return ChatPreviewItem(
        chatID: 'c1',
        user: ChatUserItem(id: 'peer', displayName: 'Peer'),
        lastMessage: ChatMessageItem(
          id: 'm1',
          chatID: 'c1',
          senderUserID: sender,
          body: body,
          createdAt: '2026-01-01T00:00:00Z',
        ),
        unreadCount: unread,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      );
    }

    test('collects gift from unread incoming last message', () {
      final codes = giftCodesFromUnreadChats(
        chats: [
          chat(
            unread: 1,
            sender: 'peer',
            body: '[gift_coll:coll_ghost|Привидение|👻|ghost]',
          ),
        ],
        myUserId: 'me',
      );
      expect(codes, {'coll_ghost'});
    });

    test('skips read chats and own messages', () {
      final codes = giftCodesFromUnreadChats(
        chats: [
          chat(
            unread: 0,
            sender: 'peer',
            body: '[gift_coll:coll_ghost|Привидение|👻|ghost]',
          ),
          chat(
            unread: 2,
            sender: 'me',
            body: '[gift_coll:coll_robot|Робот|🤖|robot]',
          ),
        ],
        myUserId: 'me',
      );
      expect(codes, isEmpty);
    });
  });
}
