import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

typedef PushNotificationNavHandler = void Function(String path);

const _pendingCache = 'zozu-push-pending-v1';
const _pendingKey = '/__pending_nav';

JSFunction? _messageListener;
JSFunction? _visibilityListener;
PushNotificationNavHandler? _onNavigate;

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

/// Соответствует tagFromPath / pathFromTag в push-sw.js.
String? _tagFromPath(String path) {
  final p = _normalizeAppPath(path);
  final chat = RegExp(r'^/chats/([^/?#]+)').firstMatch(p);
  if (chat != null) return 'chat_${chat.group(1)}';
  if (p == '/friends' || p.startsWith('/friends?') || p.startsWith('/friends/')) {
    return 'friend_request';
  }
  final lobby =
      RegExp(r'^/games/tictactoe/lobby/([^/?#]+)').firstMatch(p);
  if (lobby != null) return 'game_invite_${lobby.group(1)}';
  final game = RegExp(r'^/games/tictactoe/game/([^/?#]+)').firstMatch(p);
  if (game != null) return 'game_turn_${game.group(1)}';
  if (p == '/coins/login' || p.startsWith('/coins/login?')) {
    return 'daily_reward';
  }
  return null;
}

void _askServiceWorkerClearNotifications({
  String? tag,
  required String path,
}) {
  try {
    final ready = web.window.navigator.serviceWorker.ready;
    ready.toDart.then((reg) {
      final worker = reg.active;
      if (worker == null) return;
      final payload = <String, Object?>{
        'type': 'clear_notifications',
        'path': path,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      };
      worker.postMessage(payload.jsify());
    });
  } catch (_) {}
}

void _go(String raw, {String? tag}) {
  final path = _normalizeAppPath(raw);
  if (path.isEmpty || path == '/') return;
  _onNavigate?.call(path);
  _askServiceWorkerClearNotifications(
    tag: tag ?? _tagFromPath(path),
    path: path,
  );
}

Future<String?> _takePendingPath() async {
  try {
    final cache = await web.window.caches.open(_pendingCache).toDart;
    final response = await cache.match(_pendingKey.toJS).toDart;
    if (response == null) return null;
    await cache.delete(_pendingKey.toJS).toDart;
    final text = (await response.text().toDart).toDart;
    final decoded = jsonDecode(text);
    if (decoded is Map && decoded['path'] is String) {
      return decoded['path'] as String;
    }
  } catch (_) {}
  return null;
}

Future<void> _consumePendingIfAny() async {
  final path = await _takePendingPath();
  if (path != null) _go(path);
}

/// Слушает postMessage от push-sw.js и pending deep-link в Cache.
void installPushNotificationNavigation(PushNotificationNavHandler onNavigate) {
  if (!kIsWeb) return;
  uninstallPushNotificationNavigation();
  _onNavigate = onNavigate;

  void handleMessage(web.Event event) {
    try {
      final message = event as web.MessageEvent;
      final data = message.data;
      if (data == null) return;
      final obj = data as JSObject;
      final type = obj.getProperty('type'.toJS).dartify();
      final url = obj.getProperty('url'.toJS).dartify();
      if (type is! String || url is! String) return;
      if (type != 'notification_click') return;
      final tagRaw = obj.getProperty('tag'.toJS).dartify();
      final tag = tagRaw is String && tagRaw.isNotEmpty ? tagRaw : null;
      _go(url, tag: tag);
    } catch (_) {}
  }

  void handleVisibility(web.Event _) {
    if (web.document.visibilityState == 'visible') {
      _consumePendingIfAny();
    }
  }

  _messageListener = handleMessage.toJS;
  _visibilityListener = handleVisibility.toJS;
  web.window.navigator.serviceWorker
      .addEventListener('message', _messageListener!);
  web.document.addEventListener('visibilitychange', _visibilityListener!);
  web.window.addEventListener('focus', _visibilityListener!);

  // Подтянуть новый push-sw (tag/cache deep-link) без переустановки PWA.
  try {
    web.window.navigator.serviceWorker.getRegistration().toDart.then((reg) {
      reg?.update();
    });
  } catch (_) {}

  // Холодный старт / уже открытое приложение после клика по пушу.
  _consumePendingIfAny();
}

void uninstallPushNotificationNavigation() {
  if (!kIsWeb) return;
  try {
    if (_messageListener != null) {
      web.window.navigator.serviceWorker
          .removeEventListener('message', _messageListener!);
    }
  } catch (_) {}
  try {
    if (_visibilityListener != null) {
      web.document
          .removeEventListener('visibilitychange', _visibilityListener!);
      web.window.removeEventListener('focus', _visibilityListener!);
    }
  } catch (_) {}
  _messageListener = null;
  _visibilityListener = null;
  _onNavigate = null;
}
