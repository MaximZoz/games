import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';

void main() {
  testWidgets('opens under ProviderScope without lifecycle errors',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameStateProvider.overrideWith(
            (ref, gameId) => Completer<GameStateItem>().future,
          ),
        ],
        child: const MaterialApp(
          home: TicTacToeGameScreen(gameId: 'game-1'),
        ),
      ),
    );

    expect(find.byType(TicTacToeGameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
