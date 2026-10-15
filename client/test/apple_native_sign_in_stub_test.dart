import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/apple_native_sign_in_stub.dart';

void main() {
  test('stub signInWithAppleNative returns null (web/tests)', () async {
    expect(isAppleSignInSupported, isFalse);
    expect(await signInWithAppleNative(), isNull);
  });

  test('AppleSignInUnavailableException toString is the message', () {
    final e = AppleSignInUnavailableException('no apple');
    expect(e.toString(), 'no apple');
  });
}
