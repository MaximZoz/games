import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/widgets/app_shell.dart';

void main() {
  group('gameIdFromPath / activeGameUsable', () {
    test('parses game id from path', () {
      expect(
        gameIdFromPathForTest(
          '/games/tictactoe/game/abc-123',
        ),
        'abc-123',
      );
      expect(
        gameIdFromPathForTest('/games/durak/game/d-99'),
        'd-99',
      );
      expect(gameIdFromPathForTest('/games'), isNull);
      expect(gameIdFromPathForTest('/games/tictactoe/lobby/x'), isNull);
    });

    test('active game with id is usable', () {
      expect(
        activeGameUsableForTest(
          ActiveGameItem(type: 'game', gameId: 'g1'),
        ),
        isTrue,
      );
      expect(activeGameUsableForTest(null), isFalse);
      expect(
        activeGameUsableForTest(ActiveGameItem(type: 'game')),
        isFalse,
      );
    });
  });

  group('gamesLobbyTabIndexForAnimation', () {
    test('игры до середины свайпа, лобби после', () {
      expect(gamesLobbyTabIndexForAnimation(0), 0);
      expect(gamesLobbyTabIndexForAnimation(0.49), 0);
      expect(gamesLobbyTabIndexForAnimation(0.5), 1);
      expect(gamesLobbyTabIndexForAnimation(1), 1);
    });

    test('анимация вкладки короче дефолтных 300 мс', () {
      expect(gamesLobbyTabAnimation.inMilliseconds, lessThan(300));
      expect(gamesLobbyTabAnimation.inMilliseconds, greaterThan(0));
    });
  });

  group('gamesHubTileColumns / width', () {
    test('на телефоне одна колонка на всю ширину', () {
      expect(gamesHubTileColumns(maxWidth: 540, wide: false), 1);
      expect(gamesHubTileWidth(maxWidth: 540, cols: 1), 540);
      expect(gamesHubStackActions(320), isTrue);
      expect(gamesHubStackActions(400), isFalse);
    });

    test('на широком экране несколько колонок', () {
      expect(gamesHubTileColumns(maxWidth: 1100, wide: true), greaterThan(1));
      expect(gamesHubTileWidth(maxWidth: 1100, cols: 3), lessThan(400.1));
    });
  });
}
