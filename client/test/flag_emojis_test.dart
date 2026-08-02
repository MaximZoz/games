import 'package:flutter/material.dart';
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

  test('preferred flag iso follows app language', () {
    expect(preferredFlagIsoForLocale(const Locale('ru')), 'ru');
    expect(preferredFlagIsoForLocale(const Locale('en')), 'gb');
    expect(preferredFlagIsoForLocale(const Locale('ar')), 'sa');
    expect(preferredFlagIsoForLocale(const Locale('nb')), 'no');
  });

  test('preferFlagIsoFirst moves matching flag to index 0', () {
    final items = <({String code, String name})>[
      (code: 'emoji_flag_ru', name: 'flagRu'),
      (code: 'emoji_flag_de', name: 'flagDe'),
      (code: 'emoji_flag_jp', name: 'flagJp'),
    ];
    preferFlagIsoFirst(
      items,
      preferredIso: 'jp',
      codeOf: (e) => e.code,
      animatedNameOf: (e) => e.name,
    );
    expect(items.first.code, 'emoji_flag_jp');
    expect(items.map((e) => e.code).toList(), [
      'emoji_flag_jp',
      'emoji_flag_ru',
      'emoji_flag_de',
    ]);
  });

  test('preferFlagIsoFirstInMixedList keeps non-flags in place', () {
    final items = <({String group, String code})>[
      (group: 'emotions', code: 'emoji_smile'),
      (group: 'flags', code: 'emoji_flag_ru'),
      (group: 'flags', code: 'emoji_flag_de'),
      (group: 'game', code: 'emoji_game_dice'),
    ];
    preferFlagIsoFirstInMixedList(
      items,
      preferredIso: 'de',
      isFlag: (e) => e.group == 'flags',
      codeOf: (e) => e.code,
      animatedNameOf: (_) => null,
    );
    expect(items.map((e) => e.code).toList(), [
      'emoji_smile',
      'emoji_flag_de',
      'emoji_flag_ru',
      'emoji_game_dice',
    ]);
  });
}
