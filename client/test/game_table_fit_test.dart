import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/ui/game_table_fit.dart';

void main() {
  group('gameTableFit', () {
    test('высоты хватает — полный размер', () {
      final fit = gameTableFit(availableHeight: 700, designHeight: 545);
      expect(fit.scale, 1);
      expect(fit.compact, isFalse);
      expect(fit.scaled(const Size(92, 132)), const Size(92, 132));
    });

    test('альбом телефона — стол ужимается', () {
      final fit = gameTableFit(availableHeight: 330, designHeight: 545);
      expect(fit.compact, isTrue);
      expect(fit.scale, closeTo(330 / 545, 0.001));
      final card = fit.scaled(const Size(92, 132));
      expect(card.height, lessThan(132));
      expect(card.width / card.height, closeTo(92 / 132, 0.001));
    });

    test('ниже minScale не опускаемся', () {
      final fit = gameTableFit(
        availableHeight: 100,
        designHeight: 545,
        minScale: 0.52,
      );
      expect(fit.scale, 0.52);
      expect(fit.compact, isTrue);
    });

    test('нулевая высота не ломает расчёт', () {
      final fit = gameTableFit(availableHeight: 0, designHeight: 545);
      expect(fit.scale, 1);
      expect(fit.compact, isFalse);
    });
  });

  group('isActiveGamePath', () {
    test('партия и офлайн — да, лобби и список — нет', () {
      expect(gameRegistry.isActiveGamePath('/games/durak/game/abc'), isTrue);
      expect(gameRegistry.isActiveGamePath('/games/poker/offline'), isTrue);
      expect(
        gameRegistry.isActiveGamePath('/games/battleship/lobby/abc'),
        isFalse,
      );
      expect(gameRegistry.isActiveGamePath('/games'), isFalse);
      expect(gameRegistry.isActiveGamePath('/profile'), isFalse);
    });
  });
}
