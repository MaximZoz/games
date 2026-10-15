import 'dart:io';

import 'package:flutter/services.dart';

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

bool get isAppleSignInSupported => Platform.isIOS;

const _channel = MethodChannel('com.zozugames/apple_sign_in');

bool _isCanceled(PlatformException e) {
  final code = e.code.toLowerCase();
  final msg = (e.message ?? '').toLowerCase();
  return code.contains('cancel') || msg.contains('cancel');
}

/// Системный лист Apple ID через канал в AppDelegate (AuthenticationServices).
Future<AppleNativeSignInResult?> signInWithAppleNative() async {
  if (!isAppleSignInSupported) {
    throw AppleSignInUnavailableException();
  }
  try {
    final raw = await _channel.invokeMapMethod<String, dynamic>('signIn');
    if (raw == null) return null;
    final token = (raw['identityToken'] ?? '').toString().trim();
    if (token.isEmpty) {
      throw AppleSignInUnavailableException(
        'Sign in with Apple: empty identity token',
      );
    }
    String? text(String key) {
      final value = (raw[key] ?? '').toString().trim();
      return value.isEmpty ? null : value;
    }

    return AppleNativeSignInResult(
      identityToken: token,
      email: text('email'),
      givenName: text('givenName'),
      familyName: text('familyName'),
    );
  } on PlatformException catch (e) {
    if (_isCanceled(e)) return null;
    throw AppleSignInUnavailableException(e.message ?? e.code);
  } on MissingPluginException {
    throw AppleSignInUnavailableException(
      'Sign in with Apple: native channel is not registered',
    );
  }
}
