import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('shop cache round-trip', () async {
    const items = [
      ShopItem(
        code: 'emoji_joy',
        kind: 'emoji',
        title: 'Joy',
        description: '',
        priceBronze: 10,
        owned: false,
        payload: {'animated_name': 'joy'},
      ),
    ];
    await OfflineDiskCache.saveShop('u1', items);
    final loaded = await OfflineDiskCache.loadShop('u1');
    expect(loaded, isNotNull);
    expect(loaded!.single.code, 'emoji_joy');
    expect(loaded.single.animatedName, 'joy');
  });

  test('capabilities cache round-trip', () async {
    const caps = InventoryCapabilities(
      allowedStakeBronze: [1, 10, 50, 100],
      frameColor: '#112233',
      frameCode: 'frame_gold',
    );
    await OfflineDiskCache.saveCapabilities('u1', caps);
    final loaded = await OfflineDiskCache.loadCapabilities('u1');
    expect(loaded?.frameCode, 'frame_gold');
    expect(loaded?.allowedStakeBronze, [1, 10, 50, 100]);
  });

  test('пустой saveShop не затирает memory-кэш', () async {
    const items = [
      ShopItem(
        code: 'emoji_joy',
        kind: 'emoji',
        title: 'Joy',
        description: '',
        priceBronze: 10,
        owned: false,
        payload: {'animated_name': 'joy', 'group': 'emotions'},
      ),
    ];
    await OfflineDiskCache.saveShop('u2', items);
    await OfflineDiskCache.saveShop('u2', const []);
    final loaded = await OfflineDiskCache.loadShop('u2');
    expect(loaded, isNotNull);
    expect(loaded!.single.code, 'emoji_joy');
  });
}
