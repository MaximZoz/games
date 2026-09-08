/// Гистерезис сети: короткий обрыв или один таймаут не должны
/// сразу показывать «нет интернета».
///
/// Авто-офлайн больше не включаем: только помечаем, что сеть плохая,
/// чтобы UI мог предложить офлайн.
class OfflineReachability {
  OfflineReachability({
    required this.deviceOnline,
    required this.serverReachable,
  });

  /// Сколько подряд неудачных probe нужно, чтобы снять serverReachable.
  static const failStreakToOffline = 5;

  /// Сколько держать «устройство офлайн» от ОС, прежде чем поверить.
  static const deviceOfflineHold = Duration(seconds: 8);

  static const probeTimeout = Duration(seconds: 6);

  static const healthyProbeInterval = Duration(seconds: 20);

  static const recoveringProbeInterval = Duration(seconds: 4);

  /// Probe дольше этого считаем медленной сетью / VPN.
  static const slowProbeThreshold = Duration(milliseconds: 2500);

  /// Сколько медленных успехов подряд, чтобы предложить офлайн.
  static const slowStreakToOffer = 3;

  bool deviceOnline;
  bool serverReachable;
  int consecutiveFailures = 0;
  int consecutiveSlow = 0;
  bool slowNetwork = false;
  bool deviceOfflinePending = false;

  bool get isAutoOffline => !deviceOnline || !serverReachable;

  bool get networkDegraded => isAutoOffline || slowNetwork;

  /// Пока сеть «хромает» или мы уже без API — проверяем чаще.
  Duration get nextProbeInterval {
    if (consecutiveFailures > 0 || !serverReachable || slowNetwork) {
      return recoveringProbeInterval;
    }
    return healthyProbeInterval;
  }

  /// ОС/браузер сказали «онлайн». Отменяем отложенный офлайн.
  void onDeviceOnline() {
    deviceOfflinePending = false;
    deviceOnline = true;
  }

  /// ОС/браузер сказали «офлайн». Сами ещё не переключаемся.
  void onDeviceOfflineReported() {
    deviceOfflinePending = true;
  }

  /// Hold истёк, ОС всё ещё офлайн — теперь верим.
  void confirmDeviceOffline() {
    if (!deviceOfflinePending) return;
    deviceOfflinePending = false;
    deviceOnline = false;
    consecutiveFailures = failStreakToOffline;
    serverReachable = false;
    slowNetwork = false;
    consecutiveSlow = 0;
  }

  void onProbeSuccess({Duration elapsed = Duration.zero}) {
    consecutiveFailures = 0;
    deviceOfflinePending = false;
    deviceOnline = true;
    serverReachable = true;
    if (elapsed >= slowProbeThreshold) {
      consecutiveSlow += 1;
      if (consecutiveSlow >= slowStreakToOffer) {
        slowNetwork = true;
      }
    } else {
      consecutiveSlow = 0;
      slowNetwork = false;
    }
  }

  /// [immediate] — явная попытка выйти в онлайн (настройки):
  /// один провал сразу считаем офлайном, чтобы показать тост.
  void onProbeFailure({bool immediate = false}) {
    consecutiveFailures += 1;
    consecutiveSlow = 0;
    if (immediate || consecutiveFailures >= failStreakToOffline) {
      if (consecutiveFailures < failStreakToOffline) {
        consecutiveFailures = failStreakToOffline;
      }
      serverReachable = false;
    }
  }
}
