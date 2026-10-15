import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/browser_push_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/browser_push_web.dart'
    as browser_push;
import 'package:multigames_client/core/fcm.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM токен зарегистрирован — системный пуш придёт и при закрытом приложении.
final fcmDeliveryReadyProvider = StateProvider<bool>((ref) => false);

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
  WebPushEnabledNotifier(this._ref) : super(true) {
    _load();
  }

  final Ref _ref;
  bool _ensuring = false;
  bool _boundThisSession = false;
  bool _deviceBoundThisSession = false;
  DateTime? _lastEnsureAttempt;
  DateTime? _lastDeviceEnsureAttempt;
  String? _deviceToken;
  bool _listeningTokenRefresh = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // По умолчанию включено: новые пользователи / чистый профиль устройства.
    state = prefs.getBool(_keyWebPushEnabled) ?? true;
  }

  /// Для нового аккаунта после регистрации: permission + subscribe.
  /// Ошибки глотаем — регистрация уже успешна.
  Future<void> enableForNewUser() async {
    if (state && _boundThisSession) return;
    await setEnabled(true);
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

  /// Web Push (PWA) + FCM (Android и iPhone), если уведомления включены.
  Future<void> ensurePushForSession() async {
    await ensureActiveSubscription();
    await ensureAndroidDevicePush();
  }

  /// После логина / рестарта PWA: заново привязать SW и endpoint, если флаг включён.
  Future<void> ensureActiveSubscription() async {
    if (_ensuring || !state || _boundThisSession) return;
    if (!browser_push.browserPushSupported()) return;
    if (_ref.read(authStateProvider).valueOrNull == null) return;

    final now = DateTime.now();
    if (_lastEnsureAttempt != null &&
        now.difference(_lastEnsureAttempt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastEnsureAttempt = now;

    var permission = browser_push.browserNotificationPermission();
    // После logout endpoint снят, а prefs остаётся ON — нужно снова
    // получить permission (если default) и зарегистрировать подписку.
    if (permission == 'default') {
      // В установленной PWA пробуем сразу; без жеста Safari может отказать.
      if (!browser_push.browserPushStandalone()) return;
      permission = await browser_push.requestBrowserNotificationPermission();
    }
    if (permission != 'granted') return;

    _ensuring = true;
    try {
      // forceRefresh: после detachOnLogout старой подписки нет, а на сервере
      // нужен свежий endpoint — как при ручном выкл/вкл.
      final err = await _subscribeAndSave(forceRefresh: true);
      if (err != null) return;
      _boundThisSession = true;
      await _ref.read(webPushCategoriesProvider.notifier).refresh();
    } catch (_) {
      // Не помечаем bound — повторим на следующем кадре shell / через 5 с.
    } finally {
      _ensuring = false;
    }
  }

  /// Включить/выключить: permission → subscribe/unsubscribe → API.
  Future<String?> setEnabled(bool value) async {
    if (value && !kIsWeb && localNotificationsSupported()) {
      final granted = await requestLocalNotificationPermission();
      if (!granted) return LocaleService.l10n.errPushPermission;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyWebPushEnabled, true);
      state = true;
      await _ref.read(webPushCategoriesProvider.notifier).refresh();
      await ensureAndroidDevicePush();
      return null;
    }
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
        return LocaleService.l10n.errPushPermission;
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
      await _unregisterDeviceToken();
      _boundThisSession = false;
      _deviceBoundThisSession = false;
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
    _deviceBoundThisSession = false;
    await _unsubscribeEndpointAndBrowser();
    await _unregisterDeviceToken();
    _ref.read(fcmDeliveryReadyProvider.notifier).state = false;
  }

  Future<void> ensureAndroidDevicePush() async {
    if (kIsWeb || !state || !fcmSupported()) return;
    if (_ref.read(authStateProvider).valueOrNull == null) return;
    if (_deviceBoundThisSession && (_deviceToken ?? '').isNotEmpty) return;

    final now = DateTime.now();
    if (_lastDeviceEnsureAttempt != null &&
        now.difference(_lastDeviceEnsureAttempt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastDeviceEnsureAttempt = now;

    final granted = await requestLocalNotificationPermission();
    if (!granted) return;
    final token = await ensureFcmToken();
    if (token == null || token.isEmpty) return;
    if (!await _saveDeviceToken(token)) return;
    _deviceToken = token;
    _deviceBoundThisSession = true;
    _ref.read(fcmDeliveryReadyProvider.notifier).state = true;
    _listenTokenRefresh();
  }

  void _listenTokenRefresh() {
    if (_listeningTokenRefresh) return;
    _listeningTokenRefresh = true;
    fcmTokenRefresh().listen((token) async {
      if (!state || token.isEmpty) return;
      if (!await _saveDeviceToken(token)) return;
      _deviceToken = token;
      _ref.read(fcmDeliveryReadyProvider.notifier).state = true;
    });
  }

  Future<bool> _saveDeviceToken(String token) async {
    try {
      final auth = _ref.read(authRepositoryProvider);
      final resp = await auth.sendAuthorized((access) {
        return ApiClient.post(
          Uri.parse('$apiBaseUrl/api/push/device'),
          headers: {
            'Authorization': 'Bearer $access',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': token, 'platform': devicePushPlatform()}),
          operation: 'push_device_register',
        );
      });
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _unregisterDeviceToken() async {
    final token = _deviceToken;
    _deviceToken = null;
    _ref.read(fcmDeliveryReadyProvider.notifier).state = false;
    if (token != null && token.isNotEmpty) {
      try {
        final auth = _ref.read(authRepositoryProvider);
        await auth.sendAuthorized((access) {
          return ApiClient.post(
            Uri.parse('$apiBaseUrl/api/push/device/unregister'),
            headers: {
              'Authorization': 'Bearer $access',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': token}),
            operation: 'push_device_unregister',
          );
        });
      } catch (_) {}
    }
    await deleteFcmToken();
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
        return LocaleService.l10n.errSettingsSaveFailed;
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

/// Настройки уведомлений: web push или локальные на Android и iPhone.
bool get isPushSettingsAvailable =>
    isWebPushSupported || localNotificationsSupported();

bool get isWebPushStandalone => browser_push.browserPushStandalone();
