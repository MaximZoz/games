import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:multigames_client/shop/flag_emojis.dart';

/// Декодированные PNG флагов в памяти — работают в офлайне без повторного
/// HTTP-запроса к `/assets/...` (на Flutter Web ассеты грузятся по сети).
class FlagAssetCache {
  FlagAssetCache._();

  static final Map<String, MemoryImage> _images = {};
  static final Set<String> _failed = {};

  static MemoryImage? imageForIso(String iso) => _images[iso.toLowerCase()];

  static bool hasIso(String iso) => _images.containsKey(iso.toLowerCase());

  /// Загрузить один флаг в memory-кэш.
  static Future<MemoryImage?> loadIso(String iso) async {
    final key = iso.toLowerCase().trim();
    if (key.isEmpty) return null;
    final cached = _images[key];
    if (cached != null) return cached;
    if (_failed.contains(key)) return null;
    try {
      final data = await rootBundle.load(countryFlagAssetPath(key));
      final bytes = data.buffer.asUint8List();
      // Проверяем, что PNG реально декодируется.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      final image = MemoryImage(bytes);
      _images[key] = image;
      // Прогреваем ImageCache Flutter.
      final stream = image.resolve(const ImageConfiguration());
      final done = Completer<void>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, sync) {
          if (!done.isCompleted) done.complete();
          stream.removeListener(listener);
        },
        onError: (e, st) {
          if (!done.isCompleted) done.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
      return image;
    } catch (_) {
      _failed.add(key);
      return null;
    }
  }

  /// Все флаги из каталога магазина.
  static Future<void> preloadAll() async {
    final isos = countryFlagsByName.values.map((e) => e.iso).toSet();
    // Параллельно, но небольшими пачками — не забиваем сеть/CPU.
    final list = isos.toList();
    const chunk = 8;
    for (var i = 0; i < list.length; i += chunk) {
      final batch = list.skip(i).take(chunk);
      await Future.wait(batch.map(loadIso));
    }
  }
}
