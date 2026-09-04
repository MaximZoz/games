import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

Widget _wrap(double width) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: GameCardActionsRow(
            createLabel: 'Создать игру',
            creatingLabel: 'Создание…',
            onCreate: () {},
            findLabel: 'Поиск игроков',
            findingLabel: 'Поиск…',
            onFind: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('на узкой карточке обе кнопки в один ряд', (tester) async {
    await tester.pumpWidget(_wrap(280));

    final create = tester.getRect(find.widgetWithText(FramedButton, 'Создать игру'));
    final findBtn =
        tester.getRect(find.widgetWithText(FramedButton, 'Поиск игроков'));

    expect((create.center.dy - findBtn.center.dy).abs(), lessThan(2));
    expect(create.right, lessThanOrEqualTo(findBtn.left + 1));
    expect(create.width, greaterThan(80));
    expect(findBtn.width, greaterThan(80));
  });

  testWidgets('на очень узкой карточке ряд сохраняется', (tester) async {
    await tester.pumpWidget(_wrap(240));

    final create = tester.getRect(find.widgetWithText(FramedButton, 'Создать игру'));
    final findBtn =
        tester.getRect(find.widgetWithText(FramedButton, 'Поиск игроков'));

    expect((create.center.dy - findBtn.center.dy).abs(), lessThan(2));
    expect(create.right, lessThanOrEqualTo(findBtn.left + 1));
  });

  testWidgets('на широкой карточке кнопки тоже в ряд', (tester) async {
    await tester.pumpWidget(_wrap(400));

    final create = tester.getRect(find.widgetWithText(FramedButton, 'Создать игру'));
    final findBtn =
        tester.getRect(find.widgetWithText(FramedButton, 'Поиск игроков'));

    expect((create.center.dy - findBtn.center.dy).abs(), lessThan(2));
    expect(create.right, lessThanOrEqualTo(findBtn.left + 1));
  });
}
