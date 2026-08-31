import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

void main() {
  test('wrapGameTitle даёт перенос после дефиса', () {
    expect(wrapGameTitle('Крестики-нолики'), 'Крестики-\u200bнолики');
    expect(wrapGameTitle('Tic-tac-toe'), 'Tic-\u200btac-\u200btoe');
    expect(wrapGameTitle('Дурак'), 'Дурак');
    expect(wrapGameTitle('Морской бой'), 'Морской бой');
  });

  testWidgets('узкая карточка показывает обе части названия, не многоточие',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: GameCardHeader(
                title: 'Крестики-нолики',
                icon: Icons.grid_3x3_rounded,
                stakeBronze: 2,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Крестики'), findsOneWidget);
    expect(find.textContaining('нолики'), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);

    final title = tester.widget<Text>(find.textContaining('Крестики'));
    expect(title.maxLines, 3);
    expect(title.softWrap, isTrue);
    expect(title.data, contains('\u200b'));
  });
}
