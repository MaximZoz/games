import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';

void main() {
  group('gift collection message', () {
    test('encode/parse roundtrip', () {
      final body = encodeGiftCollectionMessage(
        code: 'dragon',
        title: 'Дракон',
        emoji: '🐉',
        animatedName: 'dragon',
      );
      final parsed = parseGiftCollectionMessage(body);
      expect(parsed, isNotNull);
      expect(parsed!.code, 'dragon');
      expect(parsed.title, 'Дракон');
      expect(parsed.emoji, '🐉');
      expect(parsed.animatedName, 'dragon');
      expect(isGiftCollectionMessage(body), isTrue);
    });

    test('sanitizes separators', () {
      final body = encodeGiftCollectionMessage(
        code: 'c',
        title: 'A|B]',
        emoji: 'x|y]',
        animatedName: 'n|m]',
      );
      expect(body.contains('|A/B|'), isTrue);
      expect(parseGiftCollectionMessage(body), isNotNull);
    });

    test('rejects non-gift text', () {
      expect(parseGiftCollectionMessage('hello'), isNull);
      expect(parseGiftCollectionMessage('[ae:smile]'), isNull);
      expect(isGiftCollectionMessage(''), isFalse);
    });

    test('preview shows gift title', () {
      final body = encodeGiftCollectionMessage(
        code: 'c',
        title: 'Легенда',
        emoji: '⭐',
        animatedName: 'star',
      );
      expect(formatChatMessagePreview(body), contains('Легенда'));
      expect(formatChatMessagePreview(body), contains('⭐'));
    });
  });

  group('InventoryCapabilities.fromJson', () {
    test('fallback free stakes when empty', () {
      final caps = InventoryCapabilities.fromJson({});
      expect(caps.allowedStakeBronze, [2, 10, 50]);
    });

    test('parses stakes and frame', () {
      final caps = InventoryCapabilities.fromJson({
        'allowed_stake_bronze': [2, 10, 50, 100],
        'frame_color': '#CD7F32',
        'frame_code': 'frame_bronze',
      });
      expect(caps.allowedStakeBronze, [2, 10, 50, 100]);
      expect(caps.frameColor, '#CD7F32');
      expect(caps.frameCode, 'frame_bronze');
    });
  });

  group('parseBalance', () {
    test('exact decomposition', () {
      final (d, g, s, b) = parseBalance(1234567);
      expect(d.toInt(), 1);
      expect(g.toInt(), 23);
      expect(s.toInt(), 45);
      expect(b.toInt(), 67);
    });

    test('negative → zeros', () {
      final (d, g, s, b) = parseBalance(-5);
      expect(d.toInt() + g.toInt() + s.toInt() + b.toInt(), 0);
    });
  });

  group('AvatarFrameStyle.resolve', () {
    test('by code', () {
      expect(AvatarFrameStyle.resolve(code: 'frame_bronze')?.code,
          'frame_bronze');
      expect(AvatarFrameStyle.resolve(code: 'silver')?.code, 'frame_silver');
      expect(AvatarFrameStyle.resolve(code: 'gold')?.code, 'frame_gold');
      expect(AvatarFrameStyle.resolve(code: 'nope'), isNull);
    });

    test('by color hex heuristic', () {
      expect(
        AvatarFrameStyle.resolve(colorHex: '#CD7F32')?.code,
        'frame_bronze',
      );
      expect(
        AvatarFrameStyle.resolve(colorHex: '#C0C0C0')?.code,
        'frame_silver',
      );
      expect(
        AvatarFrameStyle.resolve(colorHex: '#FFD700')?.code,
        'frame_gold',
      );
    });
  });
}
