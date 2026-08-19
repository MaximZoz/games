import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/uno_game_icon.dart';

void main() {
  testWidgets('UnoGameIcon paints without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: UnoGameIcon(size: 26)),
        ),
      ),
    );
    expect(find.byType(UnoGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
