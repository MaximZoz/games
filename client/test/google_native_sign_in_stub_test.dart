import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/google_native_sign_in_stub.dart';

void main() {
  test('stub signInWithGoogleIdToken returns null (web/tests)', () async {
    final token = await signInWithGoogleIdToken(
      serverClientId: 'test.apps.googleusercontent.com',
    );
    expect(token, isNull);
  });
}
