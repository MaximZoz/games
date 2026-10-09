import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  for (final width in [320.0, 390.0, 800.0]) {
    testWidgets('ничья: кнопки в одну линию при ширине $width', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => confirmDrawDialog(context),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final cancel = tester.getRect(find.widgetWithText(FramedButton, 'Отмена'));
      final offer =
          tester.getRect(find.widgetWithText(FramedButton, 'Предложить ничью'));
      expect((cancel.top - offer.top).abs(), lessThan(1));
      expect(offer.left - cancel.right, greaterThanOrEqualTo(8));
      expect(cancel.left, greaterThanOrEqualTo(0));
      expect(offer.right, lessThanOrEqualTo(width + 0.5));
    });
  }
}
