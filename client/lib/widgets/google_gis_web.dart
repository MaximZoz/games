import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Google Identity Services: credential JWT без redirect/Safari.
/// Вызывает window.__mgGoogleSignIn(clientId) из index.html.
Future<String?> requestGoogleIdToken(String clientId) async {
  final id = clientId.trim();
  if (id.isEmpty) return null;
  try {
    final fn = web.window.getProperty('__mgGoogleSignIn'.toJS);
    if (fn == null || fn.isUndefined || fn.isNull) {
      return null;
    }
    final promise = (fn as JSFunction).callAsFunction(null, id.toJS);
    if (promise == null) return null;
    final result = await (promise as JSPromise).toDart;
    if (result == null || result.isUndefined || result.isNull) return null;
    final s = result.dartify();
    if (s is String && s.isNotEmpty) return s;
    return null;
  } catch (_) {
    return null;
  }
}
