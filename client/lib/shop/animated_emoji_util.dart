import 'dart:async';

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/ui/app_theme.dart';

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

String resolvedEmojiChar(String animatedName, String? fallback) {
  final fromName = unicodeEmojiFromAnimatedName(animatedName);
  if (fromName != null) return fromName;
  final fb = fallback?.trim();
  if (fb != null && fb.isNotEmpty && parseAnimatedEmojiName(fb) == null) {
    return fb;
  }
  return '🙂';
}

/// Плейсхолдер фиксированного размера — без скачков layout при подгрузке.
class EmojiIconPlaceholder extends StatelessWidget {
  const EmojiIconPlaceholder({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final stroke = (size * 0.08).clamp(1.5, 2.5);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.42,
          height: size * 0.42,
          child: CircularProgressIndicator(
            strokeWidth: stroke,
            color: AppColors.accentStart.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Нейтральная иконка группы смайликов (не превью первого товара).
class ShopEmojiGroupIcon extends StatelessWidget {
  const ShopEmojiGroupIcon({
    super.key,
    required this.group,
    this.size = 40,
  });

  final String group;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (group) {
      case 'flags':
        // Без флага конкретной страны — общий символ «флажки».
        return _NeutralGroupBadge(
          size: size,
          child: Icon(
            Icons.flag_rounded,
            size: size * 0.58,
            color: AppColors.accentStart,
          ),
        );
      case 'game':
        return ShopAnimatedEmoji(
          animatedName: 'clinkingBeerMugs',
          size: size,
          fallback: '🍻',
        );
      case 'emotions':
        return ShopAnimatedEmoji(
          animatedName: 'smile',
          size: size,
          fallback: '😀',
        );
      default:
        return ShopAnimatedEmoji(
          animatedName: 'sparkles',
          size: size,
          fallback: '✨',
        );
    }
  }
}

class _NeutralGroupBadge extends StatelessWidget {
  const _NeutralGroupBadge({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: AppColors.accentStart.withValues(alpha: 0.22),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Виджет смайлика из бандла приложения (без сети).
///
/// Lottie подгружается с плейсхолдером-лоадером и лёгким fade-in.
/// В списках/сетках держите [animate]=false — иначе десятки Lottie
/// одновременно едят память и могут «ронять» вкладку.
class ShopAnimatedEmoji extends StatefulWidget {
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
  State<ShopAnimatedEmoji> createState() => _ShopAnimatedEmojiState();
}

class _ShopAnimatedEmojiState extends State<ShopAnimatedEmoji> {
  bool _ready = false;
  bool _failed = false;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _scheduleStaticReveal();
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShopAnimatedEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedName != widget.animatedName ||
        oldWidget.animate != widget.animate ||
        oldWidget.size != widget.size) {
      _loadTimeout?.cancel();
      _ready = false;
      _failed = false;
      _scheduleStaticReveal();
    }
  }

  /// Статичные unicode/флаги: отложить кадр, чтобы сетка не блокировала UI,
  /// и показать короткий лоадер → fade-in (best practice для тяжёлых emoji-шрифтов).
  void _scheduleStaticReveal() {
    final data =
        widget.animate ? animatedEmojiDataFromName(widget.animatedName) : null;
    final useLottie = widget.animate && data != null;
    if (useLottie) {
      _loadTimeout?.cancel();
      _loadTimeout = Timer(const Duration(milliseconds: 2500), () {
        if (!mounted || _ready) return;
        _markFailed();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ready) return;
      setState(() => _ready = true);
    });
  }

  void _markReady() {
    if (!mounted || _ready) return;
    _loadTimeout?.cancel();
    setState(() => _ready = true);
  }

  void _markFailed() {
    if (!mounted) return;
    _loadTimeout?.cancel();
    setState(() {
      _failed = true;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fb = resolvedEmojiChar(widget.animatedName, widget.fallback);
    final staticChild = Text(
      fb,
      style: TextStyle(fontSize: widget.size * 0.85),
    );

    if (!widget.animate || _failed) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: AppDurations.short,
          child: _ready ? Center(child: staticChild) : EmojiIconPlaceholder(size: widget.size),
        ),
      );
    }

    final data = animatedEmojiDataFromName(widget.animatedName);
    if (data == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: AppDurations.short,
          child: _ready ? Center(child: staticChild) : EmojiIconPlaceholder(size: widget.size),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!_ready) EmojiIconPlaceholder(size: widget.size),
          AnimatedOpacity(
            opacity: _ready ? 1 : 0,
            duration: AppDurations.short,
            child: AnimatedEmoji(
              data,
              size: widget.size,
              repeat: true,
              animate: true,
              source: AnimatedEmojiSource.asset,
              onLoaded: (_) => _markReady(),
              errorWidget: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markFailed();
                  });
                  return staticChild;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
