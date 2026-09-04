import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';

void main() {
  testWidgets('FramedButton shows icon and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FramedButton(
            icon: Icons.edit_outlined,
            label: 'Редактировать',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('FramedButton loading disables tap and shows spinner',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FramedButton(
            label: 'Ок',
            loading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FramedButton));
    expect(tapped, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('FramedButton can expand to full width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: FramedButton(
              label: 'Играть',
              expanded: true,
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(FramedButton));
    expect(size.width, 320);
  });
}
