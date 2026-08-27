import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Нативный Google Sign-In вернул аккаунт, но без id_token / server_auth_code.
class GoogleIdTokenMissingException implements Exception {
  GoogleIdTokenMissingException([
    this.message = 'Google Sign-In: empty idToken',
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
    // Просим server auth code каждый раз — запасной путь, если id_token пуст.
    forceCodeForRefreshToken: true,
  );
  return _cachedSignIn!;
}

bool _isCanceled(PlatformException e) {
  final code = e.code.toLowerCase();
  final msg = (e.message ?? '').toLowerCase();
  return code.contains('cancel') ||
      msg.contains('cancel') ||
      code == 'sign_in_canceled' ||
      e.code == '12501';
}

/// Вход через Google-аккаунт на устройстве (тот же, что в Play Store).
///
/// [serverClientId] — Web OAuth Client ID с бэкенда (`google_client_id`).
///
/// Возвращает `null`, если пользователь закрыл picker.
/// Бросает [GoogleIdTokenMissingException], если аккаунт выбран без credential.
Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  final webClientId = serverClientId.trim();
  if (webClientId.isEmpty) return null;

  final googleSignIn = _googleSignInFor(webClientId);

  // Не вызываем signOut() перед signIn(): на Android это часто даёт
  // аккаунт без id_token после выбора в picker.

  GoogleSignInAccount? account;
  try {
    account = await googleSignIn.signIn();
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    rethrow;
  }

  if (account == null) return null;

  String? idToken;
  try {
    final auth = await account.authentication;
    idToken = auth.idToken?.trim();
  } catch (e) {
    debugPrint('Google Sign-In authentication error: $e');
  }

  final serverAuthCode = account.serverAuthCode?.trim();
  final result = GoogleNativeSignInResult(
    idToken: (idToken != null && idToken.isNotEmpty) ? idToken : null,
    serverAuthCode:
        (serverAuthCode != null && serverAuthCode.isNotEmpty) ? serverAuthCode : null,
  );

  if (!result.hasCredential) {
    debugPrint(
      'Google Sign-In: account=${account.email} but no idToken/serverAuthCode '
      '(SHA-1 App Signing / GCP project?)',
    );
    throw GoogleIdTokenMissingException(
      'Google Sign-In: empty idToken/serverAuthCode (SHA-1 App Signing / Web Client ID)',
    );
  }
  return result;
}

/// Совместимость: только id_token (или null при отмене).
Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  final result = await signInWithGoogleNative(serverClientId: serverClientId);
  if (result == null) return null;
  final t = result.idToken?.trim();
  if (t != null && t.isNotEmpty) return t;
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken (use signInWithGoogleNative for serverAuthCode)',
  );
}
