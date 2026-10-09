import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';

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
    late int rows;
    late bool fill;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1920, 1080)),
        child: Builder(
          builder: (context) {
            cols = shopTileColumns(context);
            rows = shopTileRows(context, maxHeight: 900);
            fill = shopEmojiFillViewport(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(cols, 3);
    expect(rows, 3);
    expect(fill, isFalse);
  });

  testWidgets('shop tiles are 4+ columns on phone landscape', (tester) async {
    late int cols;
    late int rows;
    late bool fill;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 360)),
        child: Builder(
          builder: (context) {
            cols = shopTileColumns(context, maxWidth: 720);
            rows = shopTileRows(context, maxHeight: 280);
            fill = shopEmojiFillViewport(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(cols, greaterThanOrEqualTo(4));
    expect(rows, 2);
    expect(fill, isTrue);
  });

  testWidgets('shop tiles: в альбоме телефона всегда 2 ряда', (tester) async {
    late int shortRows;
    late int tallRows;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 360)),
        child: Builder(
          builder: (context) {
            shortRows = shopTileRows(context, maxHeight: 280);
            tallRows = shopTileRows(context, maxHeight: 420);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(shortRows, 2);
    expect(tallRows, 2);
  });

  testWidgets('ShopFillGrid растягивает 2 ряда без переполнения',
      (tester) async {
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) {
        fail('сетка обрезалась: ${details.exception}');
      }
      FlutterError.presentError(details);
    };
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(800, 280)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 220,
              child: ShopFillGrid(
                columns: 6,
                rows: 2,
                itemCount: 12,
                itemBuilder: _fillCell,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    final first = tester.getRect(find.text('0'));
    final last = tester.getRect(find.text('11'));
    expect(first.top, lessThan(last.top));
    expect(last.bottom, lessThanOrEqualTo(220 + 0.5));
  });
}

Widget _fillCell(BuildContext context, int index) {
  return ColoredBox(
    color: const Color(0xFFCCCCCC),
    child: Center(child: Text('$index')),
  );
}
