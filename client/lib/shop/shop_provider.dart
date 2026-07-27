import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(authRepositoryProvider));
});

final shopCatalogProvider =
    FutureProvider<List<ShopItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).listShop();
});

final inventoryListProvider =
    FutureProvider<List<InventoryItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).listInventory();
});

final inventoryCapabilitiesProvider =
    FutureProvider<InventoryCapabilities>((ref) async {
  return ref.watch(shopRepositoryProvider).capabilities();
});

final collectionIncomeProvider =
    FutureProvider<CollectionIncomeInfo>((ref) async {
  return ref.watch(shopRepositoryProvider).collectionIncome();
});
