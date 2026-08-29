import 'fcm_stub.dart' if (dart.library.io) 'fcm_io.dart' as impl;

bool fcmSupported() => impl.fcmSupported();

Future<String?> ensureFcmToken() => impl.ensureFcmToken();

Stream<String> fcmTokenRefresh() => impl.fcmTokenRefresh();

Future<void> deleteFcmToken() => impl.deleteFcmToken();
