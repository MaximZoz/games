import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/shop_section_help.dart';

void main() {
  testWidgets('справка магазина открывается и закрывается', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showShopSectionHelp(
                context: context,
                title: 'Коллекции',
                body: 'Зачем нужны коллекции',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Коллекции'), findsOneWidget);
    expect(find.text('Зачем нужны коллекции'), findsOneWidget);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Зачем нужны коллекции'), findsNothing);
  });
}
