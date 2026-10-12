import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

Widget _shell({
  required String title,
  required List<String> chipLabels,
  required Key actionsKey,
  bool isDesktop = false,
  bool isMedium = false,
}) {
  return GameCardShell(
    isDesktop: isDesktop,
    isMedium: isMedium,
    header: GameCardHeader(
      title: title,
      icon: Icons.style_rounded,
      onInfoTap: () {},
      isDesktop: isDesktop,
      isMedium: isMedium,
    ),
    chips: [
      for (final label in chipLabels)
        GameCardChip(
          label: label,
          icon: Icons.groups_rounded,
          onTap: () {},
          isDesktop: isDesktop,
          isMedium: isMedium,
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
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    ),
  );
}

Widget _app(Widget body) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: body)),
  );
}

void main() {
  test('два ряда чипов выше одного', () {
    expect(
      gameCardTitleMinHeight(isDesktop: false, isMedium: false),
      greaterThan(30),
    );
    expect(
      gameCardChipsMinHeight(compact: false, isDesktop: true),
      greaterThan(110),
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

  testWidgets('в одном ряду плитки одной высоты, следующий ряд по контенту',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        SizedBox(
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
    );
    await tester.pumpAndSettle();

    final a = tester.getSize(find.byType(GameCardShell).at(0));
    final b = tester.getSize(find.byType(GameCardShell).at(1));
    final c = tester.getSize(find.byType(GameCardShell).at(2));
    expect(a.height, b.height);
    expect(c.height, lessThan(a.height));
  });

  testWidgets('крестики и дурак одного размера на десктопе', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 800,
          child: gamesHubEqualHeightGrid(
            cols: 2,
            gap: 16,
            tileWidth: 392,
            tiles: [
              _shell(
                title: 'Крестики-нолики',
                chipLabels: const ['2', '1 мин', 'Классика'],
                actionsKey: const ValueKey('ttt'),
                isDesktop: true,
              ),
              _shell(
                title: 'Дурак',
                chipLabels: const ['2', '1 мин', 'Переводной', '24 карты'],
                actionsKey: const ValueKey('durak'),
                isDesktop: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ttt = tester.getSize(find.byType(GradientCard).at(0));
    final durak = tester.getSize(find.byType(GradientCard).at(1));
    expect(ttt.height, durak.height);
    expect(ttt.width, durak.width);

    final chipSizes = [
      for (var i = 0; i < tester.widgetList(find.byType(GameCardChip)).length; i++)
        tester.getSize(find.byType(GameCardChip).at(i)),
    ];
    expect(chipSizes, isNotEmpty);
    for (final size in chipSizes) {
      expect(size.height, chipSizes.first.height);
    }

    final tttWrap = tester.getSize(find.byType(Wrap).at(0));
    final durakWrap = tester.getSize(find.byType(Wrap).at(1));
    expect(durakWrap.height, greaterThan(tttWrap.height + 8));

    final tttBtns = tester.getRect(find.byKey(const ValueKey('ttt')));
    final durakBtns = tester.getRect(find.byKey(const ValueKey('durak')));
    expect((tttBtns.bottom - durakBtns.bottom).abs(), lessThan(1));
  });

  testWidgets('без сетки крестики и дурак всё равно одной высоты',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 392,
              child: GameCardLayout(
                cardWidth: 392,
                child: _shell(
                  title: 'Крестики-нолики',
                  chipLabels: const ['2', '1 мин', 'Классика'],
                  actionsKey: const ValueKey('ttt'),
                  isDesktop: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 392,
              child: GameCardLayout(
                cardWidth: 392,
                child: _shell(
                  title: 'Дурак',
                  chipLabels: const ['2', '1 мин', 'Переводной', '24 карты'],
                  actionsKey: const ValueKey('durak'),
                  isDesktop: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ttt = tester.getSize(find.byType(GradientCard).at(0));
    final durak = tester.getSize(find.byType(GradientCard).at(1));
    expect(ttt.height, durak.height);
  });

  testWidgets('ставка стоит первой среди переключателей, не в шапке',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 640,
          child: GameCardShell(
            header: GameCardHeader(
              title: 'Крестики-нолики',
              icon: Icons.grid_3x3_rounded,
              onInfoTap: _noop,
            ),
            stakeChip: GameCardStakeChip(
              stakeBronze: 2,
              onTap: _noop,
            ),
            chips: [
              GameCardChip(
                label: '2',
                icon: Icons.groups_rounded,
                onTap: _noop,
              ),
              GameCardChip(
                label: '20 с',
                icon: Icons.timer_outlined,
                onTap: _noop,
              ),
              GameCardChip(
                label: 'Классика',
                icon: Icons.close_rounded,
                onTap: _noop,
              ),
            ],
            actions: SizedBox(height: 46),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(GameCardHeader),
        matching: find.byType(GameCardStakeChip),
      ),
      findsNothing,
    );
    final title = tester.getRect(find.textContaining('Крестики'));
    final stake = tester.getRect(find.byType(GameCardStakeChip));
    final time = tester.getRect(find.widgetWithText(GameCardChip, '20 с'));
    expect(stake.top, greaterThan(title.bottom - 1));
    expect(stake.left, lessThan(time.left));
    expect((stake.top - time.top).abs(), lessThan(2));
  });
}

void _noop() {}
