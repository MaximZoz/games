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
    final fb = fallback ?? '🙂';
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
