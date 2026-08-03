import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/invite_link.dart';

void main() {
  group('gamePathPrefixFor', () {
    test('durak и tictactoe имеют разные префиксы', () {
      expect(gamePathPrefixFor('durak'), '/games/durak/game/');
      expect(gamePathPrefixFor('tictactoe'), '/games/tictactoe/game/');
      expect(gamePathPrefixFor('unknown'), '/games/tictactoe/game/');
    });

    test('lobbyPathPrefixFor', () {
      expect(lobbyPathPrefixFor('durak'), '/games/durak/lobby/');
      expect(lobbyPathPrefixFor('tictactoe'), '/games/tictactoe/lobby/');
    });
  });

  group('GameNavigationCoordinator', () {
    test('строит durak-путь при gameType=durak', () {
      final c = GameNavigationCoordinator();
      expect(
        c.targetForGame('g1', currentPath: '/games', gameType: 'durak'),
        '/games/durak/game/g1',
      );
    });

    test('по умолчанию tictactoe', () {
      final c = GameNavigationCoordinator();
      expect(
        c.targetForGame('g1', currentPath: '/games'),
        '/games/tictactoe/game/g1',
      );
    });

    test('не навигирует если уже на целевом пути', () {
      final c = GameNavigationCoordinator();
      expect(
        c.targetForGame('g1',
            currentPath: '/games/durak/game/g1', gameType: 'durak'),
        isNull,
      );
    });
  });

  group('realtimeGameNavForEvent', () {
    test('берёт game_type из события', () {
      final nav = realtimeGameNavForEvent(
        {'type': 'game_started', 'game_id': 'g7', 'game_type': 'durak'},
        currentPath: '/games',
      );
      expect(nav?.gameId, 'g7');
      expect(nav?.gameType, 'durak');
    });

    test('без game_type → tictactoe', () {
      final nav = realtimeGameNavForEvent(
        {'type': 'game_started', 'game_id': 'g8'},
        currentPath: '/games',
      );
      expect(nav?.gameType, 'tictactoe');
    });

    test('не срабатывает на чужие типы событий', () {
      expect(
        realtimeGameNavForEvent(
          {'type': 'chat_message', 'game_id': 'g9'},
          currentPath: '/games',
        ),
        isNull,
      );
    });
  });

  group('ActiveGameItem.gameType', () {
    test('парсит game_type из GetActive', () {
      final item = ActiveGameItem.fromJson({
        'type': 'game',
        'game_id': 'g1',
        'game_type': 'durak',
      });
      expect(item.gameType, 'durak');
    });

    test('дефолт tictactoe для обратной совместимости', () {
      final item = ActiveGameItem.fromJson({'type': 'lobby', 'lobby_id': 'l1'});
      expect(item.gameType, 'tictactoe');
    });
  });

  group('invite links', () {
    test('строит и парсит durak-ссылку', () {
      final link = buildInviteLink('lob-1', gameType: 'durak');
      expect(link, '/games/durak/lobby/lob-1?mode=invite');
      final parsed = parseInviteLobbyShareUrl(link);
      expect(parsed?.gameType, 'durak');
      expect(parsed?.lobbyId, 'lob-1');
    });

    test('tictactoe-ссылка остаётся совместимой', () {
      final parsed =
          parseInviteLobbyShareUrl('/games/tictactoe/lobby/abc?mode=invite');
      expect(parsed?.gameType, 'tictactoe');
      expect(parsed?.appPath, '/games/tictactoe/lobby/abc?mode=invite');
    });
  });
}
