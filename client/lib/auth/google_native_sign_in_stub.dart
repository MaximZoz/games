// Web / тесты без io: нативный Google Sign-In недоступен.

class GoogleIdTokenMissingException implements Exception {
  GoogleIdTokenMissingException([
    this.message = 'Google Sign-In: empty idToken',
  ]);
  final String message;
  @override
  String toString() => message;
}

class GoogleSignInDeveloperErrorException implements Exception {
  GoogleSignInDeveloperErrorException([
    this.message =
        'Google Sign-In код 10: в Google Cloud создай Android OAuth client '
        'с package com.zozugames.app(.dev) и SHA-1 App signing из Play Console. '
        'Без этого вход без браузера не работает.',
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

bool isGoogleDeveloperError(Object e) {
  if (e is GoogleSignInDeveloperErrorException) return true;
  return false;
}

Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  return null;
}

Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  return null;
}
