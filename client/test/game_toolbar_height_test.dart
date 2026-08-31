import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';

Future<double> _toolbarHeightFor(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  late double height;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          height = gameToolbarHeight(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return height;
}

void main() {
  testWidgets('портрет телефона — обычная высота шапки', (tester) async {
    expect(
      await _toolbarHeightFor(tester, const Size(390, 844)),
      kToolbarHeight,
    );
  });

  testWidgets('альбом телефона — шапка ниже', (tester) async {
    final height = await _toolbarHeightFor(tester, const Size(844, 390));
    expect(height, 44);
    expect(height, lessThan(kToolbarHeight));
  });

  testWidgets('планшет в альбоме — высота не режется', (tester) async {
    expect(
      await _toolbarHeightFor(tester, const Size(1180, 820)),
      kToolbarHeight,
    );
  });
}
