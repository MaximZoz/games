import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/chats_layout_screen.dart';
import 'package:multigames_client/screens/chats_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

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

  group('chats sidebar divider / swipe', () {
    test('линия того же цвета, что заливка тогла, и касается кнопки', () {
      const panelWidth = 72.0;
      const toggleLeft = panelWidth - chatsSidebarToggleLeftInset;
      const toggleRight = toggleLeft + chatsSidebarToggleWidth;
      final lineLeft = chatsSidebarLineLeft(panelWidth);
      expect(chatsSidebarDividerColor(), AppColors.accentSoft.withValues(alpha: 0.6));
      expect(chatsSidebarPanelColor(), chatsSidebarDividerColor());
      expect(lineLeft, greaterThanOrEqualTo(toggleLeft));
      expect(lineLeft + chatsSidebarLineWidth, lessThanOrEqualTo(toggleRight));
    });

    test('свайп влево сворачивает, вправо разворачивает', () {
      expect(
        chatsSidebarSwipeShouldToggle(collapsed: false, dx: -48),
        isTrue,
      );
      expect(
        chatsSidebarSwipeShouldToggle(collapsed: false, dx: 48),
        isFalse,
      );
      expect(
        chatsSidebarSwipeShouldToggle(collapsed: true, dx: 48),
        isTrue,
      );
      expect(
        chatsSidebarSwipeShouldToggle(collapsed: true, dx: -48),
        isFalse,
      );
      expect(
        chatsSidebarSwipeShouldToggle(collapsed: false, dx: -20),
        isFalse,
      );
    });
  });
}
