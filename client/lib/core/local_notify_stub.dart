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

Future<void> syncIosNotificationCenter({
  required int badge,
  bool applyBadge = false,
  bool clearChatThreads = false,
  List<String> keepChatTags = const [],
  List<String> dropChatTags = const [],
  bool clearFriendRequests = false,
  bool clearGameInvites = false,
  List<String> keepInviteTags = const [],
  bool clearAll = false,
}) async {}

void setLocalNotificationTapHandler(void Function(String payload)? handler) {}

Future<String?> consumeLocalNotificationLaunchPayload() async => null;
