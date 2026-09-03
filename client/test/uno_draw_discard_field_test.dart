import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_center_table_style.dart';
import 'package:multigames_client/ui/uno/uno_draw_discard_field.dart';

void main() {
  testWidgets('альбом 150px: Колода и Сброс внутри овала, без overflow',
      (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final style = UnoCenterTableStyle.of(
      narrow: true,
      phoneLandscape: true,
    );
    FlutterError? overflow;
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is FlutterError &&
          details.exception.toString().contains('overflowed')) {
        overflow = details.exception as FlutterError;
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 150,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: UnoDrawDiscardField(
                  style: style,
                  drawLabel: 'Колода',
                  discardLabel: 'Сброс',
                  currentColor: const Color(0xFFE53935),
                  drawPile: SizedBox.fromSize(size: style.cardSize),
                  discardPile: SizedBox.fromSize(size: style.cardSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(overflow, isNull);
    expect(find.text('Колода'), findsOneWidget);
    expect(find.text('Сброс'), findsOneWidget);

    final field = tester.getRect(find.byType(UnoDrawDiscardField));
    final draw = tester.getRect(find.text('Колода'));
    final discard = tester.getRect(find.text('Сброс'));
    expect(draw.bottom, lessThanOrEqualTo(field.bottom + 0.5));
    expect(discard.bottom, lessThanOrEqualTo(field.bottom + 0.5));
    expect(draw.top, greaterThanOrEqualTo(field.top - 0.5));
  });
}
