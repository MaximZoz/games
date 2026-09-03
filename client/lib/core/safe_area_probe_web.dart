import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

double _px(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  return double.tryParse(trimmed.replaceAll('px', '')) ?? 0;
}

/// Безопасные зоны из CSS `env(safe-area-inset-*)`.
///
/// Движок Flutter web их не читает — на iPhone `MediaQuery.padding` всегда
/// нулевой, и содержимое уезжает под чёлку и home indicator. Значения
/// снимаем с элемента-щупа из `index.html`.
EdgeInsets? readCssSafeAreaInsets() {
  try {
    final probe = web.document.getElementById('safe-area-probe');
    if (probe == null) return null;
    final style = web.window.getComputedStyle(probe);
    return EdgeInsets.only(
      top: _px(style.getPropertyValue('padding-top')),
      right: _px(style.getPropertyValue('padding-right')),
      bottom: _px(style.getPropertyValue('padding-bottom')),
      left: _px(style.getPropertyValue('padding-left')),
    );
  } catch (_) {
    return null;
  }
}
