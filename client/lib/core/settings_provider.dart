import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Последний успешно отправленный язык — не спамить PUT из rebuild/listen.
String? _lastSyncedPreferredLanguage;

/// Синхронизирует язык интерфейса на сервер (нужно для автоперевода в чате).
Future<void> syncPreferredLanguageToServer(WidgetRef ref) async {
  // Офлайн: язык уже в SharedPreferences, на сервер — после выхода в онлайн.
  if (ref.read(isOfflineProvider)) return;
  await syncPreferredLanguageWith(
    ref.read(authRepositoryProvider),
    user: ref.read(authStateProvider).valueOrNull,
    languageCode: effectiveAppLocale(ref.read(appLocaleProvider)).languageCode,
  );
}

Future<void> syncPreferredLanguageWith(
  AuthRepository auth, {
  required Object? user,
  required String languageCode,
}) async {
  if (user == null) return;
  final lang = languageCode.trim();
  if (lang.isEmpty) return;
  if (_lastSyncedPreferredLanguage == lang) return;
  try {
    await auth.sendAuthorized(
      (token) => ApiClient.put(
        Uri.parse('$apiBaseUrl/api/settings/language'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'preferred_language': lang}),
        operation: 'syncPreferredLanguageToServer',
      ),
    );
    _lastSyncedPreferredLanguage = lang;
  } catch (_) {
    // не блокируем UI
  }
}

const _keySoundEnabled = 'sound_enabled';
const _keySoundGamesEnabled = 'sound_games_enabled';
const _keySoundNotificationsEnabled = 'sound_notifications_enabled';
const _keySoundTurnEnabled = 'sound_turn_enabled';
const _keyHapticsEnabled = 'haptics_enabled';
const _keyGamepadEnabled = 'gamepad_enabled';
const _keyMessagesFriendsOnlyPrefix = 'messages_friends_only';

/// Настройка: мастер звука (игры + уведомления + ход).
final soundEnabledProvider =
    StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  return SoundEnabledNotifier();
});

class SoundEnabledNotifier extends StateNotifier<bool> {
  SoundEnabledNotifier() : super(true) {
    _load();
  }

  int _rev = 0;

  Future<void> _load() async {
    final rev = _rev;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rev != _rev) return;
      state = prefs.getBool(_keySoundEnabled) ?? true;
    } catch (_) {}
  }

  Future<void> set(bool value) async {
    _rev++;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, value);
    } catch (_) {}
  }
}

/// Локальный bool в SharedPreferences (категории звука / вибрация).
class PrefBoolNotifier extends StateNotifier<bool> {
  PrefBoolNotifier(this._key, {this.defaultValue = true}) : super(defaultValue) {
    _load();
  }

  final String _key;
  final bool defaultValue;
  int _rev = 0;

  Future<void> _load() async {
    final rev = _rev;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rev != _rev) return;
      state = prefs.getBool(_key) ?? defaultValue;
    } catch (_) {}
  }

  Future<void> set(bool value) async {
    _rev++;
    // Сразу, не после SharedPreferences: на iOS канал prefs может не ответить,
    // и галочка иначе остаётся нажатой без смены.
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

/// Звук партий: карты, фишки, выстрелы, победа.
final soundGamesEnabledProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keySoundGamesEnabled);
});

/// Звук бейджей: чат, друзья, инвайты.
final soundNotificationsEnabledProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keySoundNotificationsEnabled);
});

/// Звук «ваш ход» и тик часов.
final soundTurnEnabledProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keySoundTurnEnabled);
});

/// Вибрация только для алертов: уведомления, ход, таймер.
final hapticsEnabledProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keyHapticsEnabled);
});

/// Геймпад: меню, вкладки и курсор на поле.
final gamepadEnabledProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keyGamepadEnabled);
});

/// Настройка: не-друзья могут писать вам только смайликами.
final messagesFriendsOnlyProvider =
    StateNotifierProvider<MessagesFriendsOnlyNotifier, bool>((ref) {
  return MessagesFriendsOnlyNotifier(ref);
});

class MessagesFriendsOnlyNotifier extends StateNotifier<bool> {
  MessagesFriendsOnlyNotifier(this._ref) : super(false) {
    _bootstrap();
  }

  final Ref _ref;

  String _prefsKey(String? userId) {
    final id = (userId ?? '').trim();
    if (id.isEmpty) return _keyMessagesFriendsOnlyPrefix;
    return '${_keyMessagesFriendsOnlyPrefix}_$id';
  }

  Future<void> _bootstrap() async {
    await _loadLocal();
    await refresh();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _ref.read(authStateProvider).valueOrNull;
    final key = _prefsKey(user?.id);
    // Сначала per-user, затем legacy-ключ без user id.
    state = prefs.getBool(key) ??
        prefs.getBool(_keyMessagesFriendsOnlyPrefix) ??
        false;
  }

  Future<void> _persistLocal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final user = _ref.read(authStateProvider).valueOrNull;
    await prefs.setBool(_prefsKey(user?.id), value);
  }

  Future<void> refresh() async {
    final auth = _ref.read(authRepositoryProvider);
    try {
      final response = await auth.sendAuthorized(
        (token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/settings'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'MessagesFriendsOnly.refresh',
        ),
      );
      if (response.statusCode != 200) return;
      final map = jsonDecode(response.body);
      if (map is! Map) return;
      final value = map['messages_friends_only'] as bool? ?? false;
      await _persistLocal(value);
      state = value;
    } catch (_) {
      // локальный кэш уже загружен
    }
  }

  Future<String?> set(bool value) async {
    final previous = state;
    state = value;
    await _persistLocal(value);
    final auth = _ref.read(authRepositoryProvider);
    try {
      final response = await auth.sendAuthorized(
        (token) => ApiClient.put(
          Uri.parse('$apiBaseUrl/api/settings'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'messages_friends_only': value}),
          operation: 'MessagesFriendsOnly.set',
        ),
      );
      if (response.statusCode != 200) {
        state = previous;
        await _persistLocal(previous);
        return LocaleService.l10n.errSettingsSaveFailed;
      }
      final map = jsonDecode(response.body);
      if (map is Map) {
        final saved = map['messages_friends_only'] as bool? ?? value;
        state = saved;
        await _persistLocal(saved);
      }
      return null;
    } catch (_) {
      state = previous;
      await _persistLocal(previous);
      return LocaleService.l10n.errSettingsSaveFailed;
    }
  }
}
