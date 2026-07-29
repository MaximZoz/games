import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';

void main() {
  test('ChatCapabilities.fromJson парсит emoji_only', () {
    final caps = ChatCapabilities.fromJson({
      'can_send_text': false,
      'emoji_only': true,
    });
    expect(caps.emojiOnly, isTrue);
    expect(caps.canSendText, isFalse);
  });

  test('ChatCapabilities.fromJson по умолчанию разрешает текст', () {
    final caps = ChatCapabilities.fromJson({});
    expect(caps.emojiOnly, isFalse);
    expect(caps.canSendText, isTrue);
  });
}
