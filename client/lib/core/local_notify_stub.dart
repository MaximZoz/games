Future<void> initLocalNotifications() async {}

Future<bool> requestLocalNotificationPermission() async => false;

bool localNotificationsSupported() => false;

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
  String? tag,
  int? id,
}) async {}

void setLocalNotifySessionActive(bool active) {}

Future<void> cancelAllLocalNotifications() async {}

Future<void> cancelLocalNotificationsForTag(String tag) async {}

Future<void> cancelLocalNotificationsForPath(String path, {String? tag}) async {}

void setLocalNotificationTapHandler(void Function(String payload)? handler) {}

Future<String?> consumeLocalNotificationLaunchPayload() async => null;
