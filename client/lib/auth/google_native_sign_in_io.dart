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

/// Google ApiException 10 / DEVELOPER_ERROR — неверный package или SHA-1.
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

/// ApiException: 10 / DEVELOPER_ERROR / "sign_in_failed ... 10" / "d 10"
bool isGoogleDeveloperError(Object e) {
  if (e is GoogleSignInDeveloperErrorException) return true;
  final blob = e.toString().toLowerCase();
  if (blob.contains('developer_error')) return true;
  // Типичные формы: "ApiException: 10:", "sign_in_failed ... 10", "d 10"
  if (RegExp(r'apiexception\s*:?\s*10\b').hasMatch(blob)) return true;
  if (RegExp(r'\bd\s*10\b').hasMatch(blob)) return true;
  if (e is PlatformException) {
    final code = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    if (code == '10') return true;
    if (code.contains('sign_in_failed') &&
        RegExp(r'(^|[^\d])10(\D|$)').hasMatch(msg)) {
      return true;
    }
  }
  return false;
}

GoogleNativeSignInResult? _resultFromTokens({
  String? idToken,
  String? serverAuthCode,
  String? email,
}) {
  final token = idToken?.trim();
  final code = serverAuthCode?.trim();
  final result = GoogleNativeSignInResult(
    idToken: (token != null && token.isNotEmpty) ? token : null,
    serverAuthCode: (code != null && code.isNotEmpty) ? code : null,
  );
  if (result.hasCredential) {
    debugPrint(
      'Google Sign-In: email=$email '
      'idToken=${result.idToken != null} '
      'serverAuthCode=${result.serverAuthCode != null}',
    );
    return result;
  }
  return null;
}

/// iOS: [GoogleSignIn.signIn] показывает системный лист Gmail.
/// Platform `signIn()` на iOS часто зависает: Scene не прокидывал URL.
Future<GoogleNativeSignInResult?> _signInWithGoogleIos(GoogleSignIn gsi) async {
  GoogleSignInAccount? account;
  try {
    account = await gsi.signIn().timeout(const Duration(seconds: 60));
  } on TimeoutException {
    throw GoogleIdTokenMissingException(
      'Google Sign-In: timeout after account picker',
    );
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    if (isGoogleDeveloperError(e)) {
      debugPrint('Google Sign-In DEVELOPER_ERROR (10): $e');
      throw GoogleSignInDeveloperErrorException();
    }
    rethrow;
  }
  if (account == null) return null;

  GoogleSignInAuthentication auth;
  try {
    auth = await account.authentication.timeout(const Duration(seconds: 20));
  } on TimeoutException {
    throw GoogleIdTokenMissingException(
      'Google Sign-In: iOS tokens timeout',
    );
  }

  final result = _resultFromTokens(
    idToken: auth.idToken,
    serverAuthCode: account.serverAuthCode,
    email: account.email,
  );
  if (result != null) return result;
  debugPrint(
    'Google Sign-In: email=${account.email} but empty idToken/serverAuthCode '
    '(iOS OAuth client / GIDClientID / URL scheme)',
  );
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken. В Google Cloud нужен iOS OAuth client '
    'с Bundle ID com.zozugames.app(.dev) и GIDClientID / URL scheme в Info.plist.',
  );
}

/// Android: platform `signIn()` — без `account.authentication` / getTokens
/// (на Android getTokens часто зависает).
Future<GoogleNativeSignInResult?> _signInWithGoogleAndroid(
  GoogleSignIn gsi,
) async {
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
    if (isGoogleDeveloperError(e)) {
      debugPrint('Google Sign-In DEVELOPER_ERROR (10): $e');
      throw GoogleSignInDeveloperErrorException();
    }
    rethrow;
  }

  if (userData == null) return null;

  final result = _resultFromTokens(
    idToken: userData.idToken,
    serverAuthCode: userData.serverAuthCode,
    email: userData.email,
  );
  if (result != null) return result;
  debugPrint(
    'Google Sign-In: email=${userData.email} but empty idToken/serverAuthCode '
    '(SHA-1 App Signing / Web Client ID / GCP project?)',
  );
  throw GoogleIdTokenMissingException(
    'Google Sign-In: empty idToken/serverAuthCode (SHA-1 App Signing / Web Client ID)',
  );
}

/// Вход через Google-аккаунт на устройстве (тот же, что в Play Store / Gmail).
Future<GoogleNativeSignInResult?> signInWithGoogleNative({
  required String serverClientId,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  final webClientId = serverClientId.trim();
  if (webClientId.isEmpty) return null;

  final gsi = _googleSignInFor(webClientId);
  if (Platform.isIOS) {
    return _signInWithGoogleIos(gsi);
  }
  return _signInWithGoogleAndroid(gsi);
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
