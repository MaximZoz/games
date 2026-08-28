Future<void> initLocalNotifications() async {}

Future<bool> requestLocalNotificationPermission() async => false;

bool localNotificationsSupported() => false;

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {}

void setLocalNotifySessionActive(bool active) {}

Future<void> cancelAllLocalNotifications() async {}
