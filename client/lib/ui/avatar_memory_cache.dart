import 'dart:convert';

import 'package:flutter/painting.dart';

/// Кэш декодированных base64-аватаров для повторного использования во всех
/// экранах (чаты/друзья/админка).
class AvatarMemoryCache {
  AvatarMemoryCache._();

  static final Map<int, MemoryImage> _cache = <int, MemoryImage>{};
  static const int _maxEntries = 220;

  static MemoryImage? fromAvatarValue(String? avatarValue) {
    if (avatarValue == null) return null;
    var raw = avatarValue.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('base64,')) raw = raw.substring(7);
    if (raw.isEmpty) return null;

    final key = Object.hash(raw.length, raw.hashCode);
    final cached = _cache[key];
    if (cached != null) {
      // Освежаем ключ, чтобы самые горячие аватары оставались в кэше дольше.
      _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }

    try {
      final image = MemoryImage(base64Decode(raw));
      _cache[key] = image;
      if (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return image;
    } catch (_) {
      return null;
    }
  }

  static void clear() => _cache.clear();
}
