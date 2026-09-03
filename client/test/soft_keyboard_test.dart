import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/soft_keyboard.dart';

void main() {
  testWidgets('openSoftKeyboard фокусит без ожидания кадра и просит клавиатуру',
      (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(focusNode: node),
        ),
      ),
    );

    tester.testTextInput.log.clear();
    // Фокус и запрос клавиатуры — в том же жесте, без ожидания следующего
    // кадра: браузеры на iOS открывают клавиатуру только внутри
    // пользовательского события.
    openSoftKeyboard(node);
    await tester.pump();
    expect(node.hasFocus, isTrue);

    final methods = tester.testTextInput.log.map((c) => c.method).toList();
    expect(methods, contains('TextInput.setClient'));
    expect(
      methods.lastIndexOf('TextInput.show'),
      greaterThan(methods.indexOf('TextInput.setClient')),
    );
  });

  testWidgets('повторный вызов на сфокусированном поле снова просит показать',
      (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(focusNode: node),
        ),
      ),
    );

    openSoftKeyboard(node);
    await tester.pump();
    tester.testTextInput.log.clear();

    openSoftKeyboard(node);
    await tester.pump();
    expect(
      tester.testTextInput.log.map((c) => c.method),
      contains('TextInput.show'),
    );
  });
}
