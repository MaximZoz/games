import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';

void main() {
  testWidgets('isPhoneLandscape only for narrow + landscape', (tester) async {
    late bool phoneLandscape;
    late bool narrow;
    late bool wide;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: Builder(
            builder: (context) {
              phoneLandscape = isPhoneLandscape(context);
              narrow = isNarrow(context);
              wide = isWide(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(narrow, isTrue);
    expect(wide, isFalse);
    expect(phoneLandscape, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              phoneLandscape = isPhoneLandscape(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(phoneLandscape, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(
            builder: (context) {
              phoneLandscape = isPhoneLandscape(context);
              wide = isWide(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(wide, isTrue);
    expect(phoneLandscape, isFalse);
  });
}
