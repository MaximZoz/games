import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';

/// Оболочка приложения + экран чата: два вложенных Scaffold.
/// Внешний с `resizeToAvoidBottomInset` снимает viewInsets у вложенного,
/// поэтому клавиатура вычитается один раз, а не дважды.
Widget _shellWithChat({
  required Size size,
  required double keyboardInset,
  required bool onProfile,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      viewInsets: EdgeInsets.only(bottom: keyboardInset),
    ),
    child: MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset:
            profileEditShellResizeToAvoidInset(onProfile: onProfile),
        body: Column(
          children: [
            const SizedBox(height: 48, key: ValueKey('toolbar')),
            Expanded(
              child: Scaffold(
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
          ],
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
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _shellWithChat(
          size: size,
          keyboardInset: keyboardInset,
          onProfile: false,
        ),
      );

      final composer = tester.getRect(find.byKey(const ValueKey('composer')));
      final messages = tester.getRect(find.byKey(const ValueKey('messages')));

      // Низ поля ввода вплотную к верху клавиатуры: если бы inset вычитался
      // дважды, поле уехало бы вверх ещё на keyboardInset.
      expect(
        composer.bottom,
        closeTo(size.height - keyboardInset, 1.0),
        reason: 'поле ввода должно упираться в клавиатуру',
      );
      // Сообщения видны над полем, а не сжаты в ноль.
      expect(messages.height, greaterThan(0));
      expect(messages.bottom, closeTo(composer.top, 1.0));
    }

    testWidgets('портрет', (tester) async {
      await check(tester, size: const Size(390, 844), keyboardInset: 336);
    });

    testWidgets('альбом', (tester) async {
      await check(tester, size: const Size(844, 390), keyboardInset: 200);
    });
  });

  test('оболочка ресайзится всюду, кроме профиля', () {
    // Профиль сам поднимает полоску над клавиатурой; друзьям и чатам resize
    // нужен, иначе вложенный Scaffold вычитает клавиатуру второй раз.
    expect(profileEditShellResizeToAvoidInset(onProfile: false), isTrue);
    expect(profileEditShellResizeToAvoidInset(onProfile: true), isFalse);
  });
}
