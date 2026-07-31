import 'dart:convert';

import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Дисковый снимок данных, нужных в офлайне (магазин, инвентарь, аватар-рамка…).
class OfflineDiskCache {
  OfflineDiskCache._();

  static String _k(String userId, String name) => 'offline_cache_${userId}_$name';

  static Future<void> saveShop(String userId, List<ShopItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'shop'),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<ShopItem>?> loadShop(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'shop'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return list
          .whereType<Map>()
          .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveInventory(
    String userId,
    List<InventoryItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'inventory'),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<InventoryItem>?> loadInventory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'inventory'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return list
          .whereType<Map>()
          .map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCapabilities(
    String userId,
    InventoryCapabilities caps,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k(userId, 'capabilities'), jsonEncode(caps.toJson()));
  }

  static Future<InventoryCapabilities?> loadCapabilities(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'capabilities'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return InventoryCapabilities.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGameSettings(
    String userId,
    UserGameSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'game_settings'),
      jsonEncode(settings.toJson()),
    );
  }

  static Future<UserGameSettings?> loadGameSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'game_settings'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return UserGameSettings.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAchievements(
    String userId,
    List<AchievementItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'achievements'),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<AchievementItem>?> loadAchievements(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'achievements'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return list
          .whereType<Map>()
          .map((e) => AchievementItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCollectionIncome(
    String userId,
    CollectionIncomeInfo info,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'collection_income'),
      jsonEncode(info.toJson()),
    );
  }

  static Future<CollectionIncomeInfo?> loadCollectionIncome(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'collection_income'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return CollectionIncomeInfo.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDailyReward(
    String userId,
    DailyRewardStatus status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k(userId, 'daily_reward'),
      jsonEncode(status.toJson()),
    );
  }

  static Future<DailyRewardStatus?> loadDailyReward(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(userId, 'daily_reward'));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return DailyRewardStatus.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }
}
