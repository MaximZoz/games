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

class WebPushCategoryPrefs {
  const WebPushCategoryPrefs({
    this.chat = true,
    this.friends = true,
    this.games = true,
    this.rewards = true,
  });

  final bool chat;
  final bool friends;
  final bool games;
  final bool rewards;

  WebPushCategoryPrefs copyWith({
    bool? chat,
    bool? friends,
    bool? games,
    bool? rewards,
  }) {
    return WebPushCategoryPrefs(
      chat: chat ?? this.chat,
      friends: friends ?? this.friends,
      games: games ?? this.games,
      rewards: rewards ?? this.rewards,
    );
  }

  Map<String, dynamic> toJson() => {
        'chat': chat,
        'friends': friends,
        'games': games,
        'rewards': rewards,
      };

  factory WebPushCategoryPrefs.fromJson(Map<String, dynamic> json) {
    return WebPushCategoryPrefs(
      chat: json['chat'] as bool? ?? true,
      friends: json['friends'] as bool? ?? true,
      games: json['games'] as bool? ?? true,
      rewards: json['rewards'] as bool? ?? true,
    );
  }
}

/// Пользовательский флаг «уведомления в браузере» (local prefs).
final webPushEnabledProvider =
    StateNotifierProvider<WebPushEnabledNotifier, bool>((ref) {
  return WebPushEnabledNotifier(ref);
});

/// Категории Web Push (серверные prefs).
final webPushCategoriesProvider = StateNotifierProvider<
    WebPushCategoriesNotifier, WebPushCategoryPrefs>((ref) {
  return WebPushCategoriesNotifier(ref);
});

class WebPushEnabledNotifier extends StateNotifier<bool> {
  WebPushEnabledNotifier(this._ref) : super(false) {
    _load();
  }

  final Ref _ref;
  bool _ensuring = false;
  bool _boundThisSession = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyWebPushEnabled) ?? false;
  }

  Future<String?> _subscribeAndSave({required bool forceRefresh}) async {
    final auth = _ref.read(authRepositoryProvider);
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
      forceRefresh: forceRefresh,
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
    return null;
  }

  /// После логина / рестарта PWA: заново привязать SW и endpoint, если флаг включён.
  Future<void> ensureActiveSubscription() async {
    if (_ensuring || !state || _boundThisSession) return;
    if (!browser_push.browserPushSupported()) return;
    if (browser_push.browserNotificationPermission() != 'granted') return;
    if (_ref.read(authStateProvider).valueOrNull == null) return;

    _ensuring = true;
    _boundThisSession = true;
    try {
      await _subscribeAndSave(forceRefresh: false);
      await _ref.read(webPushCategoriesProvider.notifier).refresh();
    } catch (_) {
    } finally {
      _ensuring = false;
    }
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

      try {
        final err = await _subscribeAndSave(forceRefresh: true);
        if (err != null) return err;
      } catch (e) {
        return e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
      }
      _boundThisSession = true;
      await _ref.read(webPushCategoriesProvider.notifier).refresh();
    } else {
      await _unsubscribeEndpointAndBrowser();
      _boundThisSession = false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWebPushEnabled, value);
    state = value;
    return null;
  }

  /// Снять endpoint с сервера и в браузере. Флаг prefs не трогаем —
  /// после следующего логина [ensureActiveSubscription] подпишет снова.
  /// Вызывать до очистки JWT.
  Future<void> detachOnLogout() async {
    _boundThisSession = false;
    await _unsubscribeEndpointAndBrowser();
  }

  Future<void> _unsubscribeEndpointAndBrowser() async {
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
      await browser_push.clearPushUiOnLogout();
    } catch (_) {}
  }
}

class WebPushCategoriesNotifier extends StateNotifier<WebPushCategoryPrefs> {
  WebPushCategoriesNotifier(this._ref) : super(const WebPushCategoryPrefs()) {
    refresh();
  }

  final Ref _ref;
  bool _saving = false;

  Future<void> refresh() async {
    if (_ref.read(authStateProvider).valueOrNull == null) return;
    try {
      final auth = _ref.read(authRepositoryProvider);
      final resp = await auth.sendAuthorized((token) {
        return ApiClient.get(
          Uri.parse('$apiBaseUrl/api/push/preferences'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'push_preferences_get',
        );
      });
      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        state = WebPushCategoryPrefs.fromJson(map);
      }
    } catch (_) {}
  }

  Future<String?> setCategory({
    bool? chat,
    bool? friends,
    bool? games,
    bool? rewards,
  }) async {
    if (_saving) return null;
    final next = state.copyWith(
      chat: chat,
      friends: friends,
      games: games,
      rewards: rewards,
    );
    final prev = state;
    state = next;
    _saving = true;
    try {
      final auth = _ref.read(authRepositoryProvider);
      final resp = await auth.sendAuthorized((token) {
        return ApiClient.put(
          Uri.parse('$apiBaseUrl/api/push/preferences'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(next.toJson()),
          operation: 'push_preferences_put',
        );
      });
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        state = prev;
        return 'Не удалось сохранить настройки уведомлений';
      }
      return null;
    } catch (e) {
      state = prev;
      return e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    } finally {
      _saving = false;
    }
  }
}

/// Поддержка Web Push (для UI).
bool get isWebPushSupported => browser_push.browserPushSupported();

bool get isWebPushStandalone => browser_push.browserPushStandalone();
