import 'dart:convert';

import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Дисковый + memory-снимок данных для офлайна.
///
/// Memory нужен на ту же сессию: при переключении офлайн FutureProvider
/// пересобирается и без last-known каталог на миг/насовсем становится пустым,
/// если диск ещё не успел записаться или localStorage недоступен.
class OfflineDiskCache {
  OfflineDiskCache._();

  static final Map<String, List<ShopItem>> _memShop = {};
  static final Map<String, List<InventoryItem>> _memInventory = {};
  static final Map<String, InventoryCapabilities> _memCapabilities = {};
  static final Map<String, UserGameSettings> _memGameSettings = {};
  static final Map<String, List<AchievementItem>> _memAchievements = {};
  static final Map<String, List<AchievementItem>> _memTasks = {};
  static final Map<String, CollectionIncomeInfo> _memCollectionIncome = {};
  static final Map<String, DailyRewardStatus> _memDailyReward = {};

  static String _k(String userId, String name) => 'offline_cache_${userId}_$name';

  static String _settingsCacheKey(String userId, String gameType) {
    final gt = gameType.trim().isEmpty ? 'tictactoe' : gameType.trim();
    return '${userId}__$gt';
  }

  static Future<void> saveShop(String userId, List<ShopItem> items) async {
    // Не затираем хороший кэш пустым ответом API.
    if (items.isEmpty && (_memShop[userId]?.isNotEmpty ?? false)) return;
    _memShop[userId] = List<ShopItem>.from(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'shop'),
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<List<ShopItem>?> loadShop(String userId) async {
    final mem = _memShop[userId];
    if (mem != null && mem.isNotEmpty) return List<ShopItem>.from(mem);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId, 'shop'));
      if (raw == null || raw.isEmpty) return mem;
      final list = jsonDecode(raw);
      if (list is! List) return mem;
      final loaded = list
          .whereType<Map>()
          .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (loaded.isNotEmpty) _memShop[userId] = loaded;
      return loaded;
    } catch (_) {
      return mem;
    }
  }

  static Future<void> saveInventory(
    String userId,
    List<InventoryItem> items,
  ) async {
    _memInventory[userId] = List<InventoryItem>.from(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'inventory'),
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<List<InventoryItem>?> loadInventory(String userId) async {
    final mem = _memInventory[userId];
    if (mem != null && mem.isNotEmpty) {
      return List<InventoryItem>.from(mem);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId, 'inventory'));
      if (raw == null || raw.isEmpty) return mem;
      final list = jsonDecode(raw);
      if (list is! List) return mem;
      final loaded = list
          .whereType<Map>()
          .map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (loaded.isNotEmpty) _memInventory[userId] = loaded;
      return loaded;
    } catch (_) {
      return mem;
    }
  }

  static Future<void> saveCapabilities(
    String userId,
    InventoryCapabilities caps,
  ) async {
    _memCapabilities[userId] = caps;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'capabilities'),
        jsonEncode(caps.toJson()),
      );
    } catch (_) {}
  }

  static Future<InventoryCapabilities?> loadCapabilities(String userId) async {
    final mem = _memCapabilities[userId];
    if (mem != null) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId, 'capabilities'));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final loaded =
          InventoryCapabilities.fromJson(Map<String, dynamic>.from(map));
      _memCapabilities[userId] = loaded;
      return loaded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGameSettings(
    String userId,
    UserGameSettings settings, {
    String? gameType,
  }) async {
    final gt = (gameType ?? settings.gameType).trim().isEmpty
        ? 'tictactoe'
        : (gameType ?? settings.gameType).trim();
    final key = _settingsCacheKey(userId, gt);
    _memGameSettings[key] = settings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'game_settings_$gt'),
        jsonEncode(settings.toJson()),
      );
      // Legacy-ключ: для tictactoe пишем и старый слот (миграция кэша).
      if (gt == 'tictactoe') {
        await prefs.setString(
          _k(userId, 'game_settings'),
          jsonEncode(settings.toJson()),
        );
      }
    } catch (_) {}
  }

  static Future<UserGameSettings?> loadGameSettings(
    String userId, {
    String gameType = 'tictactoe',
  }) async {
    final gt = gameType.trim().isEmpty ? 'tictactoe' : gameType.trim();
    final key = _settingsCacheKey(userId, gt);
    final mem = _memGameSettings[key];
    if (mem != null) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_k(userId, 'game_settings_$gt'));
      // Fallback на старый единый ключ только для крестиков.
      if ((raw == null || raw.isEmpty) && gt == 'tictactoe') {
        raw = prefs.getString(_k(userId, 'game_settings'));
      }
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final loaded = UserGameSettings.fromJson(Map<String, dynamic>.from(map));
      _memGameSettings[key] = loaded;
      return loaded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAchievements(
    String userId,
    List<AchievementItem> items,
  ) async {
    final frames = filterAchievementItems(items);
    _memAchievements[userId] = List<AchievementItem>.from(frames);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'achievements'),
        jsonEncode(frames.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static List<AchievementItem>? _decodeRewardList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final list = jsonDecode(raw);
    if (list is! List) return null;
    return list
        .whereType<Map>()
        .map((e) => AchievementItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<AchievementItem>?> loadAchievements(String userId) async {
    final mem = _memAchievements[userId];
    if (mem != null && mem.isNotEmpty) {
      return filterAchievementItems(mem);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final loaded = _decodeRewardList(prefs.getString(_k(userId, 'achievements')));
      if (loaded == null) {
        return mem == null ? null : filterAchievementItems(mem);
      }
      final frames = filterAchievementItems(loaded);
      if (frames.isNotEmpty) _memAchievements[userId] = frames;
      return frames;
    } catch (_) {
      return mem == null ? null : filterAchievementItems(mem);
    }
  }

  static Future<void> saveTasks(
    String userId,
    List<AchievementItem> items,
  ) async {
    final tasks = filterTaskItems(items);
    _memTasks[userId] = List<AchievementItem>.from(tasks);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'tasks'),
        jsonEncode(tasks.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<List<AchievementItem>?> loadTasks(String userId) async {
    final mem = _memTasks[userId];
    if (mem != null && mem.isNotEmpty) {
      return filterTaskItems(mem);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final loaded = _decodeRewardList(prefs.getString(_k(userId, 'tasks')));
      if (loaded != null) {
        final tasks = filterTaskItems(loaded);
        if (tasks.isNotEmpty) _memTasks[userId] = tasks;
        return tasks;
      }
      // Старый кэш держал задания вместе с достижениями.
      final legacy = _decodeRewardList(prefs.getString(_k(userId, 'achievements')));
      if (legacy == null) return mem;
      final extracted = filterTaskItems(legacy);
      if (extracted.isNotEmpty) _memTasks[userId] = extracted;
      return extracted.isEmpty ? mem : extracted;
    } catch (_) {
      return mem == null ? null : filterTaskItems(mem);
    }
  }

  static Future<void> saveCollectionIncome(
    String userId,
    CollectionIncomeInfo info,
  ) async {
    _memCollectionIncome[userId] = info;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'collection_income'),
        jsonEncode(info.toJson()),
      );
    } catch (_) {}
  }

  static Future<CollectionIncomeInfo?> loadCollectionIncome(
    String userId,
  ) async {
    final mem = _memCollectionIncome[userId];
    if (mem != null) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId, 'collection_income'));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final loaded =
          CollectionIncomeInfo.fromJson(Map<String, dynamic>.from(map));
      _memCollectionIncome[userId] = loaded;
      return loaded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDailyReward(
    String userId,
    DailyRewardStatus status,
  ) async {
    _memDailyReward[userId] = status;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _k(userId, 'daily_reward'),
        jsonEncode(status.toJson()),
      );
    } catch (_) {}
  }

  static Future<DailyRewardStatus?> loadDailyReward(String userId) async {
    final mem = _memDailyReward[userId];
    if (mem != null) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId, 'daily_reward'));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final loaded = DailyRewardStatus.fromJson(Map<String, dynamic>.from(map));
      _memDailyReward[userId] = loaded;
      return loaded;
    } catch (_) {
      return null;
    }
  }
}
