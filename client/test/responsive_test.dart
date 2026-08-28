import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';

void main() {
  group('Breakpoints', () {
    test('mobile threshold is 700', () {
      expect(Breakpoints.mobile, 700);
    });
  });

  group('isNarrow / isWide', () {
    Future<bool> measureNarrow(WidgetTester tester, Size size) async {
      late bool narrow;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              narrow = isNarrow(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return narrow;
    }

    testWidgets('phone portrait is narrow', (tester) async {
      expect(await measureNarrow(tester, const Size(390, 844)), isTrue);
    });

    testWidgets('phone landscape uses shortestSide (still narrow)',
        (tester) async {
      // width 844 > 700, но shortestSide=390 < 700
      expect(await measureNarrow(tester, const Size(844, 390)), isTrue);
    });

    testWidgets('tablet / desktop is wide', (tester) async {
      expect(await measureNarrow(tester, const Size(1024, 768)), isFalse);
    });

    testWidgets('exactly 700 shortestSide is wide', (tester) async {
      expect(await measureNarrow(tester, const Size(700, 900)), isFalse);
    });

    testWidgets('699 shortestSide is narrow', (tester) async {
      expect(await measureNarrow(tester, const Size(699, 900)), isTrue);
    });

    testWidgets('isWide is inverse of isNarrow', (tester) async {
      late bool narrow;
      late bool wide;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              narrow = isNarrow(context);
              wide = isWide(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(wide, isFalse);
      expect(narrow, isTrue);
      expect(wide, isNot(narrow));
    });
  });

  testWidgets('shop tiles are 3 columns on desktop', (tester) async {
    late int cols;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1920, 1080)),
        child: Builder(
          builder: (context) {
            cols = shopTileColumns(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(cols, 3);
  });
}
