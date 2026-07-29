import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/browser_push_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/browser_push_web.dart'
    as browser_push;
import 'package:shared_preferences/shared_preferences.dart';

const _keyWebPushEnabled = 'web_push_enabled';

/// Пользовательский флаг «уведомления в браузере» (local prefs).
final webPushEnabledProvider =
    StateNotifierProvider<WebPushEnabledNotifier, bool>((ref) {
  return WebPushEnabledNotifier(ref);
});

class WebPushEnabledNotifier extends StateNotifier<bool> {
  WebPushEnabledNotifier(this._ref) : super(false) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyWebPushEnabled) ?? false;
  }

  /// Включить/выключить: permission → subscribe/unsubscribe → API.
  Future<String?> setEnabled(bool value) async {
    if (value) {
      if (!browser_push.browserPushSupported()) {
        return 'Уведомления недоступны в этом браузере. '
            'На iPhone нужна установленная PWA (На экран «Домой»).';
      }
      var permission = browser_push.browserNotificationPermission();
      if (permission == 'default') {
        permission = await browser_push.requestBrowserNotificationPermission();
      }
      if (permission != 'granted') {
        return 'Разрешите уведомления в настройках браузера / системы.';
      }

      final auth = _ref.read(authRepositoryProvider);
      try {
        final keyResp = await auth.sendAuthorized((token) {
          return ApiClient.get(
            Uri.parse('$apiBaseUrl/api/push/vapid-key'),
            headers: {'Authorization': 'Bearer $token'},
            operation: 'push_vapid_key',
          );
        });
        if (keyResp.statusCode != 200) {
          return 'Сервер не настроен для Web Push (нет VAPID-ключей).';
        }
        final publicKey =
            (jsonDecode(keyResp.body) as Map)['public_key'] as String? ?? '';
        if (publicKey.isEmpty) {
          return 'Пустой VAPID public key';
        }

        final sub = await browser_push.subscribeBrowserPush(
          vapidPublicKey: publicKey,
        );
        final saveResp = await auth.sendAuthorized((token) {
          return ApiClient.post(
            Uri.parse('$apiBaseUrl/api/push/subscribe'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'endpoint': sub.endpoint,
              'keys': {
                'p256dh': sub.p256dh,
                'auth': sub.auth,
              },
            }),
            operation: 'push_subscribe',
          );
        });
        if (saveResp.statusCode < 200 || saveResp.statusCode >= 300) {
          return 'Не удалось сохранить подписку на сервере';
        }
      } catch (e) {
        return e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
      }
    } else {
      try {
        final endpoint = await browser_push.currentBrowserPushEndpoint();
        if (endpoint != null) {
          final auth = _ref.read(authRepositoryProvider);
          await auth.sendAuthorized((token) {
            return ApiClient.post(
              Uri.parse('$apiBaseUrl/api/push/unsubscribe'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'endpoint': endpoint}),
              operation: 'push_unsubscribe',
            );
          });
        }
        await browser_push.unsubscribeBrowserPush();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWebPushEnabled, value);
    state = value;
    return null;
  }
}

/// Поддержка Web Push (для UI).
bool get isWebPushSupported => browser_push.browserPushSupported();
