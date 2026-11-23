import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Масти — правило игры, а не оформление стола: красная и чёрная масть
/// колоды, четыре цвета Уно.
const _suitFiles = <String>{
  'lib/ui/durak/playing_card_widget.dart',
  'lib/ui/uno/uno_card_widget.dart',
};

/// Сводка личных встреч в профиле — не игровой стол.
const _notTables = <String>{
  'lib/games/head_to_head_section.dart',
};

Iterable<File> _gameSources() sync* {
  for (final dir in const ['lib/games', 'lib/ui/uno', 'lib/ui/durak']) {
    yield* Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
  }
  yield* Directory('lib/screens')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_game_screen.dart'));
}

void main() {
  test('столы игр берут цвета из GamePalette, а не из своих литералов', () {
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)');
    final named = RegExp(
      r'Colors\.(red|pink|purple|deepPurple|indigo|blue|lightBlue|cyan|teal|'
      r'green|lightGreen|lime|yellow|amber|orange|deepOrange|brown|grey|'
      r'blueGrey)\w*',
    );
    final offenders = <String>[];
    var scanned = 0;
    for (final file in _gameSources()) {
      final path = file.path.replaceAll(r'\', '/');
      if (_suitFiles.contains(path) || _notTables.contains(path)) continue;
      scanned++;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (hex.hasMatch(line) || named.hasMatch(line)) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }
    // Все девять экранов партий и их доски действительно просмотрены.
    expect(scanned, greaterThan(40));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
