import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/shop/emoji_asset_catalog.dart';
import 'package:multigames_client/shop/flag_asset_cache.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';

/// Прогрев данных и локальных ассетов для бесшовного офлайна.
///
/// Запускается при входе / старте приложения в онлайне и при переходе
/// офлайн → онлайн. Каталог/инвентарь/настройки пишутся на диск; аватар и
/// Lottie/флаги — в memory/asset cache.
class OfflineWarmup {
  OfflineWarmup._();

  static bool _running = false;

  static Future<void> run(Ref ref) async {
    if (_running) return;
    if (ref.read(isOfflineProvider)) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    _running = true;
    try {
      try {
        await ref.read(authStateProvider.notifier).refresh();
      } catch (_) {}

      final freshUser = ref.read(authStateProvider).valueOrNull ?? user;
      final uid = freshUser.id;
      await _precacheAvatar(freshUser.avatarValue);

      // Каталог/инвентарь — напрямую в memory+disk, до invalidate провайдеров.
      // Иначе экран «Смайлики» в офлайне видит пусто: provider пересобрался,
      // а диск ещё не был записан.
      final repo = ref.read(shopRepositoryProvider);
      List<ShopItem>? shop;
      List<InventoryItem>? inv;
      try {
        shop = await repo.listShop();
        if (shop.isNotEmpty) await OfflineDiskCache.saveShop(uid, shop);
      } catch (_) {}
      try {
        inv = await repo.listInventory();
        await OfflineDiskCache.saveInventory(uid, inv);
      } catch (_) {}
      try {
        final caps = await repo.capabilities();
        await OfflineDiskCache.saveCapabilities(uid, caps);
      } catch (_) {}
      try {
        final income = await repo.collectionIncome();
        await OfflineDiskCache.saveCollectionIncome(uid, income);
      } catch (_) {}

      ref.invalidate(shopCatalogProvider);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryCapabilitiesProvider);
      ref.invalidate(userGameSettingsProvider);
      ref.invalidate(achievementsListProvider);
      ref.invalidate(achievementsUnclaimedCountProvider);
      ref.invalidate(collectionIncomeProvider);
      ref.invalidate(dailyRewardStatusProvider);

      await Future.wait<void>([
        _awaitIgnore(ref.read(shopCatalogProvider.future)),
        _awaitIgnore(ref.read(inventoryListProvider.future)),
        _awaitIgnore(ref.read(inventoryCapabilitiesProvider.future)),
        _awaitIgnore(ref.read(userGameSettingsProvider.future)),
        _awaitIgnore(ref.read(achievementsListProvider.future)),
        _awaitIgnore(ref.read(achievementsUnclaimedCountProvider.future)),
        _awaitIgnore(ref.read(collectionIncomeProvider.future)),
        _awaitIgnore(ref.read(dailyRewardStatusProvider.future)),
      ]);

      shop ??= ref.read(shopCatalogProvider).valueOrNull;
      inv ??= ref.read(inventoryListProvider).valueOrNull;
      final caps = ref.read(inventoryCapabilitiesProvider).valueOrNull;
      final settings = ref.read(userGameSettingsProvider).valueOrNull;
      final achievements = ref.read(achievementsListProvider).valueOrNull;
      final income = ref.read(collectionIncomeProvider).valueOrNull;
      final daily = ref.read(dailyRewardStatusProvider).valueOrNull;

      if (shop != null && shop.isNotEmpty) {
        await OfflineDiskCache.saveShop(uid, shop);
      }
      if (inv != null) await OfflineDiskCache.saveInventory(uid, inv);
      if (caps != null) await OfflineDiskCache.saveCapabilities(uid, caps);
      if (settings != null) {
        await OfflineDiskCache.saveGameSettings(uid, settings);
      }
      if (achievements != null) {
        await OfflineDiskCache.saveAchievements(uid, achievements);
      }
      if (income != null) {
        await OfflineDiskCache.saveCollectionIncome(uid, income);
      }
      if (daily != null) await OfflineDiskCache.saveDailyReward(uid, daily);

      await _precacheEmojiAssets(shop: shop, inventory: inv);
    } finally {
      _running = false;
    }
  }

  static Future<void> _awaitIgnore(Future<dynamic> future) async {
    try {
      await future;
    } catch (_) {}
  }

  static Future<void> _precacheAvatar(String? avatarValue) async {
    final image = AvatarMemoryCache.fromAvatarValue(avatarValue);
    if (image == null) return;
    try {
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
      await done.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    } catch (_) {}
  }

  static Future<void> _precacheEmojiAssets({
    List<ShopItem>? shop,
    List<InventoryItem>? inventory,
  }) async {
    // Флаги — всегда целиком: на Web PNG ходятся по HTTP и без прогрева
    // в офлайне дают «битую» картинку. Раньше лимит 120 отрезал флаги
    // (они в конце каталога после emotions/game).
    try {
      await FlagAssetCache.preloadAll();
    } catch (_) {}

    final names = <String>{};
    void collect(String? name) {
      final n = name?.trim() ?? '';
      if (n.isNotEmpty && !isCountryFlagAnimatedName(n)) names.add(n);
    }

    for (final item in shop ?? const <ShopItem>[]) {
      collect(item.animatedName);
    }
    for (final item in inventory ?? const <InventoryItem>[]) {
      collect(item.animatedName);
    }

    final batch = names.take(160).toList();
    for (final name in batch) {
      try {
        if (hasBundledEmojiLottie(name)) {
          await AssetLottie(bundledEmojiLottieAsset(name))
              .load()
              .timeout(const Duration(seconds: 3));
        }
      } catch (_) {}
    }
  }
}

/// Держит прогрев живым: вход, старт, возврат в онлайн.
final offlineWarmupProvider = Provider<void>((ref) {
  Future<void> maybeWarm() async {
    if (ref.read(isOfflineProvider)) return;
    if (ref.read(authStateProvider).valueOrNull == null) return;
    await OfflineWarmup.run(ref);
  }

  ref.listen(authStateProvider, (prev, next) {
    final wasIn = prev?.valueOrNull != null;
    final nowIn = next.valueOrNull != null;
    if (nowIn && (!wasIn || prev?.valueOrNull?.id != next.valueOrNull?.id)) {
      unawaited(maybeWarm());
    }
  });

  ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
    final wasOffline = prev?.isOffline ?? true;
    if (wasOffline && !next.isOffline) {
      unawaited(maybeWarm());
    }
  });

  if (ref.read(authStateProvider).valueOrNull != null &&
      !ref.read(isOfflineProvider)) {
    unawaited(maybeWarm());
  }
});
