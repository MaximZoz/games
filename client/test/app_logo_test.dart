import 'dart:io';

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

  test('веб-файлы ссылаются на иконки с cache-busting и содержат favicon.ico', () {
    final indexHtml = File('web/index.html').readAsStringSync();
    expect(indexHtml, contains('href="favicon.png?v=2"'));
    expect(indexHtml, contains('href="icons/Icon-192.png?v=2"'));

    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"icons/Icon-192.png?v=2"'));
    expect(manifest, contains('"icons/Icon-512.png?v=2"'));
    expect(manifest, contains('"icons/Icon-maskable-192.png?v=2"'));
    expect(manifest, contains('"icons/Icon-maskable-512.png?v=2"'));

    expect(File('web/favicon.ico').existsSync(), isTrue);
    expect(File('web/favicon.png').existsSync(), isTrue);
  });
}

