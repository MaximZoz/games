import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_about_line.dart';

void main() {
  testWidgets('О себе — одна строка с многоточием, без вертикальной обрезки',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            child: AboutOneLineText(
              text: 'Привет я основатель узу геймс и это длинный текст',
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, isFalse);
    expect(tester.takeException(), isNull);
  });
}
