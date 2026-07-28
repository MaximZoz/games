import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_viewport.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Phone portrait: BottomNavigationBar, no NavigationRail',
      (tester) async {
    // С /login на phone нет nav — заходим в профиль через tablet→phone.
    await openGuestProfileOnPhone(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
    expect(find.text('Друзья'), findsWidgets);
    expect(find.text('Чаты'), findsWidgets);
    expect(find.text('Игры'), findsWidgets);
    expect(find.text('Настройки'), findsWidgets);
  });

  testWidgets('Tablet: NavigationRail, no BottomNavigationBar',
      (tester) async {
    setTablet(tester);
    await pumpMultiGamesApp(tester);
    await goToProfileTab(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Phone landscape: NavigationRail instead of bottom nav',
      (tester) async {
    setPhoneLandscape(tester);
    await pumpMultiGamesApp(tester);
    await goToProfileTab(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('Phone on login: bottom nav hidden', (tester) async {
    setPhonePortrait(tester);
    await pumpMultiGamesApp(tester);

    expect(find.text('Вход'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('Phone login form is scrollable and full-bleed width',
      (tester) async {
    setPhonePortrait(tester);
    await pumpMultiGamesApp(tester);

    expect(find.text('Вход'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);

    final boxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final hasFullWidth = boxes.any((b) => b.constraints.maxWidth == 390);
    expect(hasFullWidth, isTrue);
  });

  testWidgets('Phone profile guest CTA is visible without overflow',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(find.text('Чтобы настроить личный профиль'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phone bottom nav: Profile → Settings redirects to login',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Вход'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('Phone bottom nav: Profile stays on guest profile',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
