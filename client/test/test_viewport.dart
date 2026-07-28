import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/main.dart';

/// iPhone-подобный viewport (devicePixelRatio=1 → logical == physical).
void setPhonePortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void setPhoneLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(844, 390);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void setTablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpMultiGamesApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MultiGamesApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> goToProfileTab(WidgetTester tester) async {
  final person = find.byIcon(Icons.person);
  expect(person, findsWidgets);
  await tester.tap(person.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// С /login на phone нет bottom nav — сначала wide (rail), затем phone.
Future<void> openGuestProfileOnPhone(WidgetTester tester) async {
  setTablet(tester);
  await pumpMultiGamesApp(tester);
  await goToProfileTab(tester);
  setPhonePortrait(tester);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const ValueKey('mobile-bottom-nav')), findsOneWidget);
}
