import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

typedef PushNotificationNavHandler = void Function(String path);

JSFunction? _messageListener;

String _normalizeAppPath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '/';
  if (trimmed.startsWith('/')) return trimmed;
  try {
    final uri = Uri.parse(trimmed);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      final path = uri.path.isEmpty ? '/' : uri.path;
      final q = uri.hasQuery ? '?${uri.query}' : '';
      final f = uri.hasFragment ? '#${uri.fragment}' : '';
      return '$path$q$f';
    }
  } catch (_) {}
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

/// Слушает postMessage от push-sw.js и ведёт в нужный экран без reload.
void installPushNotificationNavigation(PushNotificationNavHandler onNavigate) {
  if (!kIsWeb) return;
  uninstallPushNotificationNavigation();

  void handle(web.Event event) {
    try {
      final message = event as web.MessageEvent;
      final data = message.data;
      if (data == null) return;
      final obj = data as JSObject;
      final type = obj.getProperty('type'.toJS).dartify();
      final url = obj.getProperty('url'.toJS).dartify();
      if (type is! String || url is! String) return;
      if (type != 'notification_click') return;
      onNavigate(_normalizeAppPath(url));
    } catch (_) {}
  }

  _messageListener = handle.toJS;
  web.window.navigator.serviceWorker
      .addEventListener('message', _messageListener!);
}

void uninstallPushNotificationNavigation() {
  if (!kIsWeb || _messageListener == null) return;
  try {
    web.window.navigator.serviceWorker
        .removeEventListener('message', _messageListener!);
  } catch (_) {}
  _messageListener = null;
}
