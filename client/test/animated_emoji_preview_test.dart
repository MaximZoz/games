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

  test('formatChatMessagePreview заменяет [ae:…] в смешанном тексте', () {
    final out = formatChatMessagePreview('[ae:smile] привет');
    expect(out, isNot(contains('[ae:')));
    expect(out, contains('привет'));
  });
}
