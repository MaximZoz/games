@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// В вебе (dart2js) `-1 << 30` — это +3221225472: бот домино с такой
/// «минус бесконечностью» не выбирает ход, а кладёт первую законную кость и
/// никогда не играет два дубля. Сам перебор сверяется с сервером в
/// `domino_engine_test.dart` (его же можно прогнать с `--platform chrome`).
void main() {
  test('бот домино не считает границы перебора сдвигом', () {
    final source = File('lib/games/domino/domino_bot.dart').readAsStringSync();
    final code = source
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    expect(code.contains('<<'), isFalse, reason: 'сдвиг в коде бота домино');
  });
}
