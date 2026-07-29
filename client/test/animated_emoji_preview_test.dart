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

  test('bundledEmojiStaticPreviewProgress picks visible Lottie frame', () {
    // dragon-style default mid-frame
    expect(bundledEmojiStaticPreviewProgress('dragon'), 0.42);
    expect(bundledEmojiStaticPreviewProgress('tennis'), 0.42);
    // baseball mid-frame is shrunk — use early visible frame
    expect(bundledEmojiStaticPreviewProgress('baseball'), 0.02);
  });
}
