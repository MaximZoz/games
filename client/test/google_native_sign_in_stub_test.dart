import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/google_native_sign_in_stub.dart';

void main() {
  test('stub signInWithGoogleNative returns null (web/tests)', () async {
    final result = await signInWithGoogleNative(
      serverClientId: 'test.apps.googleusercontent.com',
    );
    expect(result, isNull);
  });

  test('GoogleSignInDeveloperErrorException message mentions SHA-1', () {
    final e = GoogleSignInDeveloperErrorException();
    expect(e.message, contains('SHA-1'));
    expect(e.message, contains('10'));
  });

  test('isGoogleDeveloperError on stub type', () {
    expect(isGoogleDeveloperError(GoogleSignInDeveloperErrorException()), isTrue);
    expect(isGoogleDeveloperError(Exception('other')), isFalse);
  });
}
