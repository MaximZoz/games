import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/chats_screen.dart';

void main() {
  group('chatsNewChatUseCompactStrip', () {
    test('в альбоме одна строка, в портрете обычная шапка', () {
      expect(chatsNewChatUseCompactStrip(phoneLandscape: true), isTrue);
      expect(chatsNewChatUseCompactStrip(phoneLandscape: false), isFalse);
    });
  });

  group('chatsNewChatSheetHeight', () {
    test('в портрете фиксированные 420', () {
      expect(
        chatsNewChatSheetHeight(
          phoneLandscape: false,
          viewHeight: 800,
          keyboardInset: 300,
        ),
        420,
      );
    });

    test('в альбоме занимает щель над клавиатурой', () {
      expect(
        chatsNewChatSheetHeight(
          phoneLandscape: true,
          viewHeight: 390,
          keyboardInset: 220,
        ),
        162,
      );
      expect(
        chatsNewChatSheetHeight(
          phoneLandscape: true,
          viewHeight: 390,
          keyboardInset: 350,
        ),
        72,
      );
    });
  });
}
