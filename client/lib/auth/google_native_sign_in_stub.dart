// Web / тесты без io: нативный Google Sign-In недоступен.

class GoogleIdTokenMissingException implements Exception {
  GoogleIdTokenMissingException([
    this.message = 'Google Sign-In: empty idToken',
  ]);
  final String message;
  @override
  String toString() => message;
}

class GoogleNativeSignInResult {
  const GoogleNativeSignInResult({
    this.idToken,
    this.serverAuthCode,
  });

  final String? idToken;
  final String? serverAuthCode;

  bool get hasCredential =>
      (idToken != null && idToken!.isNotEmpty) ||
      (serverAuthCode != null && serverAuthCode!.isNotEmpty);
}

Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  return null;
}

Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  return null;
}
