import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

const _popupName = 'mg_oauth';
const _pendingKey = 'mg_oauth_pending_state';

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
    if (v != null && !v.isUndefined && !v.isNull && v.isA<JSBoolean>()) {
      return (v as JSBoolean).toDart;
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

/// iOS PWA: без target=_blank — иначе SFSafariViewController / in-app browser,
/// где Google показывает белый экран. Cross-origin <a> отдаётся в Safari.
void openOAuthExternal(String url) {
  if (isIosStandalonePwa) {
    try {
      final a = web.document.createElement('a') as web.HTMLAnchorElement;
      a.href = url;
      web.document.body?.appendChild(a);
      a.click();
      a.remove();
      return;
    } catch (_) {}
    try {
      web.window.location.assign(url);
    } catch (_) {}
    return;
  }
  try {
    final a = web.document.createElement('a') as web.HTMLAnchorElement;
    a.href = url;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    web.document.body?.appendChild(a);
    a.click();
    a.remove();
    return;
  } catch (_) {}
  try {
    web.window.open(url, '_blank');
    return;
  } catch (_) {}
  web.window.location.assign(url);
}

/// Синхронный XHR в обработчике тапа — сохраняет user activation для открытия Safari.
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
}

String? readOAuthPendingState() {
  try {
    final v = web.window.sessionStorage.getItem(_pendingKey);
    if (v == null || v.isEmpty) return null;
    return v;
  } catch (_) {
    return null;
  }
}

void clearOAuthPendingState() {
  try {
    web.window.sessionStorage.removeItem(_pendingKey);
  } catch (_) {}
}
