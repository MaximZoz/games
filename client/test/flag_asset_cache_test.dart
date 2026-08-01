import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/flag_asset_cache.dart';
import 'package:multigames_client/shop/flag_emojis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preloadAll грузит PNG флагов в memory-кэш', () async {
    await FlagAssetCache.preloadAll();
    // Хотя бы несколько основных флагов с витрины.
    expect(FlagAssetCache.hasIso('ru'), isTrue);
    expect(FlagAssetCache.hasIso('us'), isTrue);
    expect(FlagAssetCache.hasIso('gb'), isTrue);
    expect(FlagAssetCache.imageForIso('ru'), isNotNull);
    expect(countryFlagsByName.containsKey('flagRu'), isTrue);
  });
}
