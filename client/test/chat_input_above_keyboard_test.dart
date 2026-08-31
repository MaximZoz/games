import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';

/// Оболочка приложения + экран чата: два вложенных Scaffold.
/// Клавиатуру вычитает только оболочка (padding + [KeyboardInsetScope]),
/// вложенный Scaffold по метке отключает свой resize — вычитание одно.
Widget _shellWithChat({
  required Size size,
  required double keyboardInset,
  required bool shellHandlesKeyboard,
}) {
  final shellInset = shellHandlesKeyboard
      ? sanitizeKeyboardInset(
          inset: keyboardInset,
          viewportHeight: size.height,
        )
      : 0.0;
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      viewInsets: EdgeInsets.only(bottom: keyboardInset),
    ),
    child: MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: !shellHandlesKeyboard,
        body: KeyboardInsetScope(
          handled: shellHandlesKeyboard,
          child: Padding(
            padding: EdgeInsets.only(bottom: shellInset),
            child: Column(
              children: [
                const SizedBox(height: 48, key: ValueKey('toolbar')),
                Expanded(
                  child: Builder(
                    builder: (context) => Scaffold(
                      resizeToAvoidBottomInset:
                          !KeyboardInsetScope.handledOf(context),
                      body: Column(
                        children: [
                          Expanded(
                            child: Container(
                              key: const ValueKey('messages'),
                              color: const Color(0xFFEEEEEE),
                            ),
                          ),
                          const SizedBox(
                            key: ValueKey('composer'),
                            height: 56,
                            child: TextField(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ввод стоит сразу над клавиатурой', () {
    Future<void> check(
      WidgetTester tester, {
      required Size size,
      required double keyboardInset,
      required double expectedInset,
      bool shellHandlesKeyboard = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _shellWithChat(
          size: size,
          keyboardInset: keyboardInset,
          shellHandlesKeyboard: shellHandlesKeyboard,
        ),
      );

      final composer = tester.getRect(find.byKey(const ValueKey('composer')));
      final messages = tester.getRect(find.byKey(const ValueKey('messages')));

      // Низ поля ввода вплотную к верху клавиатуры: если бы inset вычитался
      // дважды, поле уехало бы вверх ещё на expectedInset.
      expect(
        composer.bottom,
        closeTo(size.height - expectedInset, 1.0),
        reason: 'поле ввода должно упираться в клавиатуру',
      );
      // Сообщения видны над полем, а не сжаты в ноль.
      expect(messages.height, greaterThan(0));
      expect(messages.bottom, closeTo(composer.top, 1.0));
    }

    testWidgets('портрет', (tester) async {
      await check(
        tester,
        size: const Size(390, 844),
        keyboardInset: 336,
        expectedInset: 336,
      );
    });

    testWidgets('альбом', (tester) async {
      await check(
        tester,
        size: const Size(844, 390),
        keyboardInset: 200,
        expectedInset: 200,
      );
    });

    testWidgets('iOS PWA: завышенный inset не съедает экран', (tester) async {
      // Safari умеет отдать inset больше реальной клавиатуры — без ограничения
      // от экрана остаётся полоска тулбара, а список и ввод пропадают.
      await check(
        tester,
        size: const Size(390, 844),
        keyboardInset: 900,
        expectedInset: 844 * 0.6,
      );
    });

    testWidgets('без метки клавиатуру вычитает вложенный Scaffold',
        (tester) async {
      await check(
        tester,
        size: const Size(1200, 800),
        keyboardInset: 300,
        expectedInset: 300,
        shellHandlesKeyboard: false,
      );
    });
  });

  test('оболочка ресайзится всюду, кроме профиля', () {
    // Профиль сам поднимает полоску над клавиатурой; на остальных экранах,
    // где оболочка не владеет клавиатурой, работает обычный resize.
    expect(profileEditShellResizeToAvoidInset(onProfile: false), isTrue);
    expect(profileEditShellResizeToAvoidInset(onProfile: true), isFalse);
  });
}
