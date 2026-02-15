// Basic Flutter widget tests for MultiGames client.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multigames_client/main.dart';

void main() {
  testWidgets('App shows MultiGames start title', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiGamesApp());
    await tester.pump();

    expect(find.text('MultiGames start'), findsOneWidget);
  });

  testWidgets('App shows loading or content on first frame', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiGamesApp());
    await tester.pump();

    final hasTitle = find.text('MultiGames start').evaluate().isNotEmpty;
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasTitle || hasLoading, isTrue);
  });

  testWidgets('App uses Material and Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiGamesApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
