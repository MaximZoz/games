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

/// Сводка режима для UI и репозиториев.
class OfflineModeState {
  const OfflineModeState({
    required this.preference,
    required this.hasNetwork,
  });

  final OfflinePreference preference;
  final bool hasNetwork;

  /// Эффективный офлайн: ручной офлайн или нет сети.
  bool get isOffline =>
      preference == OfflinePreference.offline || !hasNetwork;

  OfflineModeState copyWith({
    OfflinePreference? preference,
    bool? hasNetwork,
  }) {
    return OfflineModeState(
      preference: preference ?? this.preference,
      hasNetwork: hasNetwork ?? this.hasNetwork,
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
          hasNetwork: readDeviceOnline(),
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
      state = state.copyWith(hasNetwork: online);
      if (online) {
        unawaited(_probeReachable());
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
      hasNetwork: readDeviceOnline(),
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

  /// Лёгкая проверка доступности API.
  Future<void> _probeReachable() async {
    if (state.preference == OfflinePreference.offline) {
      // Ручной офлайн: сеть не важна для режима, но обновим флаг.
    }
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/start'))
          .timeout(const Duration(seconds: 4));
      final ok = res.statusCode >= 200 && res.statusCode < 500;
      if (_disposed) return;
      if (state.hasNetwork != ok) {
        state = state.copyWith(hasNetwork: ok);
      }
    } catch (_) {
      if (_disposed) return;
      if (state.hasNetwork) {
        state = state.copyWith(hasNetwork: false);
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
