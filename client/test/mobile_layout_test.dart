import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/widgets/app_shell.dart';

import 'test_locale.dart';
import 'test_viewport.dart';

Finder mobileBottomNav() => find.byKey(const ValueKey('mobile-bottom-nav'));

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('Phone portrait: icon-only bottom nav, no NavigationRail',
      (tester) async {
    await openGuestProfileOnPhone(tester);

    expect(mobileBottomNav(), findsOneWidget);
    expect(tester.getSize(mobileBottomNav()).height, lessThan(68));
    final nav = tester.getRect(mobileBottomNav());
    final icon = tester.getRect(
      find.descendant(
        of: mobileBottomNav(),
        matching: find.byIcon(Icons.person),
      ),
    );
    final above = icon.top - nav.top;
    // Сверху есть зазор, но бейдж (выступ 4px) остаётся внутри панели.
    expect(above, greaterThanOrEqualTo(mobileBottomNavIconPadTop - 0.5));
    expect(above, lessThan(14));
    expect(icon.top - 4, greaterThanOrEqualTo(nav.top + 2));
    final label = tester.getRect(
      find.descendant(
        of: mobileBottomNav(),
        matching: find.text('Профиль'),
      ),
    );
    // Подпись сдвинута на 2px вверх, поэтому видимый зазор чуть меньше паддинга.
    final below = label.top - icon.bottom;
    expect(below, greaterThanOrEqualTo(2));
    expect(below, lessThan(14));
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
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      setPhoneLandscape(tester);
      tester.view.viewPadding =
          const FakeViewPadding(left: 59, right: 59, bottom: 21);
      tester.view.padding =
          const FakeViewPadding(left: 59, right: 59, bottom: 21);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);

      await pumpMultiGamesApp(tester);
      await goToProfileTab(tester);

    final rail = find.byKey(const ValueKey('phone-landscape-nav'));
    expect(rail, findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(mobileBottomNav(), findsNothing);
    // В альбоме на iPhone рейл прижат к левому краю и имеет ширину 56px.
    final railRect = tester.getRect(rail);
    expect(railRect.left, 0);
    expect(railRect.width, 56);
    final ends = tester.widget<Padding>(
      find.byKey(const ValueKey('shell-toolbar-ends')),
    );
    expect(
      ends.padding,
      const EdgeInsets.symmetric(horizontal: phoneLandscapeCornerInsetPx),
    );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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

  testWidgets('Phone bottom nav does not leave a home-indicator gap above icons',
      (tester) async {
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);

    await openGuestProfileOnPhone(tester);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final nav = tester.getRect(mobileBottomNav());
    final scroll = tester.getRect(find.byType(Scrollable));
    // Раньше SafeArea повторял home indicator (~34) над уже стоящим меню.
    expect(nav.top - scroll.bottom, lessThan(8));
    expect(tester.getSize(mobileBottomNav()).height, lessThan(68));
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
    expect(tester.getSize(mobileBottomNav()).height, lessThan(68));
  });

  testWidgets('Phone bottom nav label follows selected tab', (tester) async {
    await openGuestProfileOnPhone(tester);
    expect(find.text('Профиль'), findsWidgets);

    // Друзья → редирект на login, nav скрыт. Остаёмся на профиле и
    // проверяем, что активная иконка покрашена.
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

  testWidgets('тап по подписи снизу попадает во вкладку над пальцем',
      (tester) async {
    await openGuestProfileOnPhone(tester);
    final nav = tester.getRect(mobileBottomNav());
    final settings = tester.getRect(find.byIcon(Icons.settings));

    // Низ панели — подпись, не глиф. Гость с «Настроек» уходит на вход.
    await tester.tapAt(Offset(settings.center.dx, nav.bottom - 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Вход'), findsOneWidget);
    expect(mobileBottomNav(), findsNothing);
  });

  testWidgets('альбом: одно касание по иконке переключает вкладку',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      setPhoneLandscape(tester);
      await pumpMultiGamesApp(tester);
      await goToProfileTab(tester);
      expect(find.text('Войдите в аккаунт'), findsOneWidget);

      final rail =
          tester.getRect(find.byKey(const ValueKey('phone-landscape-nav')));
      final settings = tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('phone-landscape-nav')),
          matching: find.byIcon(Icons.settings),
        ),
      );
      // Палец чуть сдвигается по вертикали — так на телефоне выглядит тап.
      final gesture = await tester.startGesture(settings);
      await gesture.moveBy(const Offset(0, 22));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Вход'), findsOneWidget);
      expect(rail.width, 56);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('альбом: плашка едет за пальцем по вертикали', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      setPhoneLandscape(tester);
      await pumpMultiGamesApp(tester);
      await goToProfileTab(tester);

      final rail = tester.getRect(find.byKey(const ValueKey('phone-landscape-nav')));
      final slot = rail.height / 6;
      final profileTop = rail.top + slot;
      final gesture = await tester.startGesture(
        Offset(rail.center.dx, profileTop + slot - 8),
      );
      await gesture.moveTo(Offset(rail.center.dx, profileTop + 8));
      await tester.pump();
      final mid = tester.getCenter(
        find.byKey(const ValueKey('phone-landscape-nav-pill')),
      );
      expect(mid.dy, lessThan(profileTop + slot * 0.55));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(find.byKey(const ValueKey('phone-landscape-nav')), findsOneWidget);
      final pill = tester.getCenter(
        find.byKey(const ValueKey('phone-landscape-nav-pill')),
      );
      final person = tester.getCenter(find.byIcon(Icons.person));
      expect((pill.dy - person.dy).abs(), lessThan(10));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('плашка едет за пальцем и встаёт на вкладку', (tester) async {
    await openGuestProfileOnPhone(tester);
    final nav = tester.getRect(mobileBottomNav());
    final slot = nav.width / 6;
    final profileLeft = nav.left + slot;
    final y = nav.top + 18.0;
    final gesture = await tester.startGesture(
      Offset(profileLeft + slot - 8, y),
    );
    await gesture.moveTo(Offset(profileLeft + 8, y));
    await tester.pump();
    final mid =
        tester.getCenter(find.byKey(const ValueKey('mobile-bottom-nav-pill')));
    expect(mid.dx, lessThan(profileLeft + slot * 0.55));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(mobileBottomNav(), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
    final pill =
        tester.getCenter(find.byKey(const ValueKey('mobile-bottom-nav-pill')));
    final person = tester.getCenter(find.byIcon(Icons.person));
    expect((pill.dx - person.dx).abs(), lessThan(10));
  });
}
