import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(authRepositoryProvider));
});

final shopCatalogProvider = FutureProvider<List<ShopItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const [];
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    return await OfflineDiskCache.loadShop(user.id) ?? const [];
  }
  try {
    final items = await ref.watch(shopRepositoryProvider).listShop();
    await OfflineDiskCache.saveShop(user.id, items);
    return items;
  } catch (_) {
    final cached = await OfflineDiskCache.loadShop(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const [];
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    return await OfflineDiskCache.loadInventory(user.id) ?? const [];
  }
  try {
    final items = await ref.watch(shopRepositoryProvider).listInventory();
    await OfflineDiskCache.saveInventory(user.id, items);
    return items;
  } catch (_) {
    final cached = await OfflineDiskCache.loadInventory(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

final inventoryCapabilitiesProvider =
    FutureProvider<InventoryCapabilities>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return const InventoryCapabilities(allowedStakeBronze: [1, 10, 50]);
  }
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    return await OfflineDiskCache.loadCapabilities(user.id) ??
        const InventoryCapabilities(allowedStakeBronze: [1, 10, 50]);
  }
  try {
    final caps = await ref.watch(shopRepositoryProvider).capabilities();
    await OfflineDiskCache.saveCapabilities(user.id, caps);
    return caps;
  } catch (_) {
    final cached = await OfflineDiskCache.loadCapabilities(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

final collectionIncomeProvider =
    FutureProvider<CollectionIncomeInfo>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return const CollectionIncomeInfo(
      available: false,
      amountBronze: 0,
      ownedCount: 0,
    );
  }
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    return await OfflineDiskCache.loadCollectionIncome(user.id) ??
        const CollectionIncomeInfo(
          available: false,
          amountBronze: 0,
          ownedCount: 0,
        );
  }
  try {
    final info = await ref.watch(shopRepositoryProvider).collectionIncome();
    await OfflineDiskCache.saveCollectionIncome(user.id, info);
    return info;
  } catch (_) {
    final cached = await OfflineDiskCache.loadCollectionIncome(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

/// Можно ли забрать дневной доход коллекций (для бейджей).
final collectionIncomeAvailableProvider = Provider<bool>((ref) {
  return ref.watch(collectionIncomeProvider).valueOrNull?.available == true;
});
