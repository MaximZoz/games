import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Жёсткая перезагрузка: сбросить SW/кэш и открыть страницу заново.
/// Иначе Flutter/браузер может снова отдать старый билд.
Future<void> reloadApp() async {
  try {
    final regs =
        await web.window.navigator.serviceWorker.getRegistrations().toDart;
    for (final reg in regs.toDart) {
      try {
        await reg.unregister().toDart;
      } catch (_) {}
    }
  } catch (_) {}

  try {
    final keys = await web.window.caches.keys().toDart;
    for (final key in keys.toDart) {
      try {
        await web.window.caches.delete(key.toDart).toDart;
      } catch (_) {}
    }
  } catch (_) {}

  final href = web.window.location.href;
  final uri = Uri.parse(href);
  final q = Map<String, String>.from(uri.queryParameters);
  q['_reload'] = DateTime.now().millisecondsSinceEpoch.toString();
  final next = uri.replace(queryParameters: q).toString();
  web.window.location.assign(next);
}
