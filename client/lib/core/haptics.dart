import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Короткие хаптики только для алертов: уведомления, ваш ход, таймер.
enum HapticKind {
  notify,
  yourTurn,
  timerMark,
  timerSecond,
}

abstract final class Haptics {
  static final HapticsController instance = HapticsController();

  static void play(HapticKind kind) => instance.play(kind);

  static void setEnabled(bool enabled) => instance.setEnabled(enabled);

  @visibleForTesting
  static void reset() {
    instance.reset();
    HapticsController.debugOnPlay = null;
  }
}

class HapticsController {
  HapticsController({
    this.debounce = const Duration(milliseconds: 80),
  });

  final Duration debounce;

  bool _enabled = true;
  DateTime? _lastAt;
  HapticKind? _lastKind;

  bool get enabled => _enabled;

  @visibleForTesting
  static const yourTurnDebounce = Duration(milliseconds: 900);

  @visibleForTesting
  static void Function(HapticKind kind)? debugOnPlay;

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
}
