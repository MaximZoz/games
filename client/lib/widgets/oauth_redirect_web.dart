import 'dart:async';
import 'dart:convert';

import 'package:web/web.dart' as web;

const _storageKey = 'mg_oauth_result';
const _popupName = 'mg_oauth';

/// Открывает OAuth в popup, чтобы PWA не уходила в Safari.
/// Возвращает query-параметры колбэка или `null` при полном редиректе / отмене.
Future<Map<String, String>?> openOAuthUrl(String url) async {
  try {
    web.window.localStorage.removeItem(_storageKey);
  } catch (_) {}

  final popup = web.window.open(url, _popupName, 'popup=yes,width=480,height=720');
  if (popup == null) {
    // Блокер popup — полный переход (в браузере ок, в PWA хуже).
    web.window.location.assign(url);
    return null;
  }

  final completer = Completer<Map<String, String>?>();

  void finish(Map<String, String>? data) {
    if (completer.isCompleted) return;
    try {
      web.window.localStorage.removeItem(_storageKey);
    } catch (_) {}
    try {
      popup.close();
    } catch (_) {}
    completer.complete(data);
  }

  final timer = Timer.periodic(const Duration(milliseconds: 250), (t) {
    try {
      final raw = web.window.localStorage.getItem(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        t.cancel();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          finish(decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')));
        } else {
          finish(null);
        }
        return;
      }
    } catch (_) {}
    try {
      if (popup.closed) {
        t.cancel();
        finish(null);
      }
    } catch (_) {}
  });

  return completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () {
      timer.cancel();
      return null;
    },
  );
}

/// На странице колбэка / в popup: записать результат для opener и закрыть.
bool completeOAuthPopup(Map<String, String> params) {
  var isPopup = false;
  try {
    isPopup = web.window.opener != null || web.window.name == _popupName;
  } catch (_) {
    try {
      isPopup = web.window.name == _popupName;
    } catch (_) {}
  }
  if (!isPopup) return false;
  try {
    web.window.localStorage.setItem(_storageKey, jsonEncode(params));
  } catch (_) {}
  try {
    web.window.close();
  } catch (_) {}
  return true;
}
