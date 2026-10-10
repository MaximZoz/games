import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/shop/collection_widgets.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required DateTime acquired,
    int shift = 0,
    DateTime? vintageAt,
    List<CollectionElixirButton> actions = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showCollectionFullscreen(
                    context,
                    title: 'Природа',
                    animatedName: 'sparkles',
                    artwork: const SizedBox(width: 24, height: 24),
                    acquiredAt: acquired,
                    conditionShift: shift,
                    vintageAt: vintageAt,
                    elixirActions: actions,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('открытая коллекция показывает срок до следующего состояния',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final acquired = DateTime.now().toUtc().subtract(const Duration(days: 1));
    await open(tester, acquired: acquired);

    expect(find.text('Природа'), findsOneWidget);
    expect(find.text('Новое'), findsNWidgets(2));
    expect(find.text('Потрепанное'), findsOneWidget);
    expect(find.text('Уставшее'), findsOneWidget);
    expect(find.text('Ветхое'), findsOneWidget);
    expect(find.text('Винтаж'), findsOneWidget);
    expect(find.byKey(const Key('condition-scale-marker')), findsOneWidget);
    expect(find.textContaining(RegExp(r'До потрепанного \d+')), findsOneWidget);
  });

  testWidgets('у винтажа таймера нет, кнопки эликсира на геймпаде',
      (tester) async {
    final acquired = DateTime.now().toUtc().subtract(const Duration(days: 400));
    await open(
      tester,
      acquired: acquired,
      actions: [
        CollectionElixirButton(
          effect: 'rejuvenate',
          label: 'Омолодить',
          onPressed: () async => null,
        ),
      ],
    );

    expect(find.text('Винтаж'), findsNWidgets(2));
    expect(find.textContaining('До '), findsNothing);
    expect(find.widgetWithText(GamepadBuyButton, 'Омолодить'), findsOneWidget);
  });
}
