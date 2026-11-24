import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_ui/widgets/app_button.dart';

void main() {
  testWidgets('кнопка API сразу становится лоадером и не жмётся повторно', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<void>();
    Future<void> press() {
      calls++;
      return gate.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FramedButton(
            label: 'Создать игру',
            onPressed: press,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Создать игру'));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Создать игру'), findsNothing);

    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.pump();
    expect(calls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Создать игру'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('AppButton уменьшается от касания и показывает лоадер', (
    tester,
  ) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Поиск игроков',
            onPressed: () => gate.future,
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Поиск игроков')));
    await tester.pump(const Duration(milliseconds: 40));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, lessThan(1));

    await gesture.up();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Поиск игроков'), findsOneWidget);
  });
}
