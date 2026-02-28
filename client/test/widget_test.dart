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

    // Кнопка «На главную» и заголовок в тулбаре удалены — тулбар показывает «Войти»/«Выйти»
    expect(find.byTooltip('На главную'), findsNothing);
    expect(find.text('Вход'), findsOneWidget);
  });

  testWidgets('On login page, form is visible and toolbar has auth button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byTooltip('Войти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Вход'), findsOneWidget);

    // Тулбар без заголовка MultiGames — проверяем наличие формы и кнопки входа
    expect(find.byTooltip('Войти'), findsOneWidget);
  });

  testWidgets('Navigation rail shows main sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
    expect(find.text('Друзья'), findsWidgets);
    expect(find.text('Чаты'), findsWidgets);
  });

  testWidgets('Profile for unauthenticated user shows login prompt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(find.text('Чтобы видеть профиль и достижения'), findsOneWidget);
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Регистрация'), findsOneWidget);
  });

  testWidgets('Profile → Login → Register → Login navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Профиль → Войти
    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Войти').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);

    // Логин → Регистрация
    await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Уже есть аккаунт? Войти'), findsOneWidget);

    // Регистрация → Логин
    await tester.tap(find.text('Уже есть аккаунт? Войти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Вход'), findsOneWidget);
  });

  testWidgets('Login form shows validation errors on empty submit', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byTooltip('Войти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Тап по кнопке «Войти» в форме (не иконке в тулбаре)
    final loginButtons = find.text('Войти');
    expect(loginButtons, findsWidgets);
    await tester.tap(loginButtons.last);
    await tester.pump();

    expect(find.text('Введите email или логин'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('Unauthenticated user tapping Friends redirects to profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.people));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Редирект: /friends → /profile (needsAuth)
    expect(find.text('Войдите в аккаунт'), findsOneWidget);
  });

  testWidgets('Register form has title and link to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byTooltip('Войти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Уже есть аккаунт? Войти'), findsOneWidget);
  });
}
