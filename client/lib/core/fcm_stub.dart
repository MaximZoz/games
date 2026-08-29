import 'package:multigames_client/core/fcm_types.dart';

bool fcmSupported() => false;

Future<String?> ensureFcmToken() async => null;

Stream<String> fcmTokenRefresh() => const Stream.empty();

Future<void> deleteFcmToken() async {}

Future<FcmPushMessage?> getInitialFcmMessage() async => null;

Stream<FcmPushMessage> fcmOpenedAppMessages() => const Stream.empty();

Stream<FcmPushMessage> fcmForegroundMessages() => const Stream.empty();
