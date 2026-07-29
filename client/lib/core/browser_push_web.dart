// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

const _swUrl = '/push-sw.js';

/// Поддержка Web Push в текущем браузере.
bool browserPushSupported() {
  if (!kIsWeb) return false;
  final n = html.window.navigator;
  return html.Notification.supported &&
      n.serviceWorker != null &&
      js_util.hasProperty(n, 'PushManager');
}

String browserNotificationPermission() {
  if (!html.Notification.supported) return 'denied';
  return html.Notification.permission ?? 'default';
}

Future<String> requestBrowserNotificationPermission() async {
  if (!html.Notification.supported) return 'denied';
  final result = await html.Notification.requestPermission();
  return result;
}

Future<html.ServiceWorkerRegistration> _ensurePushServiceWorker() async {
  final container = html.window.navigator.serviceWorker;
  if (container == null) {
    throw StateError('ServiceWorker недоступен');
  }
  return container.register(_swUrl);
}

Uint8List _urlBase64ToUint8List(String base64String) {
  final padding = '=' * ((4 - base64String.length % 4) % 4);
  final normalized =
      (base64String + padding).replaceAll('-', '+').replaceAll('_', '/');
  return Uint8List.fromList(base64Decode(normalized));
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

Future<html.PushSubscription> _subscribeWithKey(
  html.PushManager pushManager,
  Uint8List applicationServerKey,
) async {
  // dart:html типы PushManager неточны — работаем через JS interop.
  final existing = await js_util.promiseToFuture<html.PushSubscription?>(
    js_util.callMethod(pushManager, 'getSubscription', const []),
  );
  if (existing != null) return existing;
  final opts = js_util.jsify({
    'userVisibleOnly': true,
    'applicationServerKey': applicationServerKey,
  });
  return js_util.promiseToFuture<html.PushSubscription>(
    js_util.callMethod(pushManager, 'subscribe', [opts]),
  );
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
  await html.window.navigator.serviceWorker!.ready;

  final applicationServerKey = _urlBase64ToUint8List(vapidPublicKey);
  final pushManager = registration.pushManager;
  if (pushManager == null) {
    throw StateError('PushManager недоступен');
  }

  final subscription =
      await _subscribeWithKey(pushManager, applicationServerKey);

  final keyP256 = subscription.getKey('p256dh');
  final keyAuth = subscription.getKey('auth');
  if (keyP256 == null || keyAuth == null) {
    throw StateError('Неполная push-подписка');
  }
  final endpoint = subscription.endpoint;
  if (endpoint == null || endpoint.isEmpty) {
    throw StateError('Пустой endpoint подписки');
  }
  return BrowserPushSubscriptionData(
    endpoint: endpoint,
    p256dh: base64UrlEncode(Uint8List.view(keyP256)).replaceAll('=', ''),
    auth: base64UrlEncode(Uint8List.view(keyAuth)).replaceAll('=', ''),
  );
}

Future<String?> currentBrowserPushEndpoint() async {
  final container = html.window.navigator.serviceWorker;
  if (container == null) return null;
  final registration = await container.getRegistration(_swUrl);
  final pushManager = registration.pushManager;
  if (pushManager == null) return null;
  final sub = await js_util.promiseToFuture<html.PushSubscription?>(
    js_util.callMethod(pushManager, 'getSubscription', const []),
  );
  return sub?.endpoint;
}

Future<void> unsubscribeBrowserPush() async {
  final container = html.window.navigator.serviceWorker;
  if (container == null) return;
  final registration = await container.getRegistration(_swUrl);
  final pushManager = registration.pushManager;
  if (pushManager == null) return;
  final sub = await js_util.promiseToFuture<html.PushSubscription?>(
    js_util.callMethod(pushManager, 'getSubscription', const []),
  );
  if (sub == null) return;
  await js_util.promiseToFuture(
    js_util.callMethod(sub, 'unsubscribe', const []),
  );
}
