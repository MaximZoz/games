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
        'Color(0xFF010203)',
      ],
    );
    final button = findUiLibraryHits('''
      ElevatedButton(onPressed: () {}, child: const Text('x'));
      TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('y'));
      const AppButton(onPressed: null, label: 'z');
      TextButton(onPressed: () {}, child: const Text('ok')); // ui-library-allow
    ''');
    expect(button.map((hit) => hit.token).toList(), [
      'ElevatedButton',
      'TextButton.icon',
    ]);
  });

  test('новое вхождение печатается как warning сборки', () {
    final report = diffHits(
      [
        const UiLibraryHit(
          path: 'lib/a.dart',
          line: 4,
          column: 3,
          offset: 10,
          length: 10,
          token: 'Colors.red',
        ),
      ],
      const {},
    );
    expect(report.isClean, isFalse);
    expect(
      report.format(),
      contains(
        'warning • Цвет Colors.red вне UI-библиотеки. Возьми AppColors или GamePalette. • lib/a.dart:4:3 • use_ui_library',
      ),
    );
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
