// Базовые виджет-тесты клиента MultiGames.
// Не используем pumpAndSettle: на главной есть сетевой запрос и async auth — они не завершаются в тесте.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:multigames_client/main.dart';
import 'package:multigames_client/ui/widgets/zozu_boot_splash.dart';

Widget _testApp() => ProviderScope(
      overrides: [
        bootSplashEnabledProvider.overrideWith((ref) => false),
      ],
      child: const MultiGamesApp(),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('Unauthenticated app opens login instead of home',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // `/` требует авторизации → редирект на вход
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('App uses MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login page shows form and toolbar auth button',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Вход'), findsOneWidget);
    expect(find.byTooltip('На главную'), findsNothing);
    final hasLogin = find.byTooltip('Войти').evaluate().isNotEmpty;
    final hasLoading =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasLogin || hasLoading, isTrue);
  });

  testWidgets('Navigation shows main sections from profile',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Профиль доступен без auth — там видна навигация (иконки + подпись таба).
    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person), findsWidgets);
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Unauthenticated user tapping Home redirects to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('Profile for unauthenticated user shows login prompt',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(find.text('Чтобы настроить личный профиль'), findsOneWidget);
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Регистрация'), findsOneWidget);
  });

  testWidgets('Profile → Login → Register → Login navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
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

  testWidgets('Login form shows validation errors on empty submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Уже на /login после редиректа с главной
    final loginButtons = find.text('Войти');
    expect(loginButtons, findsWidgets);
    await tester.tap(loginButtons.last);
    await tester.pump();

    expect(find.text('Введите email или логин'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('Unauthenticated user tapping Friends redirects to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.people));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Редирект: /friends → /login?redirect=/friends (needsAuth)
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('Register form has title and link to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
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
