import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'sfx_html_stub.dart' if (dart.library.html) 'sfx_html_web.dart' as html_sfx;

/// Короткие эффекты UI и игр. Выключенные / тестовые вызовы — no-op.
enum SfxId {
  uiTap,
  cardPlay,
  cardDraw,
  cardDeal,
  cardSpecial,
  unoCall,
  colorPick,
  chip,
  place,
  shoot,
  hit,
  miss,
  win,
  coins,
  deny,
}

abstract final class Sfx {
  static final SfxController instance = SfxController();

  static void play(SfxId id) => instance.play(id);

  static void setEnabled(bool enabled) => instance.setEnabled(enabled);
}

class SfxController {
  SfxController({
    this.debounce = const Duration(milliseconds: 55),
  });

  final Duration debounce;

  static const _assets = <SfxId, String>{
    SfxId.uiTap: 'assets/sfx/ui_tap.wav',
    SfxId.cardPlay: 'assets/sfx/card_play.wav',
    SfxId.cardDraw: 'assets/sfx/card_draw.wav',
    SfxId.cardDeal: 'assets/sfx/card_deal.wav',
    SfxId.cardSpecial: 'assets/sfx/card_special.wav',
    SfxId.unoCall: 'assets/sfx/uno_call.wav',
    SfxId.colorPick: 'assets/sfx/color_pick.wav',
    SfxId.chip: 'assets/sfx/chip.wav',
    SfxId.place: 'assets/sfx/place.wav',
    SfxId.shoot: 'assets/sfx/shoot.wav',
    SfxId.hit: 'assets/sfx/hit.wav',
    SfxId.miss: 'assets/sfx/miss.wav',
    SfxId.win: 'assets/sfx/win.wav',
    SfxId.coins: 'assets/sfx/coins.wav',
    SfxId.deny: 'assets/sfx/deny.wav',
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
          html_sfx.htmlSfxPlay(ready);
        }
      }));
      return;
    }
    html_sfx.htmlSfxPlay(uri);
  }

  Future<void> _preload() async {
    if (_dataUris.length == _assets.length) return;
    final inflight = _preloadDone;
    if (inflight != null) return inflight.future;
    final done = Completer<void>();
    _preloadDone = done;
    try {
      for (final entry in _assets.entries) {
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

/// Проигрывает [id] один раз при появлении в дереве (анимация клетки, салют).
class SfxOnInit extends StatefulWidget {
  const SfxOnInit({super.key, required this.id, required this.child});

  final SfxId id;
  final Widget child;

  @override
  State<SfxOnInit> createState() => _SfxOnInitState();
}

class _SfxOnInitState extends State<SfxOnInit> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Sfx.play(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Ink-всплеск Material-кнопок и [InkWell] + короткий UI-тик.
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
