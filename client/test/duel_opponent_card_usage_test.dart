import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Где каждая игра рисует соперника 1×1.
const _duelSources = <String, String>{
  'tictactoe': 'lib/screens/tictactoe_game_screen.dart',
  'durak': 'lib/screens/durak_game_screen.dart',
  'battleship': 'lib/screens/battleship_game_screen.dart',
  'poker': 'lib/screens/poker_game_screen.dart',
  'uno': 'lib/screens/uno_game_screen.dart',
  'domino': 'lib/games/domino/domino_table.dart',
  'nardy': 'lib/screens/nardy_game_screen.dart',
  'checkers': 'lib/screens/checkers_game_screen.dart',
  'chess': 'lib/screens/chess_game_screen.dart',
};

void main() {
  test('соперник 1×1 во всех играх — общая карточка GameOpponentPanel', () {
    _duelSources.forEach((game, path) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('GameOpponentPanel('),
        isTrue,
        reason: '$game: соперника 1×1 рисует GameOpponentPanel ($path)',
      );
    });
  });

  test('каждый экран партии описан в списке игр 1×1', () {
    final screens = Directory('lib/screens')
        .listSync()
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/'))
        .where((p) => p.endsWith('_game_screen.dart'))
        .toList();
    for (final screen in screens) {
      final game = screen.split('/').last.replaceAll('_game_screen.dart', '');
      expect(
        _duelSources.containsKey(game),
        isTrue,
        reason: 'новая игра $game: добавьте её в _duelSources и поставьте '
            'соперника 1×1 через GameOpponentPanel',
      );
    }
  });

  test('игры не собирают карточку соперника сами', () {
    const allowed = <String>{
      // Сам виджет и единственное место, где он создаётся.
      'lib/ui/widgets/game_screen_widgets.dart',
      'lib/games/framework/game_opponent_panel.dart',
    };
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll('\\', '/');
      if (allowed.contains(path)) continue;
      if (file.readAsStringSync().contains('GameOpponentCard(')) {
        offenders.add(path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'GameOpponentCard создаётся только внутри GameOpponentPanel',
    );
  });

  test('у карточки 1×1 нет слота под значки игры', () {
    final card = File('lib/ui/widgets/game_screen_widgets.dart')
        .readAsStringSync();
    final start = card.indexOf('class GameOpponentCard');
    final end = card.indexOf('class GameActionsOverlay');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    expect(card.substring(start, end).contains('trailing'), isFalse);

    final panel = File('lib/games/framework/game_opponent_panel.dart')
        .readAsStringSync();
    final ctor = panel.indexOf('const GameOpponentPanel({');
    final seat = panel.indexOf('const GameOpponentPanel.seat({');
    expect(ctor, greaterThan(0));
    expect(seat, greaterThan(ctor));
    // Значки принимает только место за столом на 3+ игроков.
    expect(panel.substring(ctor, seat).contains('this.seatBadges'), isFalse);
    expect(panel.substring(seat).contains('this.seatBadges'), isTrue);
  });
}
