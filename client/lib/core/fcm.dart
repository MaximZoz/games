import 'fcm_stub.dart' if (dart.library.io) 'fcm_io.dart' as impl;
import 'fcm_types.dart';

export 'fcm_types.dart';

bool fcmSupported() => impl.fcmSupported();

String devicePushPlatform() => impl.devicePushPlatform();

Future<String?> ensureFcmToken() => impl.ensureFcmToken();

Future<Map<String, String>?> takeIosNotificationTap() =>
    impl.takeIosNotificationTap();

void listenIosNotificationTaps(void Function(Map<String, String> data) onTap) =>
    impl.listenIosNotificationTaps(onTap);

Stream<String> fcmTokenRefresh() => impl.fcmTokenRefresh();

Future<void> deleteFcmToken() => impl.deleteFcmToken();

Future<FcmPushMessage?> getInitialFcmMessage() => impl.getInitialFcmMessage();

Stream<FcmPushMessage> fcmOpenedAppMessages() => impl.fcmOpenedAppMessages();

Stream<FcmPushMessage> fcmForegroundMessages() => impl.fcmForegroundMessages();
