// Базовые виджет-тесты клиента MultiGames.
// Не используем pumpAndSettle: на главной есть сетевой запрос и async auth — они не завершаются в тесте.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multigames_client/main.dart';

void main() {
  testWidgets('App shows MultiGames title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MultiGames'), findsWidgets);
  });

  testWidgets('App uses MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home shows MultiGames and has scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MultiGames'), findsWidgets);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
