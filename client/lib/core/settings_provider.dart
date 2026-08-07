import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Последний успешно отправленный язык — не спамить PUT из rebuild/listen.
String? _lastSyncedPreferredLanguage;

/// Синхронизирует язык интерфейса на сервер (нужно для автоперевода в чате).
Future<void> syncPreferredLanguageToServer(WidgetRef ref) async {
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

const _keyAddBotsAfter30s = 'add_bots_after_30s';
const _keyMessagesFriendsOnlyPrefix = 'messages_friends_only';

/// Настройка: если включена, в режиме «поиск игры» ждём 30 секунд,
/// и если соперник не найден — добавляем бота и начинаем игру.
final addBotsAfter30sProvider =
    StateNotifierProvider<AddBotsAfter30sNotifier, bool>((ref) {
  return AddBotsAfter30sNotifier();
});

class AddBotsAfter30sNotifier extends StateNotifier<bool> {
  AddBotsAfter30sNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyAddBotsAfter30s) ?? false;
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAddBotsAfter30s, value);
    state = value;
  }
}

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
