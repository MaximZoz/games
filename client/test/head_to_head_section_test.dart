import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_repository.dart';

void main() {
  testWidgets('счёт и игры стоят в одной горизонтальной полосе',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: HeadToHeadScoreStrip(
            title: 'Ваш счёт',
            games: const [
              GameTypeScore(gameType: 'durak', won: 2, lost: 1, drawn: 0),
              GameTypeScore(gameType: 'uno', won: 1, lost: 3, drawn: 1),
              GameTypeScore(gameType: 'poker', won: 4, lost: 0, drawn: 2),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ваш счёт'), findsOneWidget);
    expect(find.byType(GameTypeScoreChip), findsNWidgets(3));
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(HeadToHeadScoreStrip),
        matching: find.byType(Row).first,
      ),
    );
    expect(row.children.length, greaterThanOrEqualTo(2));
  });

  testWidgets('коллекции в витрине получают рамку геймпада', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: const Scaffold(
          body: CollectionShowcaseGrid(
            items: [
              InventoryItem(
                code: 'coll_a',
                kind: 'collection',
                title: 'А',
                description: '',
                payload: {'emoji': '🔥', 'animated_name': 'sparkles'},
              ),
              InventoryItem(
                code: 'coll_b',
                kind: 'collection',
                title: 'Б',
                description: '',
                payload: {'emoji': '💎', 'animated_name': 'sparkles'},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(GamepadFocusBlock), findsNWidgets(2));
    expect(find.byType(GamepadNavGroup), findsOneWidget);
  });
}
