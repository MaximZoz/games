import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
    this.createPlayers = true,
  });

  final Duration debounce;
  final bool createPlayers;

  static const _poolSize = 6;
  static const _assets = <SfxId, String>{
    SfxId.uiTap: 'sfx/ui_tap.wav',
    SfxId.cardPlay: 'sfx/card_play.wav',
    SfxId.cardDraw: 'sfx/card_draw.wav',
    SfxId.cardDeal: 'sfx/card_deal.wav',
    SfxId.cardSpecial: 'sfx/card_special.wav',
    SfxId.unoCall: 'sfx/uno_call.wav',
    SfxId.colorPick: 'sfx/color_pick.wav',
    SfxId.chip: 'sfx/chip.wav',
    SfxId.place: 'sfx/place.wav',
    SfxId.shoot: 'sfx/shoot.wav',
    SfxId.hit: 'sfx/hit.wav',
    SfxId.miss: 'sfx/miss.wav',
    SfxId.win: 'sfx/win.wav',
    SfxId.coins: 'sfx/coins.wav',
    SfxId.deny: 'sfx/deny.wav',
  };

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _enabled = true;
  bool _warming = false;
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
    if (enabled) {
      warmup();
    } else {
      for (final player in _pool) {
        unawaited(player.stop());
      }
    }
  }

  void warmup() {
    if (_warming || !_enabled || _inWidgetTest || !createPlayers) return;
    _warming = true;
    unawaited(_safeEnsurePool());
  }

  void play(SfxId id) {
    if (!_enabled || _inWidgetTest || !createPlayers) return;
    final now = DateTime.now();
    if (!shouldPlay(id, now)) return;
    final asset = _assets[id];
    if (asset == null) return;
    unawaited(_playAsset(asset));
  }

  Future<void> _safeEnsurePool() async {
    try {
      await _ensurePool();
    } catch (_) {}
  }

  Future<void> _playAsset(String asset) async {
    try {
      await _ensurePool();
      if (_pool.isEmpty) return;
      final player = _pool[_next % _pool.length];
      _next++;
      await player.stop();
      await player.play(AssetSource(asset), volume: 0.72);
    } catch (_) {}
  }

  Future<void> _ensurePool() async {
    if (_pool.isNotEmpty) return;
    for (var i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      try {
        await player.setPlayerMode(PlayerMode.lowLatency);
      } catch (_) {}
      try {
        await player.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      _pool.add(player);
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
