import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:multigames_client/core/device_push_platform.dart';
import 'package:multigames_client/core/fcm_types.dart';

const _pushChannel = MethodChannel('com.zozugames/push');

var _initialized = false;

bool _inFlutterTest() => Platform.environment.containsKey('FLUTTER_TEST');

bool fcmSupported() =>
    (Platform.isAndroid || Platform.isIOS) && !_inFlutterTest();

String devicePushPlatform() =>
    devicePushPlatformName(Platform.operatingSystem);

Future<bool> _ensureFirebase() async {
  if (!fcmSupported()) return false;
  if (_initialized) return Firebase.apps.isNotEmpty;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _initialized = true;
    return true;
  } catch (_) {
    _initialized = true;
    return Firebase.apps.isNotEmpty;
  }
}

FcmPushMessage _wrap(RemoteMessage message) {
  final data = <String, String>{};
  message.data.forEach((key, value) {
    data[key] = value.toString();
  });
  final title = message.notification?.title;
  final body = message.notification?.body;
  if (title != null && title.isNotEmpty) {
    data.putIfAbsent('title', () => title);
  }
  if (body != null && body.isNotEmpty) {
    data.putIfAbsent('body', () => body);
  }
  return FcmPushMessage(data);
}

Future<String?> ensureFcmToken() async {
  if (!await _ensureFirebase()) return null;
  if (Platform.isIOS) {
    // Storyboard-engine не видит APNs-токен, который пришёл в AppDelegate.
    try {
      await _pushChannel.invokeMethod<void>('firebaseReady');
    } catch (_) {}
  }
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    return null;
  }
  // Пока приложение открыто, баннер рисует локальное уведомление из сокета.
  // Системный баннер FCM нужен в фоне и когда процесс убит — как на Android.
  await messaging.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );
  return messaging.getToken();
}

Map<String, String>? _stringMap(dynamic raw) {
  if (raw is! Map) return null;
  final out = <String, String>{};
  raw.forEach((key, value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) out[key.toString()] = text;
  });
  if (out.isEmpty) return null;
  return out;
}

Future<Map<String, String>?> takeIosNotificationTap() async {
  if (!Platform.isIOS || !fcmSupported()) return null;
  try {
    final raw = await _pushChannel.invokeMethod<dynamic>('takeTap');
    return _stringMap(raw);
  } catch (_) {
    return null;
  }
}

/// Пока приложение уже запущено, тап приходит сюда.
/// Аргументы метода, не обратный вызов в тот же канал: иначе взаимная блокировка.
void listenIosNotificationTaps(void Function(Map<String, String> data) onTap) {
  if (!Platform.isIOS || !fcmSupported()) return;
  _pushChannel.setMethodCallHandler((call) async {
    if (call.method != 'notificationTap') return;
    final data = _stringMap(call.arguments);
    if (data != null) onTap(data);
  });
}

Stream<String> fcmTokenRefresh() {
  if (!fcmSupported()) return const Stream.empty();
  return FirebaseMessaging.instance.onTokenRefresh;
}

Future<void> deleteFcmToken() async {
  if (!await _ensureFirebase()) return;
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}
}

Future<FcmPushMessage?> getInitialFcmMessage() async {
  if (!await _ensureFirebase()) return null;
  try {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return null;
    return _wrap(message);
  } catch (_) {
    return null;
  }
}

Stream<FcmPushMessage> fcmOpenedAppMessages() {
  if (!fcmSupported()) return const Stream.empty();
  return FirebaseMessaging.onMessageOpenedApp.map(_wrap);
}

Stream<FcmPushMessage> fcmForegroundMessages() {
  if (!fcmSupported()) return const Stream.empty();
  return FirebaseMessaging.onMessage.map(_wrap);
}
