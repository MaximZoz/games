import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
var _ready = false;
var _sessionActive = false;

bool _inFlutterTest() => Platform.environment.containsKey('FLUTTER_TEST');

/// Только настоящий Android. VM-тесты и desktop плагин не регистрируют.
bool localNotificationsSupported() =>
    Platform.isAndroid && !_inFlutterTest();

Future<void> initLocalNotifications() async {
  if (_ready || !localNotificationsSupported()) return;
  try {
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    const channel = AndroidNotificationChannel(
      'zozu_events',
      'Zozu Games',
      description: 'Чаты, друзья, игры и награды',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _ready = true;
  } catch (_) {
    // Нет platform instance (тесты / не-Android) — локальные баннеры пропускаем.
  }
}

Future<bool> requestLocalNotificationPermission() async {
  if (!localNotificationsSupported()) return false;
  await initLocalNotifications();
  if (!_ready) return false;
  try {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  } catch (_) {
    return false;
  }
}

void setLocalNotifySessionActive(bool active) {
  _sessionActive = active;
}

Future<void> cancelAllLocalNotifications() async {
  if (!localNotificationsSupported()) return;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return;
  try {
    await _plugin.cancelAll();
  } catch (_) {}
}

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  if (!_sessionActive || !localNotificationsSupported()) return;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return;
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'zozu_events',
      'Zozu Games',
      channelDescription: 'Чаты, друзья, игры и награды',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notify',
    ),
  );
  try {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
      payload: payload,
    );
  } catch (_) {}
}
