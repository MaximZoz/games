import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/tictactoe_lobby_screen.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

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

    test('invite link guest does not see Своя игра', () {
      expect(
        tictactoeLobbyAppBarTitle(
          initialMode: 'invite',
          fromInviteLink: true,
        ),
        'Войти в игру',
      );
      expect(
        tictactoeLobbyAppBarTitle(
          status: 'waiting_invite',
          fromInviteLink: true,
        ),
        'Войти в игру',
      );
    });

    test('joined invitee sees Своя игра, not Войти в игру', () {
      expect(
        tictactoeLobbyAppBarTitle(
          status: 'waiting_invite',
          fromInviteLink: true,
          isLobbyMember: true,
        ),
        'Своя игра',
      );
    });

    test('lobby app bar uses tictactoe grid icon', () {
      expect(tictactoeLobbyAppBarIcon, Icons.grid_3x3_rounded);
    });
  });
}
