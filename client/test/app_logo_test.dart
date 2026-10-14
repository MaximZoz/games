import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_logo.dart';

void main() {
  testWidgets('логотип рисуется во всех трёх режимах', (tester) async {
    for (final style in ZozuLogoStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ZozuAppLogo(size: 96, style: style),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ZozuAppLogo), findsOneWidget);
      expect(tester.getSize(find.byType(ZozuAppLogo)), const Size(96, 96));
      expect(tester.takeException(), isNull);
    }
  });
}
