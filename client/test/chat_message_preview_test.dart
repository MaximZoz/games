import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

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

  test('previewText для нескольких фото', () {
    expect(
      msg(hasImage: true).copyWith(imageCount: 3).previewText,
      'Фото (3)',
    );
  });

  test('previewText для ссылки-приглашения в лобби', () {
    final body =
        'https://multigameszozu.fly.dev/games/tictactoe/lobby/f84e367b-674a-4290-900c-a5133fa23204?mode=invite';
    expect(
      msg(body: body).previewText,
      'Приглашение в игру: Крестики-нолики',
    );
    expect(
      formatChatMessagePreview(body),
      'Приглашение в игру: Крестики-нолики',
    );
  });
}
