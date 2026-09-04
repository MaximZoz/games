import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_repository.dart';

void main() {
  group('chatNeedsTranslation', () {
    test('другой язык собеседника — перевод нужен', () {
      expect(
        chatNeedsTranslation(peerLanguage: 'en', myLanguage: 'ru'),
        isTrue,
      );
    });

    test('тот же язык — перевод не нужен', () {
      expect(
        chatNeedsTranslation(peerLanguage: 'RU', myLanguage: 'ru'),
        isFalse,
      );
    });

    test('язык собеседника неизвестен — перевод не нужен', () {
      expect(chatNeedsTranslation(peerLanguage: null, myLanguage: 'ru'), isFalse);
      expect(chatNeedsTranslation(peerLanguage: '  ', myLanguage: 'ru'), isFalse);
    });
  });

  group('chatAutoTranslateEnabled', () {
    test('иностранцу переводим сразу, без нажатия кнопки', () {
      expect(
        chatAutoTranslateEnabled(
          stored: null,
          peerLanguage: 'en',
          myLanguage: 'ru',
        ),
        isTrue,
      );
    });

    test('свой язык — по умолчанию выключено', () {
      expect(
        chatAutoTranslateEnabled(
          stored: null,
          peerLanguage: 'ru',
          myLanguage: 'ru',
        ),
        isFalse,
      );
    });

    test('выбор пользователя сильнее умолчания', () {
      expect(
        chatAutoTranslateEnabled(
          stored: false,
          peerLanguage: 'en',
          myLanguage: 'ru',
        ),
        isFalse,
      );
      expect(
        chatAutoTranslateEnabled(
          stored: true,
          peerLanguage: 'ru',
          myLanguage: 'ru',
        ),
        isTrue,
      );
    });
  });
}
