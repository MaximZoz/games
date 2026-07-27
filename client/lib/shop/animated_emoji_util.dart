import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

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
  try {
    return AnimatedEmojis.fromName(name).toUnicodeEmoji();
  } catch (_) {
    return null;
  }
}

/// Превью текста сообщения: `[ae:smile]` → 😀, иначе исходная строка.
String formatChatMessagePreview(String body) {
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
