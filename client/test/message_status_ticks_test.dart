import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/message_status_ticks.dart';

void main() {
  testWidgets('одна галочка — отправлено', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageStatusTicks(
            deliveredAt: null,
            readAt: null,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNothing);
  });

  testWidgets('две серые — доставлено', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageStatusTicks(
            deliveredAt: '2026-07-26T00:00:00.000Z',
            readAt: null,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
    expect(icon.color, isNot(MessageStatusTicks.readColor));
  });

  testWidgets('две синие — прочитано', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageStatusTicks(
            deliveredAt: '2026-07-26T00:00:00.000Z',
            readAt: '2026-07-26T00:01:00.000Z',
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
    expect(icon.color, MessageStatusTicks.readColor);
  });
}
