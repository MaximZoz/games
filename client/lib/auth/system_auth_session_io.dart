import 'package:flutter/services.dart';

class SystemAuthSessionException implements Exception {
  SystemAuthSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _channel = MethodChannel('com.zozugames/system_auth');

/// true — провайдер вернул в приложение, false — пользователь закрыл лист.
Future<bool> startSystemAuthSession({
  required String url,
  required String callbackScheme,
}) async {
  try {
    final ok = await _channel.invokeMethod<bool>('start', {
      'url': url,
      'callbackScheme': callbackScheme,
    });
    return ok == true;
  } on PlatformException catch (e) {
    final code = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    if (code.contains('cancel') || msg.contains('cancel')) return false;
    final text = (e.message ?? '').trim();
    throw SystemAuthSessionException(text.isEmpty ? e.code : text);
  } on MissingPluginException {
    throw SystemAuthSessionException(
      'Sign-in sheet is not available in this build',
    );
  }
}

Future<void> cancelSystemAuthSession() async {
  try {
    await _channel.invokeMethod<void>('cancel');
  } catch (_) {}
}
