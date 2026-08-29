/// Гистерезис авто-онлайн/офлайн: короткий обрыв или один таймаут
/// не должны сразу прятать чаты и лобби.
///
/// В офлайн — только после устойчивого обрыва.
/// В онлайн — сразу после первого успешного probe.
class OfflineReachability {
  OfflineReachability({
    required this.deviceOnline,
    required this.serverReachable,
  });

  /// Сколько подряд неудачных probe нужно, чтобы снять serverReachable.
  static const failStreakToOffline = 2;

  /// Сколько держать «устройство офлайн» от ОС, прежде чем поверить.
  static const deviceOfflineHold = Duration(seconds: 2);

  static const probeTimeout = Duration(seconds: 6);

  static const healthyProbeInterval = Duration(seconds: 20);

  static const recoveringProbeInterval = Duration(seconds: 4);

  bool deviceOnline;
  bool serverReachable;
  int consecutiveFailures = 0;
  bool deviceOfflinePending = false;

  bool get isAutoOffline => !deviceOnline || !serverReachable;

  /// Пока сеть «хромает» или мы уже офлайн — проверяем чаще.
  Duration get nextProbeInterval {
    if (consecutiveFailures > 0 || !serverReachable) {
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
  }

  void onProbeSuccess() {
    consecutiveFailures = 0;
    deviceOfflinePending = false;
    deviceOnline = true;
    serverReachable = true;
  }

  /// [immediate] — явная попытка выйти в онлайн (настройки):
  /// один провал сразу считаем офлайном, чтобы показать тост.
  void onProbeFailure({bool immediate = false}) {
    consecutiveFailures += 1;
    if (immediate || consecutiveFailures >= failStreakToOffline) {
      if (consecutiveFailures < failStreakToOffline) {
        consecutiveFailures = failStreakToOffline;
      }
      serverReachable = false;
    }
  }
}
