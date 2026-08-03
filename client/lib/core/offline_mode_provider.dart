import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/connectivity_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/connectivity_web.dart'
    if (dart.library.js_interop) 'package:multigames_client/core/connectivity_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyOfflinePreference = 'offline_mode_preference';

/// Ручной выбор в настройках.
enum OfflinePreference {
  /// Онлайн: при наличии сети — онлайн, при потере — офлайн.
  online,

  /// Принудительный офлайн (даже при интернете).
  offline,
}

/// Почему сейчас нельзя включить онлайн (для тоста в настройках).
enum OnlineUnavailableReason {
  /// Сеть и API доступны.
  none,

  /// Нет сети на устройстве.
  noInternet,

  /// Сеть есть, но API/сервер недоступен.
  serverUnreachable,
}

/// Сводка режима для UI и репозиториев.
class OfflineModeState {
  const OfflineModeState({
    required this.preference,
    required this.deviceOnline,
    required this.serverReachable,
  });

  final OfflinePreference preference;

  /// Браузер/ОС считают устройство онлайн.
  final bool deviceOnline;

  /// Probe `/api/start` успешен.
  final bool serverReachable;

  /// Можно работать с API.
  bool get hasNetwork => deviceOnline && serverReachable;

  /// Эффективный офлайн: ручной офлайн или нет сети/сервера.
  bool get isOffline =>
      preference == OfflinePreference.offline || !hasNetwork;

  OnlineUnavailableReason get onlineUnavailableReason {
    if (!deviceOnline) return OnlineUnavailableReason.noInternet;
    if (!serverReachable) return OnlineUnavailableReason.serverUnreachable;
    return OnlineUnavailableReason.none;
  }

  OfflineModeState copyWith({
    OfflinePreference? preference,
    bool? deviceOnline,
    bool? serverReachable,
  }) {
    return OfflineModeState(
      preference: preference ?? this.preference,
      deviceOnline: deviceOnline ?? this.deviceOnline,
      serverReachable: serverReachable ?? this.serverReachable,
    );
  }
}

final offlineModeProvider =
    StateNotifierProvider<OfflineModeNotifier, OfflineModeState>((ref) {
  return OfflineModeNotifier();
});

/// Удобный флаг: сейчас офлайн.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(offlineModeProvider).isOffline;
});

class OfflineModeNotifier extends StateNotifier<OfflineModeState> {
  OfflineModeNotifier()
      : super(OfflineModeState(
          preference: OfflinePreference.online,
          deviceOnline: readDeviceOnline(),
          serverReachable: readDeviceOnline(),
        )) {
    _init();
  }

  StreamSubscription<bool>? _deviceSub;
  Timer? _probeTimer;
  bool _disposed = false;

  Future<void> _init() async {
    await _loadPreference();
    _deviceSub = deviceOnlineStream().listen((online) {
      if (_disposed) return;
      state = state.copyWith(deviceOnline: online);
      if (online) {
        unawaited(_probeReachable());
      } else {
        state = state.copyWith(serverReachable: false);
      }
    });
    // Периодический probe: ловит «online» без реального API.
    _probeTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_probeReachable());
    });
    unawaited(_probeReachable());
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOfflinePreference);
    final preference = raw == 'offline'
        ? OfflinePreference.offline
        : OfflinePreference.online;
    if (_disposed) return;
    state = state.copyWith(
      preference: preference,
      deviceOnline: readDeviceOnline(),
    );
  }

  Future<void> setPreference(OfflinePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyOfflinePreference,
      preference == OfflinePreference.offline ? 'offline' : 'online',
    );
    if (_disposed) return;
    state = state.copyWith(preference: preference);
    if (preference == OfflinePreference.online) {
      unawaited(_probeReachable());
    }
  }

  /// Попытка выйти в онлайн. `null` — ок; иначе причина для тоста.
  Future<OnlineUnavailableReason?> tryGoOnline() async {
    await _probeReachable();
    if (_disposed) return OnlineUnavailableReason.serverUnreachable;
    final reason = state.onlineUnavailableReason;
    if (reason != OnlineUnavailableReason.none) {
      return reason;
    }
    await setPreference(OfflinePreference.online);
    return null;
  }

  /// Лёгкая проверка доступности API.
  Future<void> _probeReachable() async {
    final deviceOnline = readDeviceOnline() || state.deviceOnline;
    if (!deviceOnline) {
      if (_disposed) return;
      if (state.deviceOnline || state.serverReachable) {
        state = state.copyWith(deviceOnline: false, serverReachable: false);
      }
      return;
    }
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/start'))
          .timeout(const Duration(seconds: 4));
      final ok = res.statusCode >= 200 && res.statusCode < 500;
      if (_disposed) return;
      // Успешный probe подтверждает и сеть устройства, и сервер.
      if (ok) {
        if (!state.deviceOnline || !state.serverReachable) {
          state = state.copyWith(deviceOnline: true, serverReachable: true);
        }
      } else if (state.serverReachable) {
        state = state.copyWith(serverReachable: false);
      }
    } catch (_) {
      if (_disposed) return;
      if (state.serverReachable) {
        state = state.copyWith(serverReachable: false);
      }
    }
  }

  /// Принудительно перепроверить сеть (после всплывашки / возврата в приложение).
  Future<void> refreshConnectivity() => _probeReachable();

  @override
  void dispose() {
    _disposed = true;
    _deviceSub?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }
}
