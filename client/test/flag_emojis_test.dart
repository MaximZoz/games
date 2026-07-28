import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/flag_emojis.dart';

void main() {
  test('country flags resolve to unicode', () {
    expect(countryFlagUnicodeByName.length, 45);
    expect(countryFlagUnicodeFromName('flagRu'), '🇷🇺');
    expect(unicodeEmojiFromAnimatedName('flagJp'), '🇯🇵');
    expect(isCountryFlagAnimatedName('flagUs'), isTrue);
    expect(isCountryFlagAnimatedName('smile'), isFalse);
  });
}
