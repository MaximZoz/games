import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

void main() {
  testWidgets('чип карточки заливается цветом фона приложения', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCardChip(
            label: '3',
            icon: Icons.groups_rounded,
            onTap: () {},
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(GameCardChip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surfaceUnified);
    expect(decoration.color, AppColors.buttonFill);
  });

  testWidgets('неактивный чип тоже заливается цветом фона приложения',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCardChip(
            label: '2',
            icon: Icons.groups_rounded,
            onTap: null,
            selected: false,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(GameCardChip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surfaceUnified);
  });

  testWidgets('короткий и длинный чип одной высоты', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              GameCardChip(
                label: '2',
                icon: Icons.groups_rounded,
                onTap: () {},
              ),
              GameCardChip(
                label: 'Переводной',
                icon: Icons.swap_horiz_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final short = tester.getSize(find.byType(GameCardChip).at(0));
    final long = tester.getSize(find.byType(GameCardChip).at(1));
    expect(short.height, long.height);
    expect(
      short.height,
      greaterThanOrEqualTo(
        gameCardChipHeight(compact: false, isDesktop: false),
      ),
    );
  });

  testWidgets('кнопки карточки заливаются цветом фона приложения',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCardActionsRow(
            createLabel: 'Создать игру',
            creatingLabel: 'Создание…',
            onCreate: () {},
            findLabel: 'Поиск игроков',
            findingLabel: 'Поиск…',
            onFind: () {},
          ),
        ),
      ),
    );

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(FramedButton),
        matching: find.byType(Material),
      ),
    );
    expect(materials.length, 2);
    for (final material in materials) {
      expect(material.color, AppColors.surfaceUnified);
    }
  });
}
