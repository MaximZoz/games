import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sfx_html_stub.dart' if (dart.library.html) 'sfx_html_web.dart' as html_sfx;

/// Короткий набор эффектов. Сэмплы — Kenney Interface Sounds (CC0),
/// плюс голосовое «Уно!».
enum SfxId {
  uiTap,
  notify,
  cardDraw,
  cardPlay,
  cardLand,
  unoCall,
  unoSpecial,
  chip,
  place,
  hit,
  miss,
  sink,
  win,
  coins,
  deny,
  tick,
  yourTurn,
}

abstract final class Sfx {
  static final SfxController instance = SfxController();

  static void play(SfxId id) => instance.play(id);

  static void setEnabled(bool enabled) => instance.setEnabled(enabled);
}

class SfxController {
  SfxController({
    this.debounce = const Duration(milliseconds: 80),
  });

  final Duration debounce;

  @visibleForTesting
  static const assetPaths = <SfxId, String>{
    SfxId.uiTap: 'assets/sfx/ui_tap.wav',
    SfxId.notify: 'assets/sfx/notify.wav',
    SfxId.cardDraw: 'assets/sfx/card_draw.wav',
    SfxId.cardPlay: 'assets/sfx/card_play.wav',
    SfxId.cardLand: 'assets/sfx/card_land.wav',
    SfxId.unoCall: 'assets/sfx/uno_call.wav',
    SfxId.unoSpecial: 'assets/sfx/uno_special.wav',
    SfxId.chip: 'assets/sfx/chip.wav',
    SfxId.place: 'assets/sfx/place.wav',
    SfxId.hit: 'assets/sfx/hit.wav',
    SfxId.miss: 'assets/sfx/miss.wav',
    SfxId.sink: 'assets/sfx/sink.wav',
    SfxId.win: 'assets/sfx/win.wav',
    SfxId.coins: 'assets/sfx/coins.wav',
    SfxId.deny: 'assets/sfx/deny.wav',
    SfxId.tick: 'assets/sfx/tick.wav',
    SfxId.yourTurn: 'assets/sfx/your_turn.wav',
  };

  final Map<SfxId, String> _dataUris = {};
  Completer<void>? _preloadDone;
  bool _enabled = true;
  DateTime? _lastAt;
  SfxId? _lastId;

  bool get enabled => _enabled;

  @visibleForTesting
  bool shouldPlay(SfxId id, DateTime now) {
    if (_lastId == id &&
        _lastAt != null &&
        now.difference(_lastAt!) < debounce) {
      return false;
    }
    _lastId = id;
    _lastAt = now;
    return true;
  }

  bool get _inWidgetTest {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding');
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled) warmup();
  }

  void warmup({bool unlock = true}) {
    if (!_enabled || _inWidgetTest) return;
    if (unlock) html_sfx.htmlSfxUnlock();
    unawaited(_preload());
  }

  void play(SfxId id) {
    if (!_enabled || _inWidgetTest) return;
    final now = DateTime.now();
    if (!shouldPlay(id, now)) return;
    final uri = _dataUris[id];
    if (uri == null) {
      unawaited(_preload().then((_) {
        final ready = _dataUris[id];
        if (ready != null && _enabled) {
          html_sfx.htmlSfxPlay(ready, volume: _volumeFor(id));
        }
      }));
      return;
    }
    html_sfx.htmlSfxPlay(uri, volume: _volumeFor(id));
  }

  static double _volumeFor(SfxId id) {
    switch (id) {
      case SfxId.tick:
        return 0.28;
      case SfxId.yourTurn:
        return 0.5;
      default:
        return 0.55;
    }
  }

  Future<void> _preload() async {
    if (_dataUris.length == assetPaths.length) return;
    final inflight = _preloadDone;
    if (inflight != null) return inflight.future;
    final done = Completer<void>();
    _preloadDone = done;
    try {
      for (final entry in assetPaths.entries) {
        if (_dataUris.containsKey(entry.key)) continue;
        final bytes = await rootBundle.load(entry.value);
        _dataUris[entry.key] =
            'data:audio/wav;base64,${base64Encode(bytes.buffer.asUint8List())}';
      }
      done.complete();
    } catch (_) {
      _preloadDone = null;
      if (!done.isCompleted) done.complete();
    }
  }
}

/// Ink-всплеск Material-кнопок и [InkWell] + короткий клик.
class SfxSplashFactory extends InteractiveInkFeatureFactory {
  const SfxSplashFactory(this.inner);

  final InteractiveInkFeatureFactory inner;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    Sfx.instance.warmup();
    Sfx.play(SfxId.uiTap);
    return inner.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

/// Рост бейджа (чаты / заявки / инвайты) → один notify, не на первом кадре.
abstract final class AlertSfx {
  static bool shouldPlayCountBump(int? previous, int next) {
    return previous != null && next > previous;
  }
}

/// Тик часов на своём ходе и сигнал «ваш ход» (без двойного звука).
abstract final class TurnClockSfx {
  static bool _wasMyTurn = false;
  static int? _lastTickSecond;
  static int? _skipTickSecond;

  @visibleForTesting
  static void Function(SfxId id)? debugOnPlay;

  @visibleForTesting
  static void reset() {
    _wasMyTurn = false;
    _lastTickSecond = null;
    _skipTickSecond = null;
    debugOnPlay = null;
  }

  static void sync({
    required bool isMyTurn,
    required int remainingSeconds,
    required bool clockVisible,
    bool hasTimer = true,
    bool announceOnly = false,
  }) {
    if (!isMyTurn) {
      _wasMyTurn = false;
      _lastTickSecond = null;
      _skipTickSecond = null;
      return;
    }
    if (!_wasMyTurn) {
      _wasMyTurn = true;
      if (!announceOnly) {
        _lastTickSecond = remainingSeconds;
        _skipTickSecond = remainingSeconds;
      }
      _play(SfxId.yourTurn);
      return;
    }
    if (announceOnly) return;
    if (!clockVisible || !hasTimer || remainingSeconds <= 0) return;
    if (_skipTickSecond == remainingSeconds) return;
    if (_lastTickSecond == remainingSeconds) return;
    _lastTickSecond = remainingSeconds;
    _play(SfxId.tick);
  }

  static void _play(SfxId id) {
    debugOnPlay?.call(id);
    Sfx.play(id);
  }
}
