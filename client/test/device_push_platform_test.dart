import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/device_push_platform.dart';

void main() {
  test('iPhone регистрируется как ios, остальное как android', () {
    expect(devicePushPlatformName('ios'), 'ios');
    expect(devicePushPlatformName('android'), 'android');
    expect(devicePushPlatformName(''), 'android');
  });
}
