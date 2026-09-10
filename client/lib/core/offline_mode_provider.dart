import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/connectivity_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/connectivity_web.dart'
    if (dart.library.js_interop) 'package:multigames_client/core/connectivity_web.dart';
import 'package:multigames_client/core/offline_reachability.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyOfflinePreference = 'offline_mode_preference';
const _keyLastOfflineOfferMs = 'offline_mode_last_offer_ms';

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
    this.slowNetwork = false,
  });

  final OfflinePreference preference;

  /// Браузер/ОС считают устройство онлайн.
  final bool deviceOnline;

  /// Probe `/api/start` успешен.
  final bool serverReachable;

  /// Сеть есть, но ответы стабильно медленные (VPN / плохой канал).
  final bool slowNetwork;

  /// Можно работать с API.
  bool get hasNetwork => deviceOnline && serverReachable;

  /// Офлайн только по явному выбору пользователя — сеть сама не переключает.
  bool get isOffline => preference == OfflinePreference.offline;

  /// Долго нет сети или она слишком медленная — можно предложить офлайн.
  bool get shouldOfferOffline =>
      preference == OfflinePreference.online &&
      (!hasNetwork || slowNetwork);

  OnlineUnavailableReason get onlineUnavailableReason {
    if (!deviceOnline) return OnlineUnavailableReason.noInternet;
    if (!serverReachable) return OnlineUnavailableReason.serverUnreachable;
    return OnlineUnavailableReason.none;
  }

  OfflineModeState copyWith({
    OfflinePreference? preference,
    bool? deviceOnline,
    bool? serverReachable,
    bool? slowNetwork,
  }) {
    return OfflineModeState(
      preference: preference ?? this.preference,
      deviceOnline: deviceOnline ?? this.deviceOnline,
      serverReachable: serverReachable ?? this.serverReachable,
      slowNetwork: slowNetwork ?? this.slowNetwork,
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
    _reachability = OfflineReachability(
      deviceOnline: state.deviceOnline,
      serverReachable: state.serverReachable,
    );
    _resumeObserver = _AppResumeObserver(_onAppResumed);
    WidgetsBinding.instance.addObserver(_resumeObserver);
    _init();
  }

  late final OfflineReachability _reachability;
  late final _AppResumeObserver _resumeObserver;
  StreamSubscription<bool>? _deviceSub;
  Timer? _probeTimer;
  Timer? _deviceOfflineHold;
  int _probeGen = 0;
  bool _disposed = false;

  Future<void> _init() async {
    await _loadPreference();
    _deviceSub = deviceOnlineStream().listen(_onDeviceOnlineChanged);
    unawaited(_probeReachable());
  }

  void _onDeviceOnlineChanged(bool online) {
    if (_disposed) return;
    _deviceOfflineHold?.cancel();
    _deviceOfflineHold = null;
    if (online) {
      _reachability.onDeviceOnline();
      _publishReachability();
      unawaited(_probeReachable());
      return;
    }
    _reachability.onDeviceOfflineReported();
    _deviceOfflineHold = Timer(OfflineReachability.deviceOfflineHold, () {
      if (_disposed) return;
      _reachability.confirmDeviceOffline();
      _publishReachability();
      _scheduleNextProbe();
    });
  }

  void _onAppResumed() {
    if (_disposed) return;
    if (readDeviceOnline()) {
      _deviceOfflineHold?.cancel();
      _deviceOfflineHold = null;
      _reachability.onDeviceOnline();
      _publishReachability();
    }
    unawaited(_probeReachable());
  }

  void _publishReachability() {
    if (_disposed) return;
    if (state.deviceOnline == _reachability.deviceOnline &&
        state.serverReachable == _reachability.serverReachable &&
        state.slowNetwork == _reachability.slowNetwork) {
      return;
    }
    state = state.copyWith(
      deviceOnline: _reachability.deviceOnline,
      serverReachable: _reachability.serverReachable,
      slowNetwork: _reachability.slowNetwork,
    );
  }

  static const offerCooldown = Duration(hours: 6);

  /// Слот на всплывашку: не чаще [offerCooldown] и только при плохой сети.
  Future<bool> consumeOfflineOffer() async {
    if (!state.shouldOfferOffline) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastOfflineOfferMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last > 0 && now - last < offerCooldown.inMilliseconds) {
      return false;
    }
    await prefs.setInt(_keyLastOfflineOfferMs, now);
    return true;
  }

  void _scheduleNextProbe() {
    _probeTimer?.cancel();
    if (_disposed) return;
    _probeTimer = Timer(_reachability.nextProbeInterval, () {
      unawaited(_probeReachable());
    });
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOfflinePreference);
    final preference = raw == 'offline'
        ? OfflinePreference.offline
        : OfflinePreference.online;
    if (_disposed) return;
    final deviceOnline = readDeviceOnline();
    if (deviceOnline) {
      _reachability.onDeviceOnline();
    }
    state = state.copyWith(
      preference: preference,
      deviceOnline: _reachability.deviceOnline,
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
    await _probeReachable(immediateFailure: true);
    if (_disposed) return OnlineUnavailableReason.serverUnreachable;
    final reason = state.onlineUnavailableReason;
    if (reason != OnlineUnavailableReason.none) {
      return reason;
    }
    await setPreference(OfflinePreference.online);
    return null;
  }

  /// Лёгкая проверка доступности API.
  Future<void> _probeReachable({bool immediateFailure = false}) async {
    final gen = ++_probeGen;
    final osOnline = readDeviceOnline();
    // Нативный stub всегда online; на web — navigator.onLine.
    if (!osOnline && !immediateFailure) {
      // Короткий offline-ивент: HTTP всё равно упадёт, ждём hold.
      _scheduleNextProbe();
      return;
    }
    if (!osOnline && !_reachability.deviceOnline) {
      _reachability.onProbeFailure(immediate: immediateFailure);
      if (gen != _probeGen || _disposed) return;
      _publishReachability();
      _scheduleNextProbe();
      return;
    }
    try {
      final started = DateTime.now();
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/start'))
          .timeout(OfflineReachability.probeTimeout);
      if (gen != _probeGen || _disposed) return;
      final ok = res.statusCode >= 200 && res.statusCode < 500;
      if (ok) {
        _reachability.onProbeSuccess(
          elapsed: DateTime.now().difference(started),
        );
      } else {
        _reachability.onProbeFailure(immediate: immediateFailure);
      }
      _publishReachability();
    } catch (_) {
      if (gen != _probeGen || _disposed) return;
      _reachability.onProbeFailure(immediate: immediateFailure);
      _publishReachability();
    }
    if (gen != _probeGen || _disposed) return;
    _scheduleNextProbe();
  }

  /// Принудительно перепроверить сеть (после всплывашки / возврата в приложение).
  Future<void> refreshConnectivity() => _probeReachable();

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(_resumeObserver);
    _deviceSub?.cancel();
    _probeTimer?.cancel();
    _deviceOfflineHold?.cancel();
    super.dispose();
  }
}

class _AppResumeObserver with WidgetsBindingObserver {
  _AppResumeObserver(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
