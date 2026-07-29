import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

import 'test_locale.dart';
import 'test_viewport.dart';

Future<void> _openRegisterFromLogin(WidgetTester tester) async {
  expect(find.text('Вход'), findsOneWidget);
  await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('Регистрация'), findsOneWidget);
}

Finder _registerFields() => find.byType(TextFormField);

void main() {
  setUp(setUpTestLocaleRu);

  group('Auth UI flows (phone)', () {
    testWidgets('Login ↔ Register round-trip', (tester) async {
      setPhonePortrait(tester);
      await pumpMultiGamesApp(tester);

      await _openRegisterFromLogin(tester);

      await tester.tap(find.text('Уже есть аккаунт? Войти'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Вход'), findsOneWidget);

      await _openRegisterFromLogin(tester);
      expect(find.text('Создайте аккаунт для игры'), findsOneWidget);
    });

    testWidgets('Login empty submit shows validation', (tester) async {
      setPhonePortrait(tester);
      await pumpMultiGamesApp(tester);

      await tester.tap(find.text('Войти').last);
      await tester.pump();

      expect(find.text('Введите email или логин'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
    });

    testWidgets('Register empty submit shows all validators', (tester) async {
      setPhonePortrait(tester);
      await pumpMultiGamesApp(tester);
      await _openRegisterFromLogin(tester);

      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pump();

      expect(find.text('Введите имя'), findsOneWidget);
      expect(find.text('Введите email'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
    });

    testWidgets('Register rejects bad email and short password',
        (tester) async {
      setPhonePortrait(tester);
      await pumpMultiGamesApp(tester);
      await _openRegisterFromLogin(tester);

      // Порядок полей: имя, email, пароль
      await tester.enterText(_registerFields().at(0), 'PlayerOne');
      await tester.enterText(_registerFields().at(1), 'not-an-email');
      await tester.enterText(_registerFields().at(2), '123');
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pump();

      expect(find.text('Некорректный email'), findsOneWidget);
      expect(find.text('Пароль не короче 6 символов'), findsOneWidget);
    });

    testWidgets('Login password visibility toggle', (tester) async {
      setPhonePortrait(tester);
      await pumpMultiGamesApp(tester);

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('Profile CTA opens Login then Register', (tester) async {
      await openGuestProfileOnPhone(tester);

      expect(find.text('Войдите в аккаунт'), findsOneWidget);
      await tester.tap(find.text('Войти').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Вход'), findsOneWidget);

      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Регистрация'), findsOneWidget);
    });
  });

  group('Guest protected routes (phone)', () {
    testWidgets('Home tab → login', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('Friends tab → login', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.people));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('Chats tab → login', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('Games tab → login', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.sports_esports));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('Settings tab → login', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('Guest can stay on Profile without crash', (tester) async {
      await openGuestProfileOnPhone(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Войдите в аккаунт'), findsOneWidget);
      expect(find.text('Регистрация'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Swipe-back on phone viewport', () {
    testWidgets('SwipeBackScope fires on phone-sized screen', (tester) async {
      setPhonePortrait(tester);
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SwipeBackScope(
            triggerDistance: 28,
            topInset: 0,
            onBack: () => backs++,
            child: const Scaffold(
              body: SizedBox.expand(child: Text('page')),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(8, 400));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(backs, 1);
      await gesture.up();
    });

    testWidgets('Swipe does not fire inside topInset zone', (tester) async {
      setPhonePortrait(tester);
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SwipeBackScope(
            triggerDistance: 28,
            topInset: 56,
            onBack: () => backs++,
            child: Scaffold(
              appBar: AppBar(title: const Text('Title')),
              body: const SizedBox.expand(child: Text('page')),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(8, 20));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(backs, 0);
      await gesture.up();

      final gesture2 = await tester.startGesture(const Offset(8, 200));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(backs, 1);
      await gesture2.up();
    });
  });

  group('Desktop vs phone nav consistency', () {
    testWidgets('Tablet rail has labels; phone shows one caption under icons',
        (tester) async {
      const labels = [
        'Главная',
        'Профиль',
        'Друзья',
        'Чаты',
        'Игры',
        'Настройки',
      ];

      setTablet(tester);
      await pumpMultiGamesApp(tester);
      await goToProfileTab(tester);
      for (final label in labels) {
        expect(find.text(label), findsWidgets, reason: 'rail: $label');
      }

      setPhonePortrait(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('mobile-bottom-nav')), findsOneWidget);
      // На phone одна подпись — текущий таб.
      expect(find.text('Профиль'), findsWidgets);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
