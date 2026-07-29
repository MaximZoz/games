import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';

void main() {
  ChatMessageItem msg({
    String body = '',
    bool hasImage = false,
  }) {
    return ChatMessageItem(
      id: 'm1',
      chatID: 'c1',
      senderUserID: 'u1',
      body: body,
      createdAt: '2026-01-01T00:00:00Z',
      hasImage: hasImage,
    );
  }

  test('previewText для фото без подписи', () {
    expect(msg(hasImage: true).previewText, 'Фото');
  });

  test('previewText для фото с подписью', () {
    expect(msg(body: 'привет', hasImage: true).previewText, 'Фото: привет');
  });

  test('previewText для обычного текста', () {
    expect(msg(body: 'привет').previewText, 'привет');
  });
}
