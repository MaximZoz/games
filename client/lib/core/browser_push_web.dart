import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

const _swUrl = '/push-sw.js';

/// Поддержка Web Push в текущем браузере.
bool browserPushSupported() {
  if (!kIsWeb) return false;
  try {
    final _ = web.Notification.permission;
    // Наличие navigator.serviceWorker — базовый критерий.
    web.window.navigator.serviceWorker;
    return true;
  } catch (_) {
    return false;
  }
}

String browserNotificationPermission() {
  try {
    return web.Notification.permission;
  } catch (_) {
    return 'denied';
  }
}

Future<String> requestBrowserNotificationPermission() async {
  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

Future<web.ServiceWorkerRegistration> _ensurePushServiceWorker() {
  return web.window.navigator.serviceWorker.register(_swUrl.toJS).toDart;
}

Uint8List _urlBase64ToUint8List(String base64String) {
  final padding = '=' * ((4 - base64String.length % 4) % 4);
  final normalized =
      (base64String + padding).replaceAll('-', '+').replaceAll('_', '/');
  return Uint8List.fromList(base64Decode(normalized));
}

String _bufferToBase64Url(JSArrayBuffer buffer) {
  final bytes = buffer.toDart.asUint8List();
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Результат подписки для отправки на сервер.
class BrowserPushSubscriptionData {
  const BrowserPushSubscriptionData({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;
  final String p256dh;
  final String auth;
}

Future<web.PushSubscription> _getOrCreateSubscription({
  required web.PushManager pushManager,
  required Uint8List applicationServerKey,
}) async {
  final existing = await pushManager.getSubscription().toDart;
  if (existing != null) return existing;

  return pushManager
      .subscribe(
        web.PushSubscriptionOptionsInit(
          userVisibleOnly: true,
          applicationServerKey: applicationServerKey.toJS,
        ),
      )
      .toDart;
}

/// Подписывается на Web Push с [vapidPublicKey] (URL-safe base64).
Future<BrowserPushSubscriptionData> subscribeBrowserPush({
  required String vapidPublicKey,
}) async {
  final permission = browserNotificationPermission();
  if (permission != 'granted') {
    throw StateError('Нет разрешения на уведомления');
  }

  final registration = await _ensurePushServiceWorker();
  await web.window.navigator.serviceWorker.ready.toDart;

  final applicationServerKey = _urlBase64ToUint8List(vapidPublicKey);
  final subscription = await _getOrCreateSubscription(
    pushManager: registration.pushManager,
    applicationServerKey: applicationServerKey,
  );

  final keyP256 = subscription.getKey('p256dh');
  final keyAuth = subscription.getKey('auth');
  if (keyP256 == null || keyAuth == null) {
    throw StateError('Неполная push-подписка');
  }
  final endpoint = subscription.endpoint;
  if (endpoint.isEmpty) {
    throw StateError('Пустой endpoint подписки');
  }
  return BrowserPushSubscriptionData(
    endpoint: endpoint,
    p256dh: _bufferToBase64Url(keyP256),
    auth: _bufferToBase64Url(keyAuth),
  );
}

Future<String?> currentBrowserPushEndpoint() async {
  try {
    final registration = await _ensurePushServiceWorker();
    final sub = await registration.pushManager.getSubscription().toDart;
    return sub?.endpoint;
  } catch (_) {
    return null;
  }
}

Future<void> unsubscribeBrowserPush() async {
  try {
    final registration = await _ensurePushServiceWorker();
    final sub = await registration.pushManager.getSubscription().toDart;
    if (sub == null) return;
    await sub.unsubscribe().toDart;
  } catch (_) {}
}
