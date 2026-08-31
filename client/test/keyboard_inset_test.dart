import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';

void main() {
  group('sanitizeKeyboardInset', () {
    test('обычную клавиатуру не трогает', () {
      expect(
        sanitizeKeyboardInset(inset: 336, viewportHeight: 844),
        closeTo(336, 0.01),
      );
    });

    test('нулевой inset остаётся нулём', () {
      expect(sanitizeKeyboardInset(inset: 0, viewportHeight: 844), 0);
      expect(sanitizeKeyboardInset(inset: -10, viewportHeight: 844), 0);
    });

    test('завышенный inset ограничен долей экрана', () {
      expect(
        sanitizeKeyboardInset(inset: 900, viewportHeight: 844),
        closeTo(844 * 0.85, 0.01),
      );
      expect(
        sanitizeKeyboardInset(inset: 5000, viewportHeight: 390),
        closeTo(390 * 0.85, 0.01),
      );
    });

    test('без высоты экрана возвращает как есть', () {
      expect(sanitizeKeyboardInset(inset: 200, viewportHeight: 0), 200);
    });
  });

  group('keyboardIsOpen', () {
    test('мелкие значения — не клавиатура', () {
      expect(keyboardIsOpen(0), isFalse);
      expect(keyboardIsOpen(34), isFalse);
    });


    test('клавиатура открыта от 80', () {
      expect(keyboardIsOpen(80), isTrue);
      expect(keyboardIsOpen(336), isTrue);
    });
  });

  group('KeyboardInsetScope', () {
    testWidgets('без обёртки — клавиатуру никто не вычел', (tester) async {
      bool? handled;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              handled = KeyboardInsetScope.handledOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(handled, isFalse);
    });

    testWidgets('внутри обёртки метка видна', (tester) async {
      bool? handled;
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardInsetScope(
            handled: true,
            child: Builder(
              builder: (context) {
                handled = KeyboardInsetScope.handledOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(handled, isTrue);
    });
  });
}
