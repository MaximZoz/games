import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/google_native_sign_in_stub.dart';

void main() {
  test('stub signInWithGoogleNative returns null (web/tests)', () async {
    final result = await signInWithGoogleNative(
      serverClientId: 'test.apps.googleusercontent.com',
    );
    expect(result, isNull);
  });

  test('stub signInWithGoogleIdToken returns null (web/tests)', () async {
    final token = await signInWithGoogleIdToken(
      serverClientId: 'test.apps.googleusercontent.com',
    );
    expect(token, isNull);
  });

  test('GoogleIdTokenMissingException toString', () {
    final e = GoogleIdTokenMissingException('empty');
    expect(e.toString(), 'empty');
  });

  test('GoogleNativeSignInResult.hasCredential', () {
    expect(
      const GoogleNativeSignInResult(idToken: 'x').hasCredential,
      isTrue,
    );
    expect(
      const GoogleNativeSignInResult(serverAuthCode: 'y').hasCredential,
      isTrue,
    );
    expect(const GoogleNativeSignInResult().hasCredential, isFalse);
  });
}
