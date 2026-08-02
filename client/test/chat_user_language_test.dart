import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';

void main() {
  test('ChatUserItem parses preferred_language', () {
    final user = ChatUserItem.fromJson({
      'id': 'u1',
      'display_name': 'Peer',
      'preferred_language': 'en',
    });
    expect(user.preferredLanguage, 'en');
  });
}
