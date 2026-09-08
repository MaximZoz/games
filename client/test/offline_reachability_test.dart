import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/offline_reachability.dart';

void main() {
  group('OfflineReachability', () {
    OfflineReachability online() => OfflineReachability(
          deviceOnline: true,
          serverReachable: true,
        );

    test('один провал probe не выключает онлайн', () {
      final r = online();
      r.onProbeFailure();
      expect(r.serverReachable, isTrue);
      expect(r.deviceOnline, isTrue);
      expect(r.isAutoOffline, isFalse);
      expect(r.consecutiveFailures, 1);
      expect(r.nextProbeInterval, OfflineReachability.recoveringProbeInterval);
    });

    test('два провала подряд ещё не снимают сервер', () {
      final r = online();
      r.onProbeFailure();
      r.onProbeFailure();
      expect(r.serverReachable, isTrue);
      expect(r.isAutoOffline, isFalse);
    });

    test('пять провалов подряд снимают сервер', () {
      final r = online();
      for (var i = 0; i < OfflineReachability.failStreakToOffline; i++) {
        r.onProbeFailure();
      }
      expect(r.serverReachable, isFalse);
      expect(r.isAutoOffline, isTrue);
      expect(r.nextProbeInterval, OfflineReachability.recoveringProbeInterval);
    });

    test('три медленных успеха помечают медленную сеть', () {
      final r = online();
      for (var i = 0; i < OfflineReachability.slowStreakToOffer; i++) {
        r.onProbeSuccess(elapsed: OfflineReachability.slowProbeThreshold);
      }
      expect(r.serverReachable, isTrue);
      expect(r.slowNetwork, isTrue);
      expect(r.networkDegraded, isTrue);
    });

    test('успех после одного провала оставляет онлайн', () {
      final r = online();
      r.onProbeFailure();
      r.onProbeSuccess();
      expect(r.serverReachable, isTrue);
      expect(r.consecutiveFailures, 0);
      expect(r.isAutoOffline, isFalse);
      expect(r.nextProbeInterval, OfflineReachability.healthyProbeInterval);
    });

    test('первый успех сразу выключает офлайн', () {
      final r = OfflineReachability(
        deviceOnline: false,
        serverReachable: false,
      )..consecutiveFailures = 4;
      r.onProbeSuccess();
      expect(r.deviceOnline, isTrue);
      expect(r.serverReachable, isTrue);
      expect(r.consecutiveFailures, 0);
      expect(r.deviceOfflinePending, isFalse);
      expect(r.isAutoOffline, isFalse);
    });

    test('короткий offline-ивент ОС не переключает режим', () {
      final r = online();
      r.onDeviceOfflineReported();
      expect(r.deviceOfflinePending, isTrue);
      expect(r.deviceOnline, isTrue);
      expect(r.serverReachable, isTrue);
      expect(r.isAutoOffline, isFalse);

      r.onDeviceOnline();
      expect(r.deviceOfflinePending, isFalse);
      expect(r.deviceOnline, isTrue);
      expect(r.isAutoOffline, isFalse);
    });

    test('устойчивый offline ОС подтверждается после hold', () {
      final r = online();
      r.onDeviceOfflineReported();
      r.confirmDeviceOffline();
      expect(r.deviceOnline, isFalse);
      expect(r.serverReachable, isFalse);
      expect(r.deviceOfflinePending, isFalse);
      expect(r.isAutoOffline, isTrue);
    });

    test('confirm без pending ничего не меняет', () {
      final r = online();
      r.confirmDeviceOffline();
      expect(r.deviceOnline, isTrue);
      expect(r.serverReachable, isTrue);
    });

    test('явный tryGoOnline падает с первого провала', () {
      final r = online();
      r.onProbeFailure(immediate: true);
      expect(r.serverReachable, isFalse);
      expect(r.consecutiveFailures, OfflineReachability.failStreakToOffline);
      expect(r.isAutoOffline, isTrue);
    });

    test('после офлайна интервал остаётся коротким', () {
      final r = online();
      for (var i = 0; i < OfflineReachability.failStreakToOffline + 1; i++) {
        r.onProbeFailure();
      }
      expect(r.nextProbeInterval, OfflineReachability.recoveringProbeInterval);
    });
  });

  group('OfflineModeState', () {
    test('ручной офлайн действует даже при сети', () {
      const s = OfflineModeState(
        preference: OfflinePreference.offline,
        deviceOnline: true,
        serverReachable: true,
      );
      expect(s.isOffline, isTrue);
      expect(s.hasNetwork, isTrue);
      expect(s.onlineUnavailableReason, OnlineUnavailableReason.none);
    });

    test('нет сети не включает офлайн, но предлагает его', () {
      const s = OfflineModeState(
        preference: OfflinePreference.online,
        deviceOnline: false,
        serverReachable: false,
      );
      expect(s.isOffline, isFalse);
      expect(s.hasNetwork, isFalse);
      expect(s.shouldOfferOffline, isTrue);
      expect(s.onlineUnavailableReason, OnlineUnavailableReason.noInternet);
    });

    test('сервер недоступен не включает офлайн, но предлагает его', () {
      const s = OfflineModeState(
        preference: OfflinePreference.online,
        deviceOnline: true,
        serverReachable: false,
      );
      expect(s.isOffline, isFalse);
      expect(s.shouldOfferOffline, isTrue);
      expect(
        s.onlineUnavailableReason,
        OnlineUnavailableReason.serverUnreachable,
      );
    });

    test('медленная сеть тоже предлагает офлайн', () {
      const s = OfflineModeState(
        preference: OfflinePreference.online,
        deviceOnline: true,
        serverReachable: true,
        slowNetwork: true,
      );
      expect(s.isOffline, isFalse);
      expect(s.hasNetwork, isTrue);
      expect(s.shouldOfferOffline, isTrue);
    });

    test('онлайн если сеть и сервер есть', () {
      const s = OfflineModeState(
        preference: OfflinePreference.online,
        deviceOnline: true,
        serverReachable: true,
      );
      expect(s.isOffline, isFalse);
      expect(s.hasNetwork, isTrue);
    });
  });
}
