import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:multigames_client/shop/flag_emojis.dart';

/// Токен сообщения с анимированным смайликом: `[ae:rocket]`.
final RegExp animatedEmojiTokenRe = RegExp(r'^\[ae:([A-Za-z0-9_]+)\]$');

String encodeAnimatedEmojiMessage(String animatedName) => '[ae:$animatedName]';

String? parseAnimatedEmojiName(String body) {
  final m = animatedEmojiTokenRe.firstMatch(body.trim());
  return m?.group(1);
}

bool isAnimatedEmojiMessage(String body) =>
    parseAnimatedEmojiName(body) != null;

AnimatedEmojiData? animatedEmojiDataFromName(String name) {
  try {
    return AnimatedEmojis.fromName(name);
  } catch (_) {
    return null;
  }
}

/// Юникод-символ по имени анимации (для превью без Lottie).
String? unicodeEmojiFromAnimatedName(String name) {
  final flag = countryFlagUnicodeFromName(name);
  if (flag != null) return flag;
  try {
    return AnimatedEmojis.fromName(name).toUnicodeEmoji();
  } catch (_) {
    return null;
  }
}

/// Токен подарка коллекции: `[gift_coll:code|Title|emoji|animatedName]`.
final RegExp giftCollectionTokenRe = RegExp(
  r'^\[gift_coll:([^|\]]+)\|([^|\]]*)\|([^|\]]*)\|([^\]]*)\]$',
);

({String code, String title, String emoji, String animatedName})?
    parseGiftCollectionMessage(String body) {
  final m = giftCollectionTokenRe.firstMatch(body.trim());
  if (m == null) return null;
  return (
    code: m.group(1)!.trim(),
    title: m.group(2)!.trim(),
    emoji: m.group(3)!.trim(),
    animatedName: m.group(4)!.trim(),
  );
}

bool isGiftCollectionMessage(String body) =>
    parseGiftCollectionMessage(body) != null;

String encodeGiftCollectionMessage({
  required String code,
  required String title,
  required String emoji,
  required String animatedName,
}) {
  final safeTitle = title.replaceAll('|', '/').replaceAll(']', '');
  final safeEmoji = emoji.replaceAll('|', '').replaceAll(']', '');
  final safeName = animatedName.replaceAll('|', '').replaceAll(']', '');
  return '[gift_coll:$code|$safeTitle|$safeEmoji|$safeName]';
}

/// Превью текста сообщения: `[ae:smile]` → 😀, подарок → 🎁 Название.
String formatChatMessagePreview(String body) {
  final gift = parseGiftCollectionMessage(body);
  if (gift != null) {
    final title = gift.title.isNotEmpty ? gift.title : 'коллекция';
    final emoji = gift.emoji.isNotEmpty
        ? gift.emoji
        : (unicodeEmojiFromAnimatedName(gift.animatedName) ?? '🎁');
    return '🎁 $emoji $title';
  }
  final name = parseAnimatedEmojiName(body);
  if (name == null) return body;
  return unicodeEmojiFromAnimatedName(name) ?? '🙂';
}

String _resolvedEmojiChar(String animatedName, String? fallback) {
  final fromName = unicodeEmojiFromAnimatedName(animatedName);
  if (fromName != null) return fromName;
  final fb = fallback?.trim();
  if (fb != null && fb.isNotEmpty && parseAnimatedEmojiName(fb) == null) {
    return fb;
  }
  return '🙂';
}

/// Виджет анимированного смайлика из бандла приложения (без сети).
///
/// В списках/сетках держите [animate]=false — иначе десятки Lottie
/// одновременно едят память и могут «ронять» вкладку.
class ShopAnimatedEmoji extends StatelessWidget {
  const ShopAnimatedEmoji({
    super.key,
    required this.animatedName,
    this.size = 32,
    this.fallback,
    this.animate = false,
  });

  final String animatedName;
  final double size;
  final String? fallback;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final fb = _resolvedEmojiChar(animatedName, fallback);
    if (!animate) {
      return Text(
        fb,
        style: TextStyle(fontSize: size * 0.85),
      );
    }
    final data = animatedEmojiDataFromName(animatedName);
    if (data == null) {
      return Text(
        fb,
        style: TextStyle(fontSize: size * 0.85),
      );
    }
    return AnimatedEmoji(
      data,
      size: size,
      repeat: true,
      animate: true,
      source: AnimatedEmojiSource.asset,
      errorWidget: Text(
        fb,
        style: TextStyle(fontSize: size * 0.85),
      ),
    );
  }
}
