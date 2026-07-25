import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/tictactoe_lobby_screen.dart';

void main() {
  group('tictactoeLobbyAppBarTitle', () {
    test('uses invite initialMode while lobby is still loading', () {
      expect(
        tictactoeLobbyAppBarTitle(initialMode: 'invite'),
        'Своя игра',
      );
    });

    test('uses matchmake initialMode while lobby is still loading', () {
      expect(
        tictactoeLobbyAppBarTitle(initialMode: 'matchmake'),
        'Лобби',
      );
    });

    test('prefers loaded status over initialMode', () {
      expect(
        tictactoeLobbyAppBarTitle(
          status: 'waiting_invite',
          initialMode: 'matchmake',
        ),
        'Своя игра',
      );
      expect(
        tictactoeLobbyAppBarTitle(
          status: 'waiting_matchmake',
          initialMode: 'invite',
        ),
        'Лобби',
      );
    });

    test('does not default to Лобби without mode or status', () {
      expect(tictactoeLobbyAppBarTitle(), isEmpty);
    });
  });
}
