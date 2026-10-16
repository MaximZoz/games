/// Платформа для `POST /api/push/device`.
/// iPhone нельзя записывать как android: это другой APNs-токен.
String devicePushPlatformName(String operatingSystem) {
  if (operatingSystem == 'ios') return 'ios';
  return 'android';
}
