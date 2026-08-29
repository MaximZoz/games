import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:multigames_client/core/fcm_types.dart';

var _initialized = false;

bool _inFlutterTest() => Platform.environment.containsKey('FLUTTER_TEST');

bool fcmSupported() => Platform.isAndroid && !_inFlutterTest();

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
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    return null;
  }
  return messaging.getToken();
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
