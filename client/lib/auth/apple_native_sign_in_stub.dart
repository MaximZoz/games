// Web / тесты без io: системный Sign in with Apple недоступен.

class AppleNativeSignInResult {
  const AppleNativeSignInResult({
    required this.identityToken,
    this.email,
    this.givenName,
    this.familyName,
  });

  final String identityToken;
  final String? email;
  final String? givenName;
  final String? familyName;
}

class AppleSignInUnavailableException implements Exception {
  AppleSignInUnavailableException([
    this.message = 'Sign in with Apple is not available',
  ]);
  final String message;
  @override
  String toString() => message;
}

bool get isAppleSignInSupported => false;

Future<AppleNativeSignInResult?> signInWithAppleNative() async => null;
