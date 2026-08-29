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
  String? tag,
  int? id,
}) =>
    impl.showLocalNotification(
      title: title,
      body: body,
      payload: payload,
      tag: tag,
      id: id,
    );

void setLocalNotifySessionActive(bool active) =>
    impl.setLocalNotifySessionActive(active);

Future<void> cancelAllLocalNotifications() =>
    impl.cancelAllLocalNotifications();

Future<void> cancelLocalNotificationsForTag(String tag) =>
    impl.cancelLocalNotificationsForTag(tag);

Future<void> cancelLocalNotificationsForPath(String path, {String? tag}) =>
    impl.cancelLocalNotificationsForPath(path, tag: tag);

void setLocalNotificationTapHandler(void Function(String payload)? handler) =>
    impl.setLocalNotificationTapHandler(handler);

Future<String?> consumeLocalNotificationLaunchPayload() =>
    impl.consumeLocalNotificationLaunchPayload();
