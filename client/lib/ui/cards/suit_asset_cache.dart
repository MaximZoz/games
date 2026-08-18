import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:multigames_client/games/durak/card.dart';

/// PNG мастей в memory-кэше — как [FlagAssetCache] для флагов.
///
/// Системный emoji/unicode-шрифт на Web часто даёт «тофу» (□) для ♥♦♣♠;
/// ассеты грузятся из бандла и рисуются через [ui.Image].
class SuitAssetCache {
  SuitAssetCache._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _failed = {};
  static final Map<String, Future<ui.Image?>> _inflight = {};

  static String assetPath(Suit suit) => 'assets/suits/${suit.name}.png';

  static ui.Image? imageFor(Suit suit) => _images[suit.name];

  static bool has(Suit suit) => _images.containsKey(suit.name);

  static Future<ui.Image?> load(Suit suit) {
    final key = suit.name;
    final cached = _images[key];
    if (cached != null) return Future.value(cached);
    if (_failed.contains(key)) return Future.value(null);
    return _inflight.putIfAbsent(key, () => _loadKey(key));
  }

  static Future<ui.Image?> _loadKey(String key) async {
    try {
      final data = await rootBundle.load('assets/suits/$key.png');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _images[key] = frame.image;
      return frame.image;
    } catch (_) {
      _failed.add(key);
      return null;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<void> preloadAll() async {
    await Future.wait(Suit.values.map(load));
  }
}
