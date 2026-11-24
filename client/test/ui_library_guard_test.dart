import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/ui_library_guard.dart';

void main() {
  test('литерал цвета вне палитры находится, комментарий и строка — нет', () {
    final hits = findUiLibraryHits('''
      const a = Colors.red;
      const b = Colors.transparent;
      const c = AppColors.danger;
      // Colors.blue
      /* Color(0xFF111111) */
      const d = Color(0xFFaaBBcc);
      const e = Color(0xFF00FF00); // ui-library-allow
      final f = 'Colors.white';
      final g = Color.fromRGBO(1, 2, 3, 1);
      const h = Color(
        0xFF010203,
      );
    ''');
    expect(
      hits.map((hit) => hit.token).toList(),
      [
        'Colors.red',
        'Color(0xFFAABBCC)',
        'Color.fromRGBO',
        'Color(0xFF010203)'
      ],
    );
  });

  test('новое вхождение не сходится с базой', () {
    final report = diffHits(
      [const UiLibraryHit(path: 'lib/a.dart', line: 4, token: 'Colors.red')],
      const {},
    );
    expect(report.isClean, isFalse);
    expect(report.format(), contains('lib/a.dart:4 Colors.red'));
    expect(report.format(), contains('AppColors'));
  });

  test('client/lib совпадает с базой цветов', () {
    final root = findClientRoot();
    final hits = scanClientLib(root);
    final baseline = loadBaseline(File('${root.path}/$baselineName'));
    final total = baseline.values.fold<int>(0, (sum, count) => sum + count);
    expect(total, greaterThan(50));
    final report = diffHits(hits, baseline);
    expect(report.isClean, isTrue, reason: report.format());
  });
}
