import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_material.dart';

void main() {
  test('старт — ни шашек, ни дамок в перевесе', () {
    final board = CheckersEngine.newGame(CheckersEngine.modeRussian).board;
    expect(checkersMaterialDiff(board, 0), const CheckersMaterialDiff(men: 0, kings: 0));
    expect(checkersMaterialDiff(board, 1), const CheckersMaterialDiff(men: 0, kings: 0));
  });

  test('знак считается от места: шашки и дамки отдельно', () {
    final board = List<int>.filled(64, CheckersEngine.empty);
    board[0] = CheckersEngine.whiteMan;
    board[1] = CheckersEngine.whiteMan;
    board[2] = CheckersEngine.blackMan;
    board[3] = CheckersEngine.whiteKing;
    board[4] = CheckersEngine.blackKing;
    board[5] = CheckersEngine.blackKing;
    expect(checkersMaterialDiff(board, 0), const CheckersMaterialDiff(men: 1, kings: -1));
    expect(checkersMaterialDiff(board, 1), const CheckersMaterialDiff(men: -1, kings: 1));
  });

  testWidgets('на строке шашка и дамка со знаком', (tester) async {
    final board = List<int>.filled(64, CheckersEngine.empty);
    board[0] = CheckersEngine.whiteMan;
    board[1] = CheckersEngine.whiteMan;
    board[2] = CheckersEngine.blackMan;
    board[3] = CheckersEngine.whiteKing;
    board[4] = CheckersEngine.blackKing;
    board[5] = CheckersEngine.blackKing;
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CheckersMaterialLine(board: board, seat: 0),
      ),
    ));
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
  });
}
