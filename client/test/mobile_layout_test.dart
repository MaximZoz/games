import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_locale.dart';
import 'test_viewport.dart';

Finder mobileBottomNav() => find.byKey(const ValueKey('mobile-bottom-nav'));

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('Phone portrait: icon-only bottom nav, no NavigationRail',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    expect(mobileBottomNav(), findsOneWidget);
    expect(tester.getSize(mobileBottomNav()).height, lessThan(52));
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    // Одна подпись — текущий таб (Профиль).
    expect(find.text('Профиль'), findsWidgets);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Tablet: NavigationRail, no mobile bottom nav', (tester) async {
    setTablet(tester);
    await pumpMultiGamesApp(tester);
    await goToProfileTab(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(mobileBottomNav(), findsNothing);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Phone landscape: NavigationRail instead of bottom nav',
      (tester) async {
    setPhoneLandscape(tester);
    await pumpMultiGamesApp(tester);
    await goToProfileTab(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(mobileBottomNav(), findsNothing);
  });

  testWidgets('Phone on login: bottom nav hidden', (tester) async {
    setPhonePortrait(tester);
    await pumpMultiGamesApp(tester);

    expect(find.text('Вход'), findsOneWidget);
    expect(mobileBottomNav(), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('Phone login form is scrollable and full-bleed width',
      (tester) async {
    setPhonePortrait(tester);
    await pumpMultiGamesApp(tester);

    expect(find.text('Вход'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);

    final boxes =
        tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final hasFullWidth = boxes.any((b) => b.constraints.maxWidth == 390);
    expect(hasFullWidth, isTrue);
  });

  testWidgets('Phone landscape profile card is vertically centered',
      (tester) async {
    setTablet(tester);
    await pumpMultiGamesApp(tester);
    await goToProfileTab(tester);
    setPhoneLandscape(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    final top = tester.getTopLeft(find.text('Войдите в аккаунт')).dy;
    // Прижатие к тулбару давало бы ~60–120; центр — ниже.
    expect(top, greaterThan(150));
  });

  testWidgets('Phone portrait profile card is vertically centered',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    final top = tester.getTopLeft(find.text('Войдите в аккаунт')).dy;
    // Прижатие к верху давало бы ~80–140 на 844px высоты.
    expect(top, greaterThan(200));
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

    expect(mobileBottomNav(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Вход'), findsOneWidget);
    expect(mobileBottomNav(), findsNothing);
  });

  testWidgets('Phone bottom nav does not clip a badge above the icons',
      (tester) async {
    await openGuestProfileOnPhone(tester);
    var clipsBadge = false;
    tester.element(mobileBottomNav()).visitAncestorElements((ancestor) {
      if (ancestor.widget is ClipRect) {
        clipsBadge = true;
        return false;
      }
      if (ancestor.widget is Scaffold) return false;
      return true;
    });
    expect(clipsBadge, isFalse);
    expect(tester.getSize(mobileBottomNav()).height, lessThan(52));
  });

  testWidgets('Phone bottom nav label follows selected tab', (tester) async {
    await openGuestProfileOnPhone(tester);
    expect(find.text('Профиль'), findsWidgets);

    // Друзья → редирект на login, nav скрыт. Остаёмся на профиле и
    // проверяем, что активная иконка без заливки (просто Icon).
    final personIcons = find.byIcon(Icons.person);
    expect(personIcons, findsWidgets);
    final iconWidget = tester.widget<Icon>(personIcons.first);
    expect(iconWidget.color, isNotNull);
  });

  testWidgets('Phone bottom nav: Profile stays on guest profile',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(mobileBottomNav(), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
  });
}
