import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Нативный Google Sign-In вернул аккаунт, но без credential.
class GoogleIdTokenMissingException implements Exception {
  GoogleIdTokenMissingException([
    this.message = 'Google Sign-In: empty credential',
  ]);
  final String message;
  @override
  String toString() => message;
}

/// Результат нативного Google Sign-In.
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

GoogleSignIn? _cachedSignIn;
String? _cachedServerClientId;

GoogleSignIn _googleSignInFor(String webClientId) {
  if (_cachedSignIn != null && _cachedServerClientId == webClientId) {
    return _cachedSignIn!;
  }
  _cachedServerClientId = webClientId;
  _cachedSignIn = GoogleSignIn(
    scopes: const <String>['openid', 'email', 'profile'],
    serverClientId: webClientId,
  );
  return _cachedSignIn!;
}

bool _isCanceled(Object e) {
  if (e is! PlatformException) return false;
  final code = e.code.toLowerCase();
  final msg = (e.message ?? '').toLowerCase();
  return code.contains('cancel') ||
      msg.contains('cancel') ||
      code == 'sign_in_canceled' ||
      e.code == '12501';
}

/// Вход через Google-аккаунт на устройстве (тот же, что в Play Store).
///
/// Берём `idToken` / `serverAuthCode` из [GoogleSignInUserData] через
/// platform `signIn()` — **без** `account.authentication` / getTokens
/// (на Android getTokens часто зависает).
Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  final webClientId = serverClientId.trim();
  if (webClientId.isEmpty) return null;

  // Инициализация с serverClientId (requestIdToken на Android).
  final gsi = _googleSignInFor(webClientId);
  await gsi.isSignedIn();

  GoogleSignInUserData? userData;
  try {
    userData = await GoogleSignInPlatform.instance
        .signIn()
        .timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw GoogleIdTokenMissingException(
      'Google Sign-In: timeout after account picker',
    );
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    rethrow;
  }

  if (userData == null) return null;

  final idToken = userData.idToken?.trim();
  final serverAuthCode = userData.serverAuthCode?.trim();
  final result = GoogleNativeSignInResult(
    idToken: (idToken != null && idToken.isNotEmpty) ? idToken : null,
    serverAuthCode:
        (serverAuthCode != null && serverAuthCode.isNotEmpty) ? serverAuthCode : null,
  );

  if (result.hasCredential) {
    debugPrint(
      'Google Sign-In: email=${userData.email} '
      'idToken=${result.idToken != null} '
      'serverAuthCode=${result.serverAuthCode != null}',
    );
    return result;
  }

  debugPrint(
    'Google Sign-In: email=${userData.email} but empty idToken/serverAuthCode '
    '(SHA-1 App Signing / Web Client ID / GCP project?)',
  );
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken/serverAuthCode (SHA-1 App Signing / Web Client ID)',
  );
}

/// Совместимость: только id_token.
Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  final result = await signInWithGoogleNative(serverClientId: serverClientId);
  if (result == null) return null;
  final t = result.idToken?.trim();
  if (t != null && t.isNotEmpty) return t;
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken (use signInWithGoogleNative for serverAuthCode)',
  );
}
