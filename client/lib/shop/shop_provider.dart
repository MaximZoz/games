import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(authRepositoryProvider));
});

final shopCatalogProvider = FutureProvider<List<ShopItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const [];
  return ref.watch(shopRepositoryProvider).listShop();
});

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const [];
  return ref.watch(shopRepositoryProvider).listInventory();
});

final inventoryCapabilitiesProvider =
    FutureProvider<InventoryCapabilities>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return const InventoryCapabilities(allowedStakeBronze: [1, 10, 50]);
  }
  return ref.watch(shopRepositoryProvider).capabilities();
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
  return ref.watch(shopRepositoryProvider).collectionIncome();
});

/// Можно ли забрать дневной доход коллекций (для бейджей).
final collectionIncomeAvailableProvider = Provider<bool>((ref) {
  return ref.watch(collectionIncomeProvider).valueOrNull?.available == true;
});
