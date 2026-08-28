import 'local_notify_stub.dart'
    if (dart.library.io) 'local_notify_io.dart' as impl;

Future<void> initLocalNotifications() => impl.initLocalNotifications();

Future<bool> requestLocalNotificationPermission() =>
    impl.requestLocalNotificationPermission();

bool localNotificationsSupported() => impl.localNotificationsSupported();

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) =>
    impl.showLocalNotification(title: title, body: body, payload: payload);

void setLocalNotifySessionActive(bool active) =>
    impl.setLocalNotifySessionActive(active);

Future<void> cancelAllLocalNotifications() =>
    impl.cancelAllLocalNotifications();
