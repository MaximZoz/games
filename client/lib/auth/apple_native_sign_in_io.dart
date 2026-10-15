import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

bool get isAppleSignInSupported =>
    Platform.isIOS || Platform.isMacOS;

bool _isCanceled(Object e) {
  if (e is SignInWithAppleAuthorizationException) {
    return e.code == AuthorizationErrorCode.canceled;
  }
  if (e is PlatformException) {
    final code = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    return code.contains('cancel') || msg.contains('cancel');
  }
  return false;
}

/// Системный лист Apple ID (тот же аккаунт, что в Настройках iPhone).
Future<AppleNativeSignInResult?> signInWithAppleNative() async {
  if (!isAppleSignInSupported) {
    throw AppleSignInUnavailableException();
  }
  final available = await SignInWithApple.isAvailable();
  if (!available) {
    throw AppleSignInUnavailableException();
  }

  try {
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final token = (cred.identityToken ?? '').trim();
    if (token.isEmpty) {
      throw AppleSignInUnavailableException(
        'Sign in with Apple: empty identity token',
      );
    }
    return AppleNativeSignInResult(
      identityToken: token,
      email: cred.email,
      givenName: cred.givenName,
      familyName: cred.familyName,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (_isCanceled(e)) return null;
    debugPrint('Sign in with Apple failed: $e');
    rethrow;
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    rethrow;
  }
}
