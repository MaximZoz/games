import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  // Не ставим forceCodeForRefreshToken: после picker это часто зависает
  // на offline-consent, и кнопка крутит лоадер бесконечно.
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
/// Важно: **не** вызываем `account.authentication` / getTokens —
/// на Android это может открыть recovery Intent и зависнуть, пока Flutter
/// крутит лоадер. Берём `serverAuthCode` из результата `signIn()` и
/// меняем его на бэкенде.
Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  final webClientId = serverClientId.trim();
  if (webClientId.isEmpty) return null;

  final googleSignIn = _googleSignInFor(webClientId);

  GoogleSignInAccount? account;
  try {
    account = await googleSignIn.signIn().timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw GoogleIdTokenMissingException(
      'Google Sign-In: timeout after account picker',
    );
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    rethrow;
  }

  if (account == null) return null;

  final serverAuthCode = account.serverAuthCode?.trim();
  if (serverAuthCode != null && serverAuthCode.isNotEmpty) {
    debugPrint('Google Sign-In: serverAuthCode ok for ${account.email}');
    return GoogleNativeSignInResult(serverAuthCode: serverAuthCode);
  }

  // id_token из sign-in лежит в приватном поле; authentication→getTokens
  // на Android часто зависает. Не вызываем его — пусть UI сделает fallback.
  debugPrint(
    'Google Sign-In: account=${account.email} but serverAuthCode empty '
    '(SHA-1 App Signing / Web Client ID / GCP project?)',
  );
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty serverAuthCode (SHA-1 App Signing / Web Client ID)',
  );
}

/// Совместимость: только id_token (на native сейчас не извлекаем без getTokens).
Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  final result = await signInWithGoogleNative(serverClientId: serverClientId);
  if (result == null) return null;
  final t = result.idToken?.trim();
  if (t != null && t.isNotEmpty) return t;
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken (use signInWithGoogleNative for serverAuthCode)',
  );
}
