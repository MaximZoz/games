// Базовые виджет-тесты клиента MultiGames.
// Не используем pumpAndSettle: на главной есть сетевой запрос и async auth — они не завершаются в тесте.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:multigames_client/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
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

  testWidgets('On home, toolbar has login or loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final hasLogin = find.byTooltip('Войти').evaluate().isNotEmpty;
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasLogin || hasLoading, isTrue);
  });

  testWidgets('On login page, toolbar shows login button and title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byTooltip('Войти'), findsOneWidget);
    await tester.tap(find.byTooltip('Войти'));
    await tester.pump();
    // Переход между роутами анимирован в AppShell
    await tester.pump(const Duration(milliseconds: 600));

    // Кнопка «На главную» удалена — тулбар всегда показывает «Войти»/«Выйти»
    expect(find.byTooltip('На главную'), findsNothing);
    expect(find.byKey(const Key('toolbar_title')), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
  });

  testWidgets('On login page, MultiGames title in toolbar is tappable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byTooltip('Войти'));
    await tester.pump();
    // Переход между роутами анимирован в AppShell
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Вход'), findsOneWidget);

    // Тулбар без AppBar: заголовок в оболочке с ключом toolbar_title
    final titleInToolbar = find.byKey(const Key('toolbar_title'));
    expect(titleInToolbar, findsOneWidget);
    await tester.tap(titleInToolbar, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
