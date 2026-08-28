import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
var _ready = false;

Future<void> initLocalNotifications() async {
  if (_ready) return;
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
}

Future<bool> requestLocalNotificationPermission() async {
  await initLocalNotifications();
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final granted = await android?.requestNotificationsPermission();
  return granted ?? true;
}

bool localNotificationsSupported() => true;

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  if (!_ready) await initLocalNotifications();
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
  await _plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    title,
    body,
    details,
    payload: payload,
  );
}
