import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

const _popupName = 'mg_oauth';
const _pendingKey = 'mg_oauth_pending_state';

bool get isStandalonePwa => _isStandalone();

bool get isIosStandalonePwa {
  if (!_isStandalone()) return false;
  return _isIos();
}

bool _isStandalone() {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
  } catch (_) {}
  try {
    if (web.window.matchMedia('(display-mode: fullscreen)').matches) {
      return true;
    }
  } catch (_) {}
  try {
    final nav = web.window.navigator as JSObject;
    final v = nav.getProperty('standalone'.toJS);
    // iOS Safari: navigator.standalone === true в установленной PWA.
    if (v != null && !v.isUndefined && !v.isNull) {
      return v.dartify() == true;
    }
  } catch (_) {}
  return false;
}

bool _isIos() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod') ||
        (ua.contains('mac') && ua.contains('mobile'));
  } catch (_) {
    return false;
  }
}

class _OAuthWindowHandle {
  _OAuthWindowHandle(this.window);
  final web.Window? window;
}

Object? openOAuthWindowBlank() {
  if (isIosStandalonePwa) return null;
  final win =
      web.window.open('about:blank', _popupName, 'popup=yes,width=480,height=720');
  if (win == null) return null;
  return _OAuthWindowHandle(win);
}

void navigateOAuthWindow(Object? handle, String url) {
  if (handle is _OAuthWindowHandle && handle.window != null) {
    try {
      handle.window!.location.href = url;
      return;
    } catch (_) {}
  }
  openOAuthExternal(url);
}

void closeOAuthWindow(Object? handle) {
  if (handle is _OAuthWindowHandle) {
    try {
      handle.window?.close();
    } catch (_) {}
  }
}

/// Top-level навигация (без target=_blank) — в PWA остаётся Safari UA.
void openOAuthExternal(String url) {
  try {
    web.window.location.assign(url);
  } catch (_) {
    try {
      final a = web.document.createElement('a') as web.HTMLAnchorElement;
      a.href = url;
      web.document.body?.appendChild(a);
      a.click();
      a.remove();
    } catch (_) {}
  }
}

({String authorizeUrl, String state})? fetchOAuthPollStartSync(String url) {
  try {
    final xhr = web.XMLHttpRequest();
    xhr.open('GET', url, false);
    xhr.send();
    if (xhr.status != 200) return null;
    final body = jsonDecode(xhr.responseText);
    if (body is! Map) return null;
    final authUrl = (body['authorize_url'] ?? '').toString();
    final state = (body['state'] ?? '').toString();
    if (authUrl.isEmpty || state.isEmpty) return null;
    return (authorizeUrl: authUrl, state: state);
  } catch (_) {
    return null;
  }
}

void saveOAuthPendingState(String state) {
  try {
    web.window.sessionStorage.setItem(_pendingKey, state);
  } catch (_) {}
  // localStorage переживает убийство PWA на iOS, sessionStorage — нет.
  try {
    web.window.localStorage.setItem(_pendingKey, state);
  } catch (_) {}
}

String? readOAuthPendingState() {
  try {
    final session = web.window.sessionStorage.getItem(_pendingKey);
    if (session != null && session.isNotEmpty) return session;
  } catch (_) {}
  try {
    final local = web.window.localStorage.getItem(_pendingKey);
    if (local != null && local.isNotEmpty) return local;
  } catch (_) {}
  return null;
}

void clearOAuthPendingState() {
  try {
    web.window.sessionStorage.removeItem(_pendingKey);
  } catch (_) {}
  try {
    web.window.localStorage.removeItem(_pendingKey);
  } catch (_) {}
}

Future<void> hydrateOAuthPendingState() async {
  // sessionStorage уже синхронный через readOAuthPendingState.
}
