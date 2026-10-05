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

  testWidgets('в разработке одна неактивная кнопка', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: GameCardActionsRow(
              createLabel: 'Создать игру',
              creatingLabel: 'Создание…',
              onCreate: null,
              findLabel: 'Поиск игроков',
              findingLabel: 'Поиск…',
              onFind: null,
              inDevelopment: true,
            ),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(FramedButton, 'В разработке'), findsOneWidget);
    expect(find.text('Создать игру'), findsNothing);
    expect(find.text('Поиск игроков'), findsNothing);
    expect(find.text('Играть'), findsNothing);
    final button = tester.widget<FramedButton>(
      find.widgetWithText(FramedButton, 'В разработке'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('кнопки одной высоты на узкой и широкой карточке', (tester) async {
    await tester.pumpWidget(_wrap(280));
    final narrow = tester.getSize(
      find.widgetWithText(FramedButton, 'Создать игру'),
    );
    await tester.pumpWidget(_wrap(400));
    final wide = tester.getSize(
      find.widgetWithText(FramedButton, 'Создать игру'),
    );
    expect(narrow.height, wide.height);
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
