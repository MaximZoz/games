import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

var _initialized = false;

bool fcmSupported() => Platform.isAndroid;

Future<bool> _ensureFirebase() async {
  if (!Platform.isAndroid) return false;
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
  if (!Platform.isAndroid) return const Stream.empty();
  return FirebaseMessaging.instance.onTokenRefresh;
}

Future<void> deleteFcmToken() async {
  if (!await _ensureFirebase()) return;
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}
}
