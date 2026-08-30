import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Короткие хаптики только для алертов: уведомления, ваш ход, таймер.
enum HapticKind {
  notify,
  yourTurn,
  timerMark,
  timerSecond,
}

/// Паттерн мотора: [пауза, вибрация, пауза, вибрация, …] в мс.
///
/// На Android [HapticFeedback.mediumImpact] = KEYBOARD_TAP и часто молчит.
@visibleForTesting
List<int> hapticPatternMs(HapticKind kind) {
  switch (kind) {
    case HapticKind.notify:
      return const [0, 50, 40, 50];
    case HapticKind.yourTurn:
      return const [0, 55];
    case HapticKind.timerMark:
      return const [0, 70];
    case HapticKind.timerSecond:
      return const [0, 30];
  }
}

abstract final class Haptics {
  static final HapticsController instance = HapticsController();

  static void play(HapticKind kind) => instance.play(kind);

  static void setEnabled(bool enabled) => instance.setEnabled(enabled);

  @visibleForTesting
  static void reset() {
    instance.reset();
    HapticsController.debugOnPlay = null;
    HapticsController.debugAndroidVibrate = null;
  }
}

class HapticsController {
  HapticsController({
    this.debounce = const Duration(milliseconds: 80),
    MethodChannel? androidChannel,
  }) : androidChannel = androidChannel ?? const MethodChannel('zozu/haptics');

  final Duration debounce;

  @visibleForTesting
  final MethodChannel androidChannel;

  bool _enabled = true;
  DateTime? _lastAt;
  HapticKind? _lastKind;

  bool get enabled => _enabled;

  @visibleForTesting
  static const yourTurnDebounce = Duration(milliseconds: 900);

  @visibleForTesting
  static void Function(HapticKind kind)? debugOnPlay;

  @visibleForTesting
  static Future<bool> Function(List<int> pattern)? debugAndroidVibrate;

  bool get _inWidgetTest {
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      return name.contains('TestWidgetsFlutterBinding');
    } catch (_) {
      return true;
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled) {
      _lastAt = null;
      _lastKind = null;
    }
  }

  void reset() {
    _lastAt = null;
    _lastKind = null;
  }

  bool shouldPlay(HapticKind kind, DateTime now) {
    final window = kind == HapticKind.yourTurn ? yourTurnDebounce : debounce;
    if (_lastKind == kind &&
        _lastAt != null &&
        now.difference(_lastAt!) < window) {
      return false;
    }
    _lastKind = kind;
    _lastAt = now;
    return true;
  }

  void play(HapticKind kind) {
    if (!_enabled) return;
    final now = DateTime.now();
    if (!shouldPlay(kind, now)) return;
    debugOnPlay?.call(kind);
    if (_inWidgetTest) return;
    unawaited(_impact(kind));
  }

  Future<void> _impact(HapticKind kind) async {
    final pattern = hapticPatternMs(kind);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await _androidVibrate(pattern)) return;
      await HapticFeedback.vibrate();
      return;
    }
    switch (kind) {
      case HapticKind.notify:
      case HapticKind.yourTurn:
        await HapticFeedback.mediumImpact();
      case HapticKind.timerMark:
        await HapticFeedback.heavyImpact();
      case HapticKind.timerSecond:
        await HapticFeedback.lightImpact();
    }
  }

  Future<bool> _androidVibrate(List<int> pattern) async {
    final injected = debugAndroidVibrate;
    if (injected != null) return injected(pattern);
    try {
      await androidChannel.invokeMethod<void>('vibrate', {'pattern': pattern});
      return true;
    } catch (_) {
      return false;
    }
  }
}
