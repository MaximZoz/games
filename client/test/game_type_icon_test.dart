import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';
import 'package:multigames_client/ui/widgets/poker_game_icon.dart';

void main() {
  group('GameTypeIcon.iconDataOf', () {
    test('maps every known game to the list-card icon', () {
      expect(GameTypeIcon.iconDataOf('tictactoe'), Icons.grid_3x3_rounded);
      expect(GameTypeIcon.iconDataOf('durak'), DurakGameIcon.iconData);
      expect(
        GameTypeIcon.iconDataOf('battleship'),
        Icons.directions_boat_filled_rounded,
      );
      expect(GameTypeIcon.iconDataOf('poker'), PokerGameIcon.iconData);
    });

    test('unknown type falls back to gamepad', () {
      expect(GameTypeIcon.iconDataOf('unknown'), Icons.sports_esports_rounded);
      expect(GameTypeIcon.iconDataOf(''), Icons.sports_esports_rounded);
    });
  });

  testWidgets('player-info chips use the correct icon for each game',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              GameTypeScoreChip(
                gameType: 'tictactoe',
                won: 1,
                lost: 0,
                drawn: 0,
              ),
              GameTypeScoreChip(
                gameType: 'durak',
                won: 2,
                lost: 1,
                drawn: 0,
              ),
              GameTypeScoreChip(
                gameType: 'battleship',
                won: 3,
                lost: 2,
                drawn: 1,
              ),
              GameTypeScoreChip(
                gameType: 'poker',
                won: 4,
                lost: 3,
                drawn: 2,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.grid_3x3_rounded), findsOneWidget);
    expect(find.byType(DurakGameIcon), findsOneWidget);
    expect(find.byIcon(Icons.directions_boat_filled_rounded), findsOneWidget);
    expect(find.byType(PokerGameIcon), findsOneWidget);
    expect(find.byIcon(Icons.casino_rounded), findsNothing);
    expect(find.byIcon(Icons.sports_esports_rounded), findsNothing);
    expect(find.byIcon(Icons.sailing_rounded), findsNothing);
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);
  });
}
