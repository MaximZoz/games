import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';

ChatPreviewItem _chat(String id, {required int unread}) {
  return ChatPreviewItem(
    chatID: id,
    user: ChatUserItem(id: 'u-$id'),
    lastMessage: null,
    unreadCount: unread,
    createdAt: '',
    updatedAt: '',
  );
}

void main() {
  test('открытый чат не поднимает unread после reload списка', () {
    final chats = [
      _chat('a', unread: 2),
      _chat('b', unread: 1),
    ];
    final visible = applyLocallyReadChats(chats, {'a'});
    expect(visible[0].unreadCount, 0);
    expect(visible[1].unreadCount, 1);
    expect(
      visible.fold<int>(0, (sum, item) => sum + item.unreadCount),
      1,
    );
  });
}
