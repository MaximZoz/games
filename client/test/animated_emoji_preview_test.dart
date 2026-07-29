import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';

void main() {
  test('formatChatMessagePreview заменяет [ae:…] на юникод', () {
    expect(formatChatMessagePreview('[ae:smile]'), isNot(contains('[ae:')));
    expect(formatChatMessagePreview('[ae:smile]').length, lessThan(8));
    expect(formatChatMessagePreview('привет'), 'привет');
    expect(formatChatMessagePreview(''), '');
  });

  test('parseAnimatedEmojiName', () {
    expect(parseAnimatedEmojiName('[ae:kissingHeart]'), 'kissingHeart');
    expect(parseAnimatedEmojiName(' text '), isNull);
  });

  test('bundledEmojiStaticPreviewProgress', () {
    expect(bundledEmojiStaticPreviewProgress('baseball'), 0.99);
    expect(bundledEmojiStaticPreviewProgress('tennis'), 0.42);
    expect(bundledEmojiStaticPreviewProgress('dragon'), 0.42);
  });

  test('usesUnicodeStaticEmojiPreview for baseball shop card', () {
    expect(usesUnicodeStaticEmojiPreview('baseball'), isTrue);
    expect(usesUnicodeStaticEmojiPreview('tennis'), isFalse);
  });
}
