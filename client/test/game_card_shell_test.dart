import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

Widget _shell({
  required String title,
  required List<String> chipLabels,
  required Key actionsKey,
}) {
  return GameCardShell(
    header: GameCardHeader(
      title: title,
      icon: Icons.style_rounded,
      onInfoTap: () {},
    ),
    chips: [
      for (final label in chipLabels)
        GameCardChip(
          label: label,
          icon: Icons.groups_rounded,
          onTap: () {},
        ),
    ],
    actions: KeyedSubtree(
      key: actionsKey,
      child: GameCardActionsRow(
        createLabel: 'Создать игру',
        creatingLabel: 'Создание…',
        onCreate: () {},
        findLabel: 'Поиск игроков',
        findingLabel: 'Поиск…',
        onFind: () {},
      ),
    ),
  );
}

void main() {
  test('два ряда чипов выше одного', () {
    expect(
      gameCardTitleMinHeight(isDesktop: false, isMedium: false),
      greaterThan(30),
    );
    expect(
      gameCardChipsMinHeight(compact: false, isDesktop: false),
      greaterThan(40),
    );
  });

  testWidgets('в ряду карточки одной высоты, кнопки у нижнего края',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 680,
              child: gamesHubEqualHeightGrid(
                cols: 2,
                gap: 16,
                tileWidth: 320,
                tiles: [
                  _shell(
                    title: 'Дурак',
                    chipLabels: const ['2', '1 мин', 'Переводной', '24 карты'],
                    actionsKey: const ValueKey('durak-actions'),
                  ),
                  _shell(
                    title: 'Уно',
                    chipLabels: const ['2', '1 мин'],
                    actionsKey: const ValueKey('uno-actions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final durak = tester.getSize(find.byType(GameCardShell).at(0));
    final uno = tester.getSize(find.byType(GameCardShell).at(1));
    expect(durak.height, uno.height);
    expect(durak.height, greaterThan(180));

    final durakChips = tester.getRect(find.byType(Wrap).at(0));
    final unoChips = tester.getRect(find.byType(Wrap).at(1));
    expect(durakChips.height, greaterThan(unoChips.height + 8));

    final durakBtns = tester.getRect(find.byKey(const ValueKey('durak-actions')));
    final unoBtns = tester.getRect(find.byKey(const ValueKey('uno-actions')));
    expect((durakBtns.bottom - unoBtns.bottom).abs(), lessThan(1));
    expect((durakBtns.top - unoBtns.top).abs(), lessThan(1));

    final durakCard = tester.getRect(find.byType(GameCardShell).at(0));
    expect(durakCard.bottom - durakBtns.bottom, lessThan(28));
    expect(find.widgetWithText(FramedButton, 'Создать игру'), findsNWidgets(2));
  });

  testWidgets('все плитки сетки одной высоты, даже в разных рядах',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 680,
              child: gamesHubEqualHeightGrid(
                cols: 2,
                gap: 16,
                tileWidth: 320,
                tiles: [
                  _shell(
                    title: 'Дурак',
                    chipLabels: const ['2', '1 мин', 'Переводной', '24 карты'],
                    actionsKey: const ValueKey('a'),
                  ),
                  _shell(
                    title: 'Уно',
                    chipLabels: const ['2', '1 мин'],
                    actionsKey: const ValueKey('b'),
                  ),
                  _shell(
                    title: 'Покер',
                    chipLabels: const ['3', '1 мин'],
                    actionsKey: const ValueKey('c'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final a = tester.getSize(find.byType(GameCardShell).at(0));
    final b = tester.getSize(find.byType(GameCardShell).at(1));
    final c = tester.getSize(find.byType(GameCardShell).at(2));
    expect(a.height, b.height);
    expect(a.height, c.height);
  });
}
