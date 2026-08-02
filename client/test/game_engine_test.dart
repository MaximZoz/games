import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/game_engine/game_engine.dart';

void main() {
  group('game engine config', () {
    test('variants mirror server configs', () {
      expect(configForVariant(variantClassic).gridSize, 3);
      expect(configForVariant(variantClassic).winLength, 3);
      expect(configForVariant(variantGomoku).gridSize, 15);
      expect(configForVariant(variantGomoku).winLength, 5);
      expect(configForVariant(variantUltimate).cellCount, 81);
      expect(configForVariant(variantMulti3).marks, ['x', 'o', 't']);
      expect(configForVariant(variantMulti4).marks, ['x', 'o', 't', 's']);
    });
  });

  group('line engine', () {
    test('multi3 rotates three marks and wins on four', () {
      final engine = newEngine(variantMulti3);
      var state = engine.newState();
      for (final cell in [0, 10, 20, 1, 11, 21, 2, 12, 22, 3]) {
        state = engine.applyMove(state, cell).state;
      }
      expect(state.status, 'won');
      expect(state.winner, 'x');
    });
  });

  group('ultimate engine', () {
    test('forces next sub-board after a move', () {
      final engine = newEngine(variantUltimate);
      final result = engine.applyMove(engine.newState(), 4);
      expect(result.state.nextBoard, 4);
      expect(engine.legalCells(result.state), List.generate(9, (i) => 36 + i));
    });
  });
}
