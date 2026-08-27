import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

/// Вход через Google-аккаунт на устройстве (тот же, что в Play Store).
///
/// [serverClientId] — Web OAuth Client ID с бэкенда (`google_client_id`),
/// чтобы `aud` id_token совпал с `GOOGLE_CLIENT_ID` на сервере.
Future<String?> signInWithGoogleIdToken({required String serverClientId}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  final webClientId = serverClientId.trim();
  if (webClientId.isEmpty) return null;

  final googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: webClientId,
  );
  // Сбросить предыдущую сессию, чтобы показать picker аккаунта.
  try {
    await googleSignIn.signOut();
  } catch (_) {}

  final account = await googleSignIn.signIn();
  if (account == null) return null; // пользователь отменил
  final auth = await account.authentication;
  final idToken = auth.idToken?.trim();
  if (idToken == null || idToken.isEmpty) {
    throw StateError('Google Sign-In: empty idToken');
  }
  return idToken;
}
