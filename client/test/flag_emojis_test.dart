import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/flag_emojis.dart';

void main() {
  test('country flags resolve to unicode, iso and asset path', () {
    expect(countryFlagsByName.length, 45);
    expect(countryFlagUnicodeFromName('flagRu'), '🇷🇺');
    expect(countryFlagIsoFromName('flagJp'), 'jp');
    expect(unicodeEmojiFromAnimatedName('flagJp'), '🇯🇵');
    expect(isCountryFlagAnimatedName('flagUs'), isTrue);
    expect(isCountryFlagAnimatedName('smile'), isFalse);
    expect(countryFlagAssetPath('ru'), 'assets/flags/ru.png');
  });
}
